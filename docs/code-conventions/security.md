# Security and authorization

- Authentication (who you are) and authorization (what you may do) are separate concerns. Auth is Firebase Auth. Authorization is `users/{uid}.role` plus the Firestore rules.
- **The server is the gate.** Firestore rules enforce every permission. The UI hiding a button is a convenience, never protection. When adding a feature, update `firestore.rules` and its Playground cases in the same change.
- Deny by default. Every new collection or field needs an explicit rule.
- Enforce authorization in the domain too (`canEdit(report, user)`), not only in widgets, so a Cubit cannot be driven into a forbidden action.
- Least privilege: students cannot write staff fields, staff cannot edit content, nobody changes `role`.
- Never trust client input. Validate in the app for UX, and rely on the rules for enforcement. Never send a client-chosen `role`.
- Role comes only from `users/{uid}.role`. No custom claims, no values from the token that the user controls.

## Secrets and keys

- Secrets never go in the repo, logs or error messages. `.env` is gitignored; commit only `.env.example`.
- The Supabase publishable key and Firebase client identifiers are public by design. Anything that is not (service account keys, admin tokens, Supabase service-role key) must never be added to the app, `.env` or the repo.
- `scripts/` that act as an admin use the developer's own login and must not print tokens.

## Input and output

- Validate and normalize at the boundary. Encode for the sink: never build Firestore field paths or Storage paths from raw user text. Photo object names are generated (`randomId`), never user-provided.
- Do not log personal data or tokens. Sanitize user-supplied values before logging.
- Do not reveal internals in error messages (paths, SDK text, whether an email exists).
- Login and reset flows give the same message for "no such user" and "wrong password" where the SDK allows it.

## Accounts and sessions

- Registration accepts only the student domain. Staff accounts are created by an admin, never through the app.
- Require a verified email before granting access, in the UI and in the rules.
- Sign-out clears Cubit state and cached user data.
- Dev-only shortcuts (skipping verification, test accounts) must be impossible to enable in a release build. Guard with `kReleaseMode` or remove them.

## Dependencies

- Keep dependencies patched. Review `flutter pub outdated` periodically and avoid unmaintained packages.
- Do not add a package for something the SDK already does.
- Android: release builds are obfuscated and use a proper signing key kept outside the repo.

## Review checklist

Before merging a change that touches data or auth: rules updated, Playground cases updated, no new public paths, no secret added, error messages leak nothing, OWASP Mobile Top 10 skimmed.
