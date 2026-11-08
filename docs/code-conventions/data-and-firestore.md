# Data: Firestore and Supabase

`docs/Veloce Database Design.md` is the authority on collections, fields, rules and the W1 to W8 write operations. This file covers how to write the code against it well.

## Write boundaries (the "transaction" rules)

- One use case, one write: multi-document changes are a single `WriteBatch`. The security rules depend on this (`getAfter()`, `existsAfter()`), so never split a documented batch into separate writes.
- Batches and transactions live in the repository, which is the one place that knows the write shape. Cubits call a repository method named for the use case (`createReport`, `updateStatus`, `toggleVote`).
- Keep them short. No remote calls inside a batch or transaction.
- Make operations safe to retry. Client-generated ids (`doc().id`) and `set` make a retry produce the same result. Vote toggles use `FieldValue.increment(±1)` tied to the vote document, as the rules require.
- Order matters when two systems are involved: upload photos first, write the batch second, and clean up uploaded files if the batch fails (W2). Delete files only after the batch succeeds (W3, W4).

## Server-controlled values

- `createdAt` and `updatedAt` use `FieldValue.serverTimestamp()`, because the rules require `== request.time`. Never `DateTime.now()`.
- Optional values are explicit `null` (or `""` for `room`). Never omit a key. The rules check exact key sets.
- Send exactly the documented keys, no extras.

## Reads and queries

- Avoid N+1 reads: do not fetch a document per list item. Denormalize the display values the Database Design already snapshots (`reporterName`, `reportTitle`).
- Paginate any list that can grow. Use `limit` and `startAfterDocument`. Never return an unbounded collection.
- Every query combination must have an index in `firestore.indexes.json`. Add the index in the same change as the query, and deploy it.
- Respect the documented limits: a date range plus a vote sort, and a title search plus a date range, cannot both run on the server. Apply one on the client explicitly and say so in a comment.
- Select only what is needed: use aggregate `count()` for badges and status counters instead of reading documents.
- Use streams for live data and one-off `get()` for data that does not change under the user.

## Concurrency

- Assume two clients act on the same document at once. Use the batch preconditions the rules enforce (vote doc plus counter) instead of read-modify-write in the client.
- A loser of a race sees a permission error. Handle it as "refresh and retry", not as a crash (see [error-handling.md](error-handling.md)).

## Schema evolution

- The schema is final per the Database Design. A change is a production change: update the Design doc, the rules, the indexes, the models and the tests in the same change.
- Changes must be backward compatible (add optional, migrate, then tighten) because installed clients keep running old code.
- Enum values are stable string keys. Add values, never rename or reuse them. A new category or building also needs an edit in `firestore.rules`.

## Ownership

- Each feature owns its collections. Other features read through the owner's repository or exported model, never by querying its collections directly.

## Constraints in the database too

- The security rules are the database constraints: types, lengths, enums, immutable fields. Dart validation is for good UX; rules are the enforcement. Keep both in sync, and treat a mismatch as a bug.
- No business rules hidden anywhere except the rules file and the domain.

## Supabase Storage

- Only the storage adapter (`PhotoStorage` or the like) imports `supabase_flutter`.
- The report stores `photoPaths`, never URLs. The adapter resolves a path to a public URL at read time.
- Compress to JPEG on device, reject over 5 MB, cap at 5 photos, before any upload.
- Policies are limited to the `reportPhotos/` prefix. The app, not Supabase, enforces "owner only, only while Submitted". Check this in the repository before upload and delete.
- Timestamps are stored as Firestore `Timestamp`. Convert to `DateTime` at the mapper and display in local time.
