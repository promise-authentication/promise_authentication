# Plan: Sign up & log in with a telephone number (or email)

Branch: `feature/telephone-number` — shipped as **one PR**, organized into chunks.

## Goal
Let a user register and log in with **either** an email address **or** a telephone
number + password. Includes: confirming the phone is yours at signup (SMS code) and
password reset via SMS code.

## Confirmed decisions
- **SMS provider:** MessageBird/Bird.
- **Architecture:** Generalize to an `Identifier` concept (email | phone).
- **Identity count:** Strictly one identifier per account (email *or* phone).
- **Recovery:** Phone reset uses **codes, never links**. Email keeps its existing link flow.

## Key architectural insight
The identifier is **not** part of the cryptography. The vault key is derived from
`password + a random per-user salt`. The email is only a deterministically-hashed
*username* (`SHA256+BLAKE2b → Base64`) mapping to a `user_id`. Relying parties never
see the identifier (the ID token carries only `sub/aud/iss/iat/nonce`). So a phone
number is just a second kind of hashed identifier — **no crypto changes**, and nothing
downstream of auth changes.

## Event-sourcing back-compat rule
History is immutable. Keep existing `EmailClaimed`/`EmailUnclaimed` events and the
`Authentication::Email` aggregate/streams untouched. Add a parallel `Phone` aggregate +
`PhoneClaimed`/`PhoneUnclaimed` events. Generalize everything *above* the event layer
(value object, hashing, verification, projection, recovery, session, UI). The event
listener projects both event types into one unified read model.

---

## Work breakdown (check off as we go)

### Chunk 1 — Identifier foundation (pure refactor, no behavior change) ✅
- [x] Add `phonelib` and `messagebird-rest` to `Gemfile`; `bundle`
- [x] Config: default phone region via `Phonelib.default_country` (`DEFAULT_PHONE_REGION`, default DK). _(`MESSAGEBIRD_*` env + no-op test SMS handled in Chunk 2 with `SmsSender`.)_
- [x] `Authentication::Identifier` value object: `.email/.phone/.parse`, normalization (email: strip/downcase + EmailInquire; phone: Phonelib E.164), `#digest` (shared SHA256+BLAKE2b hash, historical-compatible), `#type`, `#valid?`, `#display_value`
- [x] Unified `HashedIdentifier` model (`user_id_for(identifier)`, `find_by_identifier`); `HashedEmail` kept as a delegating shim so legacy/admin/stats call sites are untouched
- [x] Migration: `authentication_hashed_identifiers` (id=hash PK, user_id, `identifier_type`, verified_at) — named `identifier_type` to avoid Rails STI on `type`
- [x] Data migration: backfill existing `authentication_hashed_emails` rows as `identifier_type: 'email'`, then drop old table (reversible `down`)
- [x] Tests: `identifier_test` (incl. phone E.164 + collision), `hashed_identifier_test`. Full suite green: 98 runs, 0 failures.

### Chunk 2 — SMS infra + generalized verification ✅
- [x] `Authentication::Services::SmsSender` wrapping MessageBird, SMTP-style retry/backoff; `:test` delivery collector (default outside production, like ActionMailer); `MESSAGEBIRD_API_KEY`/`MESSAGEBIRD_ORIGINATOR` env
- [x] Generalize `email_verification_codes` → `verification_codes` (`VerificationCode` model + `find_for(identifier)`); `EmailVerificationCode` kept as shim subclass
- [x] Generalize `PrepareEmailForValidation` → `PrepareIdentifierForValidation`: routes delivery (mailer for email, SmsSender for phone); `PrepareEmailForValidation` kept as shim subclass
- [x] `Phone` aggregate + `PhoneClaimed`/`PhoneUnclaimed` events + `ClaimPhone`/`UnclaimPhone` commands
- [x] `EventListener`: handle `PhoneClaimed`; project both email + phone into `authentication_hashed_identifiers`
- [x] i18n `sms.verification_code` (en + da)
- [x] Tests: SmsSender, verification routing (email→mail, phone→SMS), `VerificationCode.find_for`, ClaimPhone projection. Full suite green: 113 runs, 0 failures.

### Chunk 3 — Signup & login with phone ✅
- [x] `Authenticate` (email/phone, presence-only login validation) + `Register` (claims phone or email) + `Existing` (accepts Identifier or legacy string)
- [x] `RegistrationsController`: identifier-aware create/verify_human/verify_email/create_password; phone→Phonelib, email→EmailInquire ("did you mean" kept for email); email path still uses `PrepareEmailForValidation` (preserves the SMTP-error stub)
- [x] Session (`AuthenticatedConcern`): store `:identifier`/`:identifier_type` (+`:email` for back-compat); `current_user.identifier`/`.identifier_type`; `logged_in?` keys off identifier; logout clears new keys
- [x] `registration_configuration`: permit `:phone`; `signup_identifier` helper builds the Identifier from params
- [x] `AuthenticationController#authenticate`: accepts `:phone`, surfaces email/phone validation errors
- [x] Views: Email | Phone toggle on `registrations/new` (JS enables only the active field); phone-aware copy in verify_human/verify_email/create_password/verify_password; confirm + footer show `current_user.identifier`
- [x] i18n: tabs, phone labels/help, SMS sent/resent copy, phone attribute name (en + da)
- [x] Tests: phone signup → SMS code → password → sign-in; phone login; invalid-phone re-render. Full suite green: 116 runs, 0 failures.

### Chunk 4 — Password recovery via SMS code
- [ ] Generalize `SendRecoveryMail` → `SendRecovery`: email=link (unchanged), phone=code; mint `RecoveryToken` server-side + issue `VerificationCode`; SMS the code; stash identifier hash in session; don't leak unknown numbers
- [ ] New "enter recovery code" page (generalized from verify-code view); skip `passwords/wait` for phone
- [ ] `RecoveriesController#ensure_recoverable`: resolve token from session (phone) or `params[:token_id]` (email link); `RecoverySetPassword` unchanged
- [ ] Routes: phone recovery-code entry/verify actions on `password` resource
- [ ] `passwords/new`: Email | Phone toggle
- [ ] Tests: phone recovery end-to-end

### Chunk 5 — Change identifier on dashboard
- [ ] Generalize `ChangeEmail` → `ChangeIdentifier`; `EmailsController` identifier-aware
- [ ] Views: dashboard identifier change supports phone
- [ ] Tests

---

## Open implementation choices (defaults chosen)
- Default phone region for bare local numbers: **DK** (configurable).
- Existing-email migration: **data-copy migration** (event replay is the fallback).
- MessageBird originator: env-configured (alphanumeric sender ID or number).
