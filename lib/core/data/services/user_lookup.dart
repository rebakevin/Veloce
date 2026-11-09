import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_paths.dart';
import '../../domain/entities/user_account.dart';
import '../models/user_account_model.dart';
import 'cached_document_lookup.dart';

/// Cached read-by-id and stream of [UserAccount] for cross-feature reads.
class UserLookup extends CachedDocumentLookup<UserAccount> {
  UserLookup(FirebaseFirestore firestore)
    : super(
        firestore: firestore,
        collection: FirestorePaths.users,
        fromMap: UserAccountModel.fromMap,
      );
}
