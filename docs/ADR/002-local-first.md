# ADR 002 — Local-first learning, optional sync

- Status: Accepted for the planning baseline
- Date: 2026-10-29
- Related: `docs/architecture-plan.md` §4, §6.3, §7.3; `docs/PRD.md` §1, §9

## Context

Parents must be able to use Little Genius without an account, and local mode must not be a reduced learning product. Downloaded lessons must run offline. If a parent later opts into an account, progress must sync without duplicates, and deletion must beat queued uploads. Child privacy is release-blocking: the safest data is data that never leaves the device.

The requirements also make account sync, export, and deletion mandatory for the product, after consent. Web is a build target of the Flutter app even though the original MVP did not require a public web client.

## Decision

- The device is the source of truth for local mode. Profile, progress, lesson documents, and asset bytes are written locally before any network call.
- iOS and Android use Drift (SQLite) behind a repository interface. Web uses IndexedDB through that same interface. The web build does not include SQLite or `sqlite3.wasm`.
- Local mode does not call profile, progress, consent, or analytics endpoints. Content download is the only network the learning loop needs, and only while a pack is being fetched.
- Events are immutable and client-identified (UUID v4). The local outbox matches the future `POST /profiles/{id}/events:batch` contract. The server dedupes on `event_id` and on `Idempotency-Key`.
- No server row exists for a local-only profile. `parent_account_id` on the server is not nullable.
- Account mode is off until a parent completes a consent step. Sync uploads nickname, avatar id, age band, locale, bilingual flag, and minimized `started`/`completed` events. That field list is an assumption Product and Privacy still have to confirm.
- Web stays local-mode through the first mobile launch. Browser storage can be evicted, and the parent UI must say so. Web account sessions need a separate cookie design.

## Consequences

- The vertical slice can ship learning without an identity provider. Sync handlers are specified now and implemented in Phase 5.
- Offline completion cannot be lost by a failed upload, because the upload has not happened yet. Account-mode loss modes are retried batches and deletion races; both have explicit rules.
- Two persistence drivers must stay behavior-compatible. Contract tests run against both.
- Web offline is best-effort. Marketing and parent copy cannot promise phone-equivalent durability.
- A privacy review can still forbid uploading nicknames. The client can then sync progress under an opaque id. Consent UX is blocked until that choice is made.
- This ADR does not claim compliance with the DPDP Act or store kids policies. It only keeps the default on the device.
