# content_schema

JSON Schema 2020-12 for the lesson document the app is allowed to render.

This package is the source of truth for that document. The API keeps a Zod mirror and checks the reviewed fixture against both. The Flutter app parses the same fixture into a closed Freezed model. Unknown interaction types and unknown schema versions are not representable as a playable lesson.

Phase 2 allows `tap_to_learn` only. Review state, rights, and publish status are not fields in this document.
