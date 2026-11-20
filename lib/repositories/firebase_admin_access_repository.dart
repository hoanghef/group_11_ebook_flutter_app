import 'package:firebase_auth/firebase_auth.dart' as firebase;

import 'admin_access_repository.dart';

class FirebaseAdminAccessRepository implements AdminAccessRepository {
  FirebaseAdminAccessRepository(this.auth);

  final firebase.FirebaseAuth auth;

  @override
  Stream<void> get tokenChanges => auth.idTokenChanges().map((_) {});

  @override
  Future<bool> hasAdminClaim({bool forceRefresh = false}) async {
    final user = auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['admin'] == true;
  }
}
