# 0002. Account deletion

Date: 2026-11-14 · Status: accepted

## Context
A renter or owner can delete their account from the Profile tab, and everything of theirs goes.
There is no backend (no Cloud Functions), so the app itself must find and delete the data. The
rules treated bookings, ledger rows and reviews as undeletable.

## Decisions

1. **Everything goes, including reviews.** The user's profile and private documents, favourites,
   notifications, cars (with photos and documents), bookings they are a party to (with checklists,
   claims, calendar blocks, locks), ledger rows, repairs, and every review they gave or received.
   No anonymising and no soft delete.
2. **A booking disappears for the other party too.** Bookings, ledger rows and reviews are shared
   with the counterpart, so the counterpart loses them as well. Accepted for simplicity.
3. **Client-side cascade.** `FirestoreAccountEraser` finds documents by query and deletes them in
   batches: documents whose rules read a parent first, then bookings and cars, then `users/{uid}`.
   Re-running it after a failure finishes the job.
4. **Rules open delete only where needed:** the user, bookings (parties), ledger rows (the two
   parties) and reviews (author, subject, or a party of the booking). The app has no other delete
   path for the ledger or reviews, so "append-only" and "no delete" now hold by convention in the app
   and not by the rules alone. Audit logs stay create-only and remain.
5. **No prompt for Google users.** Firebase refuses to delete a stale session, and the only way
   to refresh a Google session is a Google sheet, which the user must not see. So a Google account
   has its data erased, then Firebase is asked to delete the Auth user and the refusal is ignored,
   then the user is signed out. If the Auth record stays, it is a bare uid with no profile, which the
   app treats as a new user: "Continue with Google" starts a fresh sign-up on it. Email accounts
   type their password in the dialog, re-authenticate with it, erase, delete the Auth user and sign
   out, so the email can be used to sign up again.
6. **Uploaded files are removed best effort**, like `MediaStorage.delete` (ADR 0001, point 7).

## Consequences
- Other users' rating aggregates and favourites are not touched (no backend to do it, and rules
  forbid editing another user's document), so a counterpart's average can still include a deleted
  review until the next review is written, and their favourites may point at a deleted car.
- The counterpart's own copy of the booking contact (`bookings/{id}/private/{side}`) cannot be
  deleted by the user leaving; it becomes unreachable once the booking is gone.
- Notifications sent to other users about a deleted booking remain.
- A deleted Google account may leave its bare Firebase Auth record (visible in the console, not in
  the app). Removing it needs a backend.
- For an email account, a failure after the data is gone but before the Auth user is deleted leaves a
  signed-in account with no profile. Re-authenticating right before makes this unlikely.
