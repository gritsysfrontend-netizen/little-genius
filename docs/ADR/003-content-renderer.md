# ADR 003 — Allowlisted content renderer

- Status: Accepted for the planning baseline
- Date: 2026-10-29
- Related: `docs/architecture-plan.md` §7.5, §9; `docs/PRD.md` §8

## Context

Lessons are updated from a backend without an app release. That only stays safe if a lesson is data. The requirements forbid remote content from executing code, scripts, native commands, or unreviewed HTML, and they require unknown types to fail safe. A sample lesson JSON in the requirements mixes render fields with review and publish status.

The first activity is tap-to-learn. Later activities (choice, matching, sorting, counting, sequencing, tracing) must plug into the same path. Tracing has a performance risk and is not part of the first slice.

## Decision

- The shared contract is JSON Schema (draft 2020-12) in `packages/content_schema`. The API validates with Zod generated or checked against that schema. The app parses with Freezed into a closed set of types.
- Every object in the client document rejects unknown properties. There is no `script`, `html`, `component`, `widget`, `url`, or `code` field. Asset references are ids and SHA-256 checksums. Signed CDN URLs are returned only by the asset endpoint and are not stored inside the lesson document.
- The renderer is a compile-time map from `interaction.type` to a widget. The default arm is a safe fallback (gentle copy and a home control). Unknown schema versions use that same fallback. The app does not use a WebView, an HTML renderer, or dynamic code loading for lessons.
- v1 of the schema allows `tap_to_learn` only. Each later interaction is added to the schema and the map in the same change, then released in an app build that understands it. Older apps fall back rather than partially rendering a new type.
- Review, rights, and publish status are relational columns, not fields the client obeys. Published payloads are immutable; unpublish changes status only.
- Audio is play, pause, and replay via `just_audio`. No looping. Backgrounding pauses playback.
- The client verifies payload and asset checksums before render. A mismatch shows a recoverable error and offers a re-download.

## Consequences

- A hostile or merely newer document cannot introduce a widget the app does not already contain. AC-05 is testable with fixtures.
- New interaction types need an app release. Copy, translations, and new lessons of a known type do not.
- Authors cannot ship a one-off layout by embedding HTML. The allowlist is the design system for activities.
- Schema evolution is strict: forward-compatible “ignore unknown keys” is rejected because an unknown key is how an unsafe field would sneak in.
- Tracing can slip to a later release without blocking the first lesson.
- Staff workflow state and the bytes sent to a child are different objects, so an approval change cannot mutate a version a child has already downloaded.
