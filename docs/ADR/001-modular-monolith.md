# ADR 001 — Modular monolith for the API

- Status: Accepted for the planning baseline
- Date: 2026-10-29
- Related: `docs/architecture-plan.md` §1–§3, `docs/PRD.md` §7

## Context

Little Genius needs published-content delivery, optional parent sync, deletion/export, and a staff publishing workflow. The requirements allow a modular monolith or a small set of services, and they warn against premature microservices. The client stack is fixed separately (Flutter). There is no production traffic, no measured bottleneck, and no application repository yet.

Staff authoring must not ship inside the child app. That is a UI and authentication boundary, not automatically a second backend.

## Decision

Build one Fastify/TypeScript service on Node.js 24 LTS with modules: health, content, profiles, progress, privacy, admin, and jobs.

- Public and parent routes live under `/api/v1`. Staff routes live under `/admin/v1` with a separate auth plugin and database role.
- PostgreSQL 17 is the only required datastore. Prisma 6.x is the ORM. `jsonb` is limited to the immutable lesson payload (and operational job arguments, which are not lesson documents).
- Async export, deletion, and media processing use a `job_outbox` table in the same database, drained by a worker entrypoint of the same image.
- Redis is not part of v1. Add it only after a measured multi-instance rate-limit, queue, or cache need.
- A separate admin **frontend** (`services/content_admin`) is justified when authoring starts (Phase 4). A separate admin **API service** is not.

The first lesson may be loaded as a reviewed fixture so the vertical slice does not wait on the CMS. The fixture path is retired before a second lesson is published.

## Consequences

- One migration history, one request-id path, one audit writer, and local Docker Compose of Postgres plus API.
- Module boundaries have to be enforced in code review: content handlers do not query child profiles; parent tokens do not call `/admin/v1`.
- In-process rate limits are wrong once more than one API instance runs. That scale step is explicit, not accidental.
- Prisma 8 is not adopted while it is a release candidate. Moving to it later is a planned upgrade, not a schema rewrite.
- Operational complexity of microservices (distributed transactions, per-service deploys) stays off the critical path until a real boundary appears. The likely first boundary is network isolation for admin, and only if a private ingress plus route auth is judged insufficient.
