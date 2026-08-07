# promise_authentication

## Dev environment

- `docker compose up -d` runs the Rails app on http://localhost:3003. It requires the
  `promise_kms` service from the sibling repo `../promise_key_registry` (start its
  `docker compose up -d` too) — both join the external `promise-network`. If kms is
  down, requests 500 with `SocketError (getaddrinfo: Name or service not known)`.
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
