# Ebook Firebase development runbook

The dedicated project is **`ebook-dev-20261119-a7b3`** (display name **Ebook
Development**). Firebase CLI created it on 2026-11-19. FlutterFire registered
Android package `com.example.app_ebook` and generated client configuration for
Firebase Android app `1:450111148161:android:170b93ea1081fbd7923d80`.
Auth Email/Password was enabled with `firebase deploy --only auth --project
ebook-dev-20261119-a7b3`; Firebase CLI also provisioned a Default Web App for
Auth. On 2026-11-19, Firestore `(default)` was created in Bangkok
(`asia-southeast3`) as Standard/Native. The database list showed exactly one
database, with `freeTier: true`. It began with closed client rules. The repo's
`firestore.rules` was then compiled and deployed with `--only firestore:rules`
to this project. The active remote ruleset SHA-256 matched the local file:
`14982d1f055b469131eb5b0b8db182dc611bac5c5bfd792f5f0d11d43f554ffe`.
Catalog seeding, custom claims and live account tests are recorded below.
This work did not request billing or enable Analytics, Storage or Functions;
the project's billing state has not been independently checked. The local
`demo-ebook` ID is only for Emulator rules tests.

## Verification and live results (updated 2026-11-20)

The rules Emulator passed 15/15 tests before and after deployment using OpenJDK 21.
The active ruleset read back from the Ebook project is
`projects/ebook-dev-20261119-a7b3/rulesets/2be176e2-c8c3-4493-87f3-677e4bb14528`;
its SHA-256 matches the local rules file. The deployment targeted only
`firestore:rules`.

The demo catalog has been seeded to the development Firestore: **13 categories
and 11 fictional books** are present. Guest flow, user accounts, and personal
library persistence were tested against real Firebase services.

An administrative probe was conducted using test account UID
`H3WtuFkTp6Omh7EAJWK5x99OPSW2` with `cv_admin_probe` entries:
- A draft book created during probe remained strictly invisible to public
  queries and guests (`status == 'published'` query and security rule constraint).
- Following verification, the test admin claim was **revoked and verified via
  Admin SDK** (`admin_after: false`).
- **Do not re-grant admin claim to this UID unless strictly required for a
  designated live test.**

The live Firebase checks are strictly separated from the local 15 Rules Emulator
tests as follows:

| Development check | Result | Scope / Detail |
| --- | --- | --- |
| Guest sees 11 books / 13 categories | Passed | Live Firebase development (Firestore Bangkok) |
| Register, sign in, sign out, sign back in | Passed | Live Firebase Auth session management |
| Two UIDs remain isolated | Passed | Live Firestore subcollections under `users/{uid}/*` |
| Favorites, bookmarks, notes, search history restore | Passed | Live Firestore subcollections under `users/{uid}/*` |
| Admin probe: draft book hidden from public catalog | Passed | Live Firestore query constraint (`status == 'published'`) |
| Admin claim revocation | Passed | Verified via Admin SDK (`admin_after: false`) |
| Non-scrollable preview reading progress safety | Verified via tests | Verified via widget test suite (`user_library_widget_test.dart`) |
| Reading progress restore on physical device | Chưa kiểm tra live | Verified via local unit and widget test suite |
| Archived book behavior in live catalog | Chưa kiểm tra live | Verified via local Rules Emulator (15/15 tests) |
| Catalog write rejection after claim revoke on live UI | Chưa kiểm tra live | Verified via local Rules Emulator and Admin SDK check |
| Network loss / offline recovery on physical device | Chưa kiểm tra live | Partially observed on emulator; not verified on live physical device |

To continue online seed and claim management, use a trusted workstation with
Google Cloud CLI already installed and run `gcloud auth application-default
login` interactively outside this repo, or authorize installing that CLI on
this workstation first. Confirm the resulting account has the required
Firestore and Auth administration permissions on **only**
`ebook-dev-20261119-a7b3`. Do not copy ADC files, tokens or service-account
keys into the repo. Then run the seed tool's online preview, review CREATE/SKIP,
and apply only missing documents with the exact project confirmation.

## Identify and connect the project

1. Firestore `(default)` is already in `asia-southeast3`. Its location cannot be
   changed after creation. Do not create another database. Use only
   `ebook-dev-20261119-a7b3` for development and deploy only the reviewed
   Firestore rules when they change.
2. Auth Email/Password and FlutterFire Android registration are complete. The
   current `com.example.app_ebook` package ID is for development; choose a
   permanent ID before release. `lib/main.dart` uses the generated
   `DefaultFirebaseOptions.currentPlatform`. Never add an Admin service-account
   JSON, private key, ADC token, or credential to the repo.
3. Build the Android debug APK in an isolated project copy, as the untracked
   `android/build/reports/problems/problems-report.html` must be preserved.

## Seed the fictional demo catalog

`tool/export_demo_catalog.dart` reads the current Dart sample data directly.
It validates 13 distinct categories, 11 distinct books, category references,
cover styles and the 2,000 character preview limit. The Node tool uses Firebase
Admin SDK with Application Default Credentials from a trusted administration
environment. It requires an explicit Ebook development project ID, prints the
target, and refuses Coffee, production and Emulator IDs. No service-account
file belongs in this repo. From a fresh checkout, resolve the Flutter lockfile
with `flutter pub get --enforce-lockfile` and install Node dependencies with
`npm ci` before running the tools. The Admin SDK requires Node 22 or newer.

```powershell
dart tool/export_demo_catalog.dart
npm run test:tools
node tool/seed_demo_catalog.mjs --project-id <ebook-dev-id> --offline-plan
node tool/seed_demo_catalog.mjs --project-id <ebook-dev-id>
node tool/seed_demo_catalog.mjs --project-id <ebook-dev-id> --apply --confirm-project <ebook-dev-id>
```

`--offline-plan` prints source IDs without credentials or a Firestore request.
The ordinary preview reads the target database and lists CREATE/SKIP actions.
The apply command creates **only missing** documents; it never deletes or
overwrites existing documents. To intentionally replace demo metadata in
existing documents, first review the preview with `--update-existing`, then
repeat it with `--apply --confirm-project <ebook-dev-id>`. Updates keep document
IDs and `createdAt` unchanged, and refresh `updatedAt`. Sample book creation
timestamps remain the dates in Dart; category creation timestamps use server
time. All 11 books are published, all 13 categories active, and covers use
`generated:*` references. Admin SDK writes bypass Firestore rules, so run this
only in a trusted environment after checking the target ID.

## Manage Admin access

Only the trusted tool may grant or remove `admin: true`; no client screen does
so. Choose a test account UID from the verified Ebook development project. The
tool preserves all other custom claims and prints only UID and Admin status,
not tokens or other claim values.

```powershell
node tool/manage_admin_claim.mjs --project-id <ebook-dev-id> --uid <test-uid> --grant
node tool/manage_admin_claim.mjs --project-id <ebook-dev-id> --uid <test-uid> --grant --apply --confirm-project <ebook-dev-id>
node tool/manage_admin_claim.mjs --project-id <ebook-dev-id> --uid <test-uid> --revoke --apply --confirm-project <ebook-dev-id>
```

The first command previews the change. After applying, refresh the user's ID
token from the app's account access control or sign in again. Confirm Admin
workspace visibility and catalog write permissions against Firestore rules.
Revoking a claim may require another token refresh or sign-in before the UI
updates. Never put this tool or Admin SDK in the Flutter client.

## Live Android verification checklist

Use only test accounts and sample data in the Ebook development project:

- Guest: published books and active categories appear; personal library writes
  require sign-in.
- Register, sign in, sign out, sign back in: session and profile behave as
  expected.
- Favorites, scroll ratio, bookmarks, notes and submitted search history
  restore for the same UID; a second UID sees none of the first UID's data.
- An ordinary UID has no Admin workspace and Firestore denies catalog writes.
- An Admin UID can create or edit a test catalog item; draft and archived books
  stay out of public queries. Archive test items rather than deleting them.
- Retry offline and permission denied cases; record UI messages and crashes.

Record each result separately from Flutter fake tests and Emulator rules tests.
Passing those local tests does not prove live Firebase configuration or access.
