# Little Genius — Product Requirements

Status: distilled from `internal/little-genius-production-requirements-v1.docx` (v1.0) for the engineering plan in `docs/architecture-plan.md`.
This is a product baseline for review. It is not legal advice, a privacy impact assessment, or a store-compliance claim. The product name is provisional.

## 1. Product

Little Genius is a play-based early-learning app for children aged 1–5 and their parents or caregivers. Children learn through pictures, native-language audio, stories, songs, matching, counting, letters and scripts, phonics, optional tracing, and everyday activities. Parents manage profiles, language, downloads, session limits, privacy, and a calm progress summary.

Two spaces:

- **Child space:** few choices, large targets, audio, gentle feedback, no reading required for the youngest band, no external links, no purchases, no accounts.
- **Parent space:** behind an adult gate. Profile, language, downloads, session limit, privacy, and progress.

The same concept ships in English, Hindi, and Tamil, with human-reviewed copy and native pronunciation. Ordinary content updates come from a managed backend and do not need an app release. The app works locally without an account. Downloaded lessons work offline. An account and sync are optional and must not be required for a complete learning experience.

Clients: iOS and Android phones and tablets, plus a Web build of the same Flutter app. The first store launch can be mobile-only. Web offline storage is less durable than on a phone; parent-facing copy has to say that.

## 2. Users

| User | Can | Cannot |
| --- | --- | --- |
| Child (1–5) | Open activities chosen for their age band, listen, tap, match, count, trace when that activity exists, replay audio, see gentle feedback. | Purchases, external links, settings, account actions, export, delete. |
| Parent, local mode | Create one or more local profiles, set age band and language, set a session limit, see local progress, manage downloads, clear local history. | Data does not leave the device unless they later choose an account. |
| Parent, account mode | Everything in local mode, plus sign-in, sync, restore on another device, export, and account deletion, after consent. | Skip consent or the adult gate. |
| Content author | Draft lessons, upload assets, edit translations, submit for review. | Publish. |
| Reviewer | Approve age fit, pedagogy, translation, audio, accessibility, and rights. | Publish without the publisher role. Authors do not approve their own lesson. |
| Publisher / administrator | Publish an immutable version, roll back the manifest, manage roles, read audit logs. | Act without MFA and least privilege. |

Children are not accounts. There is no child password, public profile, or social graph.

## 3. Languages

| Code | Language | Scope |
| --- | --- | --- |
| `en` | English | UI chrome and lesson copy/audio. |
| `hi` | Hindi | UI chrome and lesson copy/audio. Devanagari must render with the bundled Noto font. |
| `ta` | Tamil | UI chrome and lesson copy/audio. Tamil script must render with the bundled Noto font. |

- The parent sets a default locale and may turn on bilingual mode.
- UI strings live in ARB catalogs. Lesson title, instruction, feedback, labels, and audio live in the content document.
- A lesson is playable in a locale only when that localization is approved. The app does not silently fall back to English. An approved fallback must be an explicit field set by a reviewer.
- Machine translation alone is not sufficient to publish Hindi or Tamil.
- Bilingual mode shows the second language’s title and offers a second audio replay when both locales exist. It never mixes two languages inside one activity unless that mode is on.

## 4. Age bands

The parent picks one band per child. The app does not ask for a birth date, birth month, or birth year.

| Band | Focus | Example | Design limits |
| --- | --- | --- | --- |
| `1-2` | Sensory play, familiar objects, cause and effect, sounds, simple words, caregiver alongside. | Tap an animal and hear it. Choose one of two large pictures. | Very few choices. No reading. Short sessions. |
| `2-3` | Naming, colors, shapes, body, family, everyday objects, listening. | “Find the apple.” Choose a red object. | One-step instructions. No timers. Forgiving taps. |
| `3-4` | Letters and numbers awareness, small counts, matching, sorting, stories, patterns. | Match a numeral to a group. Sort by color. Order three pictures. | Show how. No punitive wrong-answer feedback. |
| `4-5` | Early phonics, script recognition, tracing readiness, number concepts, sequencing, school readiness. | Hear a letter, trace it if they want, count, finish a simple pattern. | Tracing is optional and skippable. Varying motor skill is expected. |

Content documents still carry `minMonths` and `maxMonths` (12–60) so an activity can span bands. A child sees an activity when their band overlaps that range. Completing an activity is not mastery and is not a developmental assessment.

## 5. Categories

Curriculum groups for the catalog:

| Category id | What it covers |
| --- | --- |
| `language` | English A–Z; Hindi vowels and consonants; Tamil uyir, mei, and age-appropriate combinations; vocabulary; phonological awareness; pre-writing and tracing. |
| `numbers` | Counting, numerals, quantities, shapes, size, sorting, patterns. Early addition only when age-appropriate. |
| `animals` | Animals and birds. |
| `plants_food` | Plants, fruits, vegetables, food. |
| `everyday` | Body, family, home, school, transport, occupations, weather, nature, community helpers. |
| `thinking` | Matching, visual discrimination, memory, sequencing, classification. |
| `feelings` | Emotions, turn-taking, sharing, routines, personal safety, kindness. |
| `create` | Drawing, coloring, music, rhythm, stories, imaginative prompts. |

Every published activity records: age range, learning objective, prerequisite if any, difficulty, expected duration, interaction type, completion rule, and an accessibility alternative.

The planning catalog (not a commitment) is the requirements appendix: on the order of 20–30 animal lessons, 12–18 colors and shapes, 20–30 number lessons, 15–20 fruits and vegetables, a first alphabet/script set, 20–30 everyday lessons, 10–15 thinking games, and 5–10 original stories or rhymes, each in `en`/`hi`/`ta` where language matters. Final counts wait on educators, rights, localization cost, and pilot feedback.

The first built lesson is one real animal activity (`animal.elephant.001`, tap the picture, hear the word) in all three languages. That lesson is a product increment, not the catalog.

## 6. Screens and journeys

| Journey | Path | Rules |
| --- | --- | --- |
| First launch | Welcome → language → parent gate → local or account explanation → child profile → home | Minimum fields. Local mode is a first-class choice. Privacy notice shown before any account. Account creation can be skipped. |
| Child learning | Home → category → intro → activity → feedback → replay or home | One primary action. Back and home always available. No external links. No modal unless safety or a system permission requires it. |
| Language | Parent gate → settings → language → preview → confirm | UI and lesson locale change. Progress is kept. Missing translation shows “unavailable,” not a mixed-language activity. |
| Offline | Downloads → pack → progress → available offline | Show size, progress, retry, cancel, and version. |
| Parent progress | Parent gate → summary → category → recent activity | Neutral wording. No scores, ranks, streaks, or comparison with other children. No diagnosis. |
| Account conversion | Parent gate → create or sign in → consent → what will sync → confirm merge | Cancellable. Does not duplicate the local profile (`clientProfileId`). |
| Delete account | Parent gate → explanation → confirm → re-authenticate → server result | No success screen while offline. Explain that backups follow the retention rule once one exists. |
| Publish (staff) | Sign in with MFA → draft → locales and assets → checks → reviewer approval → publish | Audit every transition. Rollback is unpublish of the manifest, not a silent edit. |

Required states on every relevant screen: loading, empty, success, recoverable error, offline, retrying, downloading, download failed, content unavailable, session paused, session ended, update available.

Each activity defines exit, replay, completion, what happens if it is interrupted, and what happens when the app is backgrounded. Audio pauses in the background and does not loop.

### Child profile fields

- Nickname (1–24 characters, not a legal name).
- Built-in avatar (star, sun, leaf, moon, bird, fish). No photo, camera, or upload.
- Age band (`1-2`, `2-3`, `3-4`, `4-5`).
- Preferred language and bilingual on/off.

Not collected for core learning: legal name, face photo, exact birth date, birth month, birth year, school, contact details, location.

### Session limit

The parent may set a reminder or limit. At the end, the child sees a gentle stop and a path home. This is an in-app timer. It is not iOS Screen Time and not a device-management control. Copy must not say otherwise.

### Parent gate

Parent settings, any future purchase, account actions, external links, export, and delete sit behind an adult-oriented gate. The gate is asked again each time the parent area is entered. Whether a given gate design meets Apple’s or Google’s current kids rules is a store-review question, not something this PRD can close.

## 7. Functional requirements

Must for the product, mapped to the source ids:

| Id | Requirement |
| --- | --- |
| FR-001 | Caregiver onboarding: purpose, ages, privacy, local vs account. |
| FR-002 | Parent gate on settings, purchases, account, external links, export, and delete. |
| FR-003 | Local profiles with nickname, avatar, age band, language. |
| FR-004 | Optional parent account, sync, and restore after consent. |
| FR-005 | No legal name, face photo, exact birth date, school, contacts, or location required. |
| FR-006 | `en`, `hi`, `ta`, parent default, optional bilingual mode. |
| FR-007 | Each published activity has title, instruction, feedback, labels, and audio metadata per locale, or an explicit approved fallback. |
| FR-008 | Home shows age-appropriate categories and a continue path, without a large catalog dump. |
| FR-009 | Player renders versioned content: picture cards, audio, single choice, matching, sorting, counting, sequencing, tracing. |
| FR-010 | Play, pause, replay. Missing audio fails gently. No indefinite autoplay. |
| FR-011 | Immediate, gentle feedback. Retry or show. No shaming. |
| FR-012 | Record started/completed with time and content version, under the privacy settings. |
| FR-013 | Parent summary: completed activities, categories, recent use, a suggested next activity. Neutral language. |
| FR-014 | Session reminder/limit and a gentle end. Do not claim OS enforcement. |
| FR-015 | Download a pack and play it offline. |
| FR-016 | Account mode syncs with conflict handling and retry. Local mode does not upload. |
| FR-017 | Manifest, versioned download, checksum, rollback to last good pack. |
| FR-018 | Parent screens work with screen readers, contrast, larger text, reduced motion. Activities have a non-audio path where feasible. |
| FR-019 | Privacy notice, export, account deletion, clear local history. |
| FR-020 | Network, storage, download, and playback errors are recoverable. Child-visible copy is child-friendly. Logs omit sensitive payloads. |
| FR-021 | Staff draft, translate, review, approve, and publish in a role-gated console. |
| FR-022 | Audit who created, edited, approved, published, unpublished, or deleted content, and when. |

Should:

| Id | Requirement |
| --- | --- |
| FR-024 | Reminders are parent-configured, opt-in, infrequent, and not urgent or manipulative. Omit push until copy is approved. |
| FR-025 | Parents can filter by category, age band, and language. Children do not get search in the MVP. |

Later, only if a separate decision approves it:

| Id | Requirement |
| --- | --- |
| FR-023 | Platform billing, behind the parent gate, never interrupting a child activity. Off unless monetization is approved. |

### Build order

The full must-list is the product. The first implementation slice is smaller, and the architecture plan phases 2–6 say when each row is built.

**Vertical slice (first):** local profile, `en`/`hi`/`ta`, one real lesson, allowlisted renderer, local progress, offline play after download. No account.

**Before a public account exists:** consent, sync, parent summary, export/delete, and the privacy review.

**Before a second lesson is published:** the admin console and audit log. The first lesson may ship as a reviewed fixture so the slice is not blocked on the console.

## 8. Content and progress rules

- Stable ids. Translated text is never an id.
- Schema-versioned. Only allowlisted interaction types. Remote JSON is data. Unknown types show a safe fallback and do not run code.
- Assets carry rights, source, language, duration or dimensions, checksum, and accessibility text where needed.
- Published versions are immutable. Fixes are new versions. Unpublish rolls the manifest back.
- Progress events are `started` and `completed`, plus a coarse duration bucket. No tap streams, no failure events, no leaderboard.
- Local progress survives an ordinary app restart. Account sync is idempotent: retries do not double-count.
- Diverse families, cultures, abilities, and regional language use. No stereotypes. Original or licensed media only.

## 9. Privacy and safety (release-blocking)

These are product constraints. They do not mean the app has been found compliant.

- Default is local mode and the smallest set of fields that still lets a child learn.
- Account sync is explained in plain language and is off until the parent consents.
- No behavioral ads, no sale of personal data, no ad SDKs, no cross-app tracking, no location, no contacts, no microphone recording, no camera.
- No open chat, public profiles, user-generated public content, or social feed.
- No diagnosis, screening, or claim that the app can identify a developmental disorder.
- No generative AI content shown to children. Any future AI-assisted drafting stays in the staff workflow and is human-reviewed before publish.
- No real-time video.
- Crash logs, analytics, push payloads, and support tickets do not carry nicknames, free text, profile ids, or detailed behavior unless a later review specifically allows a protected case. v1 ships without a crash SDK and without a third-party analytics SDK.
- Parents get a privacy notice, a contact method, export, correction, and deletion once accounts exist. Those flows are blocked on retention periods, which are not set.
- India is the assumed first market to review (DPDP Act, 2023, and the rules in force at launch). Other markets need their own review. Apple’s kids guidelines and Google Play Families policy are review inputs, not boxes this document can tick.

## 10. Non-goals

For the MVP and unless a new reviewed requirement says otherwise:

- No ads, sponsorships inside child activities, or data brokerage.
- No child AI chat, AI tutor, or unreviewed generated lesson shown to a child.
- No diagnosis, developmental score, percentile, or “your child is behind.”
- No leaderboard, competitive rank, streak pressure, or shame copy for a wrong answer.
- No open chat, public profiles, social feed, or user-generated public content.
- No child accounts or child passwords.
- No microphone recording, camera capture, location tracking, or contact upload.
- No real-time video.
- No arbitrary code, script, or HTML in content JSON.
- No claim of OS-enforced screen time.
- No monetization UI until FR-023 is explicitly approved.
- No requirement to create an account to learn.

## 11. Acceptance for the first slice

- A parent can create a local profile in Tamil with no account and finish the elephant lesson offline after the pack is on the device.
- Switching among English, Hindi, and Tamil updates chrome and that lesson’s copy and audio, and keeps progress.
- An unknown or hostile content type shows the fallback and does not crash.
- Completing the lesson once, then killing and reopening the app, still shows one completion.
- A bad checksum is rejected and the app stays usable.

Account sync, deletion, the full catalog, and store filings are later acceptance (requirements AC-02 through AC-12), and they stay release-blocking for those features.

## 12. Open product decisions

Owned outside this PRD, required before the matching build step:

- Repository location.
- Identity provider and cloud/region (engineering assumptions are documented in the architecture plan; they are not product sign-off).
- Target jurisdictions and legal review scope.
- Whether account sync includes the child profile fields or progress only.
- Launch lesson count and audio budget.
- Monetization: remain disabled unless approved.
- Retention, backup expiry, support hours, and final reliability targets.
