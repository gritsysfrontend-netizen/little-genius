# Little Genius

Little Genius is a small learning app for young children. This repository holds a local lesson slice: sample activities in English, Hindi, and Tamil, stored on the device. The samples are a tap-to-learn elephant, a color choice, a matching pair, a sorting activity, a counting activity, and an ordering activity. A grown-up creates a local profile. The home screen shows a category only when a sample overlaps that profile’s age band and has that profile’s language. The child can download an activity and play it again without a network connection. A grown-up can also set a play reminder that stays inside the app.

This is not a finished product. It is not ready for a store, a school, or real child accounts.

## What you can try

- Read the screen that explains local mode. An account is not required, and an account is not part of this version.
- Create a profile with a nickname, a picture, an age band, and a language.
- Switch the app’s buttons and labels between English, Hindi, and Tamil.
- Download the elephant activity.
- Tap the picture, hear the short instruction, and see that “started” and “finished” stay on the device after you close the app.
- Open the other sample activities for the age band you chose. A wrong tap stays gentle and does not mark the activity as failed.
- In Grown-ups, open Downloads. It shows the space used, the installed pack, and which activities are not on the device yet. You can download the pack, cancel it, or try again. A pack that fails its checksum is not saved. The last pack that checked out stays.
- In Grown-ups, open Progress. It lists finished activities, categories that were opened, recent activity, and one activity you could try next. The list is read from this device. It is not a score, a streak, or a comparison, and it is not uploaded.

The Hindi and Tamil sounds were made with a text-to-speech tool for this engineering slice. A native speaker has not signed off on them. The Hindi and Tamil sentences on the caregiver screen, the play reminder, the sample activities, the downloads screen, and the progress screen have not had native-speaker review either.

## Run the API

Install Docker, then from the repository root:

```bash
docker compose -f infrastructure/docker/compose.yaml up --build
```

The API listens on `http://127.0.0.1:3000`.

- Health: `http://127.0.0.1:3000/api/v1/health`
- Lesson list: `http://127.0.0.1:3000/api/v1/content/manifest?locale=en&ageBand=2-3`

The compose file starts PostgreSQL 17 and the API. It does not start Redis. The database password in that file is only for this local demo. Do not reuse it anywhere else, and do not put real secrets in the repository.

## Run the app in a browser

Install the Flutter stable channel, then:

```bash
cd apps/mobile_web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Start the API first. In the app, create a profile, open a category for that age band, and download an activity. After that, a saved activity can play if the API is stopped. An activity plays in a language only when that language is part of the activity.

On the web, the browser can delete saved lessons. A phone keeps them more reliably. The web build does not use SQLite.

## Run on a phone

Android and iOS project files are in `apps/mobile_web`. A debug build can reach an API on the same computer:

- Android emulator: `http://10.0.2.2:3000`
- iOS simulator: `http://127.0.0.1:3000`

```bash
cd apps/mobile_web
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Cleartext HTTP is allowed only for localhost and the emulator host. This environment does not have an Apple signing certificate or an iOS device, so the iOS app has not been compiled here.

## Play reminder

In the grown-up area, open Play reminder. You can leave it off or choose 5, 10, 15, or 20 minutes. The reminder counts only while Little Genius is open and in the foreground. When it finishes, the child sees a rest screen and can go home. It does not lock the phone. It is not Screen Time, and it is not a control for the whole device.

Closing the app forgets how much of the current reminder has passed. The choice of minutes is kept on the device.

## Checks

From `services/api` (Node.js 24 and PostgreSQL 17):

```bash
npm run format:check
npx prettier --check ../content_admin
npm run openapi:check
npm test
npm audit --audit-level=high
```

From `services/content_admin`:

```bash
node --experimental-strip-types --test test/*.test.ts
```

From the repository root:

```bash
node scripts/scan-secrets.mjs
```

From `apps/mobile_web`:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

The IndexedDB check is separate because it needs Chrome:

```bash
flutter test --platform chrome test/web/indexeddb_repository_test.dart
```

GitHub Actions runs those checks, plus `npm audit`, the secret scan, and `docker build` for the API image. The OpenAPI step checks that the operation list in `services/api/openapi/openapi.yaml` still matches the inventory in `services/api/scripts/check-openapi.mjs`. It is not a hosted spec diff.

## What is not built

Accounts, sign-in for families, cloud sync, tracing, payments, push notifications, analytics, crash reporting, and Redis are not in this slice. Account export and deletion are named in the grown-up area and are not implemented. Parent account routes exist only as schemas and an API description. The app does not upload progress.

Staff can open a separate console with `node --experimental-strip-types src/serve.ts` from `services/content_admin`. It listens on `http://127.0.0.1:3010` and calls `/admin/v1` only. It is not linked from the child app. The API accepts a staff token only when `IDENTITY_PROVIDER=test` is set, and that switch is an unsigned test double, not a Cognito account. Do not turn it on for a shared or public server. A parent token, a token without an MFA claim, and a token without the required role are rejected by the API. The existing sample lessons still load from the reviewed fixture files. A new lesson is published from the staff console, not by adding another fixture file.

Staging and production cloud projects are not created here. The host has not been chosen. GitHub secret-scanning administration and a hosted OpenAPI diff are not set up from this repository. This environment has no Apple signing certificate, so the iOS app has not been compiled here.

The plans and decision records live in `docs/`.
