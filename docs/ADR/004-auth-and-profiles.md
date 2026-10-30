# ADR 004 — Parent auth and child profiles

- Status: Accepted for the planning baseline, with a named vendor assumption
- Date: 2026-10-29
- Related: `docs/architecture-plan.md` §5.3, §6; `docs/PRD.md` §2, §6

## Context

Core learning must work with no account. Optional parent accounts need sign-in, sync, export, and deletion. Children must not be authenticated users. The requirements leave the identity provider open and allow either an age band or a birth month/year on the profile. Exact birth date, legal name, face photo, school, contacts, and location are forbidden as requirements for learning.

Staff publishing needs MFA and roles that parents do not have. Tokens must not be embedded as long-lived secrets in the app. Web has no Keychain equivalent.

No provider has been selected by the product owner.

## Decision

- Children never authenticate. A child profile is a record owned by a parent account, or a record that exists only on the device.
- Profiles store nickname, built-in avatar id, age band (`1-2`, `2-3`, `3-4`, `4-5`), preferred locale, and bilingual flag. They do not store birth date, birth month, birth year, legal name, photo, school, email, phone, or location.
- Parent and staff sign-in is OIDC Authorization Code with PKCE against a managed issuer. The API validates JWTs and stores the subject (`sub`). It does not store passwords, and it does not copy email or phone into PostgreSQL in v1.
- **Assumption until Product + Security choose a vendor:** Amazon Cognito, in the same region as the database (working region `ap-south-1` if India remains the launch market). Parents and staff use different app clients or pools. Staff calls require an MFA claim. Another OIDC issuer is acceptable if it offers PKCE, refresh rotation, revocation, account deletion, staff MFA, and a data-processing review. Firebase Auth is not the default.
- iOS and Android keep refresh tokens in platform secure storage, and only after account mode exists. Web does not. Web remains local-mode until a reviewed cookie session exists.
- Every profile and progress query is scoped by the token’s account. Unknown and unowned profile ids return the same `404`.
- Account deletion revokes IdP sessions, deletes or de-identifies profiles and events, and does not erase audit rows. Consent-row retention is not decided here and blocks production accounts.

## Consequences

- The vertical slice has no IdP dependency. Phase 5 cannot start the consent UI until the vendor and the jurisdiction review are real, not assumed.
- Replacing Cognito is an adapter change if the replacement is OIDC. It is not a profile-schema change.
- Age-band-only profiles can mis-target a child who is between bands. The parent can change the band. The product accepts that in exchange for not holding a birth date.
- Nicknames are still personal data once uploaded. Keeping them out of the server until consent is what makes local mode the privacy default.
- Authorization tests are part of the account milestone (altered id must not reveal whether a profile exists).
- This ADR does not assert that Cognito, or any consent screen, satisfies the DPDP Act or store account-deletion rules. Those are open reviews.
