# promise_authentication

## Deploying

- Production is Heroku (`promise-auth-production`, EU region). There is **no
  auto-deploy from GitHub** — merging to main does not ship. Deploy manually with
  `git push p main` (`p` = `https://git.heroku.com/promise-auth-production.git`);
  the release phase runs `rails db:migrate`. Verify with
  `heroku releases -a promise-auth-production`, roll back with `heroku rollback`.
- Recurring jobs run via the Heroku Scheduler add-on (no CLI/API for its job list —
  manage via `heroku addons:open scheduler -a promise-auth-production`). Expected
  entries: `rake trust:roll_certificates` and daily `rake statistics:sweep`
  (6-month visit-statistics retention promised by /privacy).

## Bounce detection for the verification mail

The verify_email page tells the user when "Bekræft din e-mail" bounced (see
`app/models/bounces.rb`). Two sources, each a no-op until its config vars are set:

- **Scaleway activity** (rejections our SMTP provider saw itself: unknown mailbox,
  full, blocklisted): `SCALEWAY_TEM_SECRET_KEY` + `SCALEWAY_TEM_PROJECT_ID`
  (optional `SCALEWAY_TEM_REGION`, default `fr-par`). The page's status poll looks
  the mail up by recipient, throttled to every 10 s per code.
- **Bounce mailbox** (asynchronous non-delivery reports, e.g. a forwarding mailbox
  that accepted the mail and then failed to pass it on — Scaleway never sees those):
  `PROMISE_BOUNCE_ADDRESS` (e.g. `bounces@promiseauthentication.org`) becomes the
  envelope sender / Return-Path of the verification mail, and
  `PROMISE_BOUNCE_IMAP_HOST`/`_USERNAME`/`_PASSWORD` (`_PORT`, default 993) is the
  IMAP mailbox that address lands in. The status poll reads it at most every 30 s
  across all users; `rake bounces:poll` does the same from the shell / Heroku
  Scheduler. **The mailbox must be dedicated to bounces:** every delivery report is
  deleted after reading (it holds an address we promised not to keep), other mail is
  marked seen and left alone.
- Reports are matched by the `X-Promise-Verification` token header the mail went out
  with; reports without it fall back to the hashed recipient. Only a reason category
  (`mailbox_not_found`, `mailbox_full`, `rejected`, `other`) is stored on the code.
- Verified 2026-10-22 (one-off `heroku run` sending to a real inbox): Scaleway SMTP
  accepts `MAIL FROM bounces@` with `From: hello@`; the received mail shows
  `Return-Path: <bounces@…>`, `spf=pass` for bounces@, `dmarc=pass` and the
  `X-Promise-Verification` header. Note Scaleway adds `X-Scw-Tem-Message-Id` to the
  outgoing mail — that is the id of the email in its activity API, but it is only
  visible to the recipient, not returned to the SMTP sender.
- To preview the page states locally, create a code and mark it:
  `EmailVerificationCode.create!(id: Authentication::HashedEmail.from_cleartext(email), code: 'ab7k').mark_bounced!('rejected')`,
  then open `/registrations/verify_email?email=<email>`.

## Dev environment

- `docker compose up -d` runs the Rails app on http://localhost:3003. It requires the
  `promise_kms` service from the sibling repo `../promise_key_registry` (start its
  `docker compose up -d` too) — both join the external `promise-network`. If kms is
  down, requests 500 with `SocketError (getaddrinfo: Name or service not known)`.
  Both services use `restart: unless-stopped`, so they come back after a
  reboot/Docker restart — if kms is still down, someone `docker compose stop`ped it;
  restart it with `docker compose up -d` in `../promise_key_registry`.
- The dev database is SQLite at `db/development.sqlite3`, a plain file in the repo dir
  mounted into the container. **It is shared across branch checkouts** — switching
  branches does not switch databases, so a branch with different migrations (or renamed
  tables) leaves the db mismatched for other branches. Symptom:
  `Could not find table '...'` on boot/requests.
  - Fix: move/delete `db/development.sqlite3` (and its `-shm`/`-wal` files), then
    restart the container. `db:prepare` runs on container start and rebuilds from
    `db/schema.rb`. Dev data is lost, which is fine.
  - **After a rebuild, sign-in 500s** with `NoMethodError (undefined method 'public_key'
    for nil)` in `id_token.rb` — the rebuilt db has no row in `trust_certificates`
    (nothing seeds it; certs only last 2 days anyway). Fix:
    `docker compose exec web bin/rails runner "Trust::Certificate.rotate!"`
- To test the e-mail confirmation flow locally: mails don't send from dev, but the
  mailer logs the magic link — `grep magic-link log/development.log | tail -1` — and
  `PROMISE_DEV_HOST` (set in docker-compose.yml) makes the URL point at :3003.
- `rails db:prepare` only runs at container **start** (it's in the compose `command:`) —
  after db changes you must `docker compose restart web`, not just wait.
- The registration flow's verify_human step shows a Cloudflare Turnstile check (test
  mode) — automation can't complete registrations end-to-end; hand that step to a
  human, or preview flash-gated states via dev params (e.g. the confirm page's
  account-created celebration replays with `/confirm?client_id=...&celebrate=1`).

## Verifying the CSS page animations

Several pages (verify_email, create_password, confirm) play multi-second pure-CSS
"two-screen" shows. When checking them via browser automation:

- Screenshot round-trips are slower than the shows, so you always catch the end
  state. Scrub instead: `document.getAnimations().forEach(a => {a.pause();
  a.currentTime = <ms>})`, screenshot, then `.forEach(a => a.play())`.
- Backgrounded automation tabs defer rendering — animation clocks are set at load,
  so a hidden tab shows stale computed styles and then jumps straight to the final
  frame when woken. Probe computed styles/scrollLeft via JS rather than trusting
  what "plays".
- The two-screen containers must use `overflow: clip`, never `hidden`: a hidden box
  is still programmatically scrollable, and autofocusing the still-offscreen screen
  makes the browser scroll the whole show out of view (symptom: blank card for the
  animation's duration, then the content pops in).
