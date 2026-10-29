# Fixture review — animal.elephant.001

Status: engineering fixture for the Phase 2 slice. This is not a native-speaker sign-off and not an educator sign-off.

| Field | Record |
| --- | --- |
| Content id | `animal.elephant.001` |
| Version | 1 |
| Schema | 1.0 |
| Interaction | `tap_to_learn` |
| Locales | `en`, `hi`, `ta` |
| Image | `assets/img.elephant.001.png` |
| Audio | `assets/aud.elephant.{en,hi,ta}.instruction.mp3` |

## Rights

- The elephant picture is an original illustration created for this repository. It is not clip art and not a copied character.
- The instruction clips were synthesized for this repository with eSpeak NG 1.51 (`en-us`, `hi`, `ta`). They are not commercial recordings and not copied audio.
- No third-party asset is embedded in the lesson document.

## What was checked here

- The document matches `packages/content_schema/lesson-document.schema.json`.
- Asset byte sizes are under the Phase 2 caps (image under 1 MB, each clip under 2 MB).
- SHA-256 values in the document match the files. `infrastructure/scripts/verify-checksums.mjs` rechecks that.
- Copy is the short instruction for the clip that was synthesized: “Tap the elephant”, “हाथी पर टैप करें”, “யானையைத் தொடு”.

## What this review does not claim

Hindi and Tamil speech is robotic text-to-speech, not a reviewed native performance. Publishing a second lesson still requires the Phase 4 review workflow. Unpublish remains a status change; this file is not rewritten in place after it is published.
