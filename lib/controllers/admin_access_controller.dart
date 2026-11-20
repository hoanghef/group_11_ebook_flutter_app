import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/admin_access_repository.dart';
import 'auth_controller.dart';

class AdminAccessController extends ChangeNotifier {
  AdminAccessController(this.auth, this.repository) {
    auth.addListener(_syncAuth);
    _tokenSubscription = repository.tokenChanges.listen((_) => _checkToken());
    _syncAuth();
  }

  final AuthController auth;
  final AdminAccessRepository repository;
  late final StreamSubscription<void> _tokenSubscription;
  String? _uid;
  int _generation = 0;
  bool _disposed = false;
  bool isAdmin = false;
  bool isLoading = false;
  String? error;
  String? get uid => _uid;

  void _syncAuth() {
    final nextUid = auth.status == AuthStatus.signedIn
        ? auth.currentUser?.uid
        : null;
    if (nextUid == _uid) return;
    _uid = nextUid;
    _generation++;
    isAdmin = false;
    isLoading = false;
    error = null;
    notifyListeners();
    if (nextUid != null) unawaited(refresh());
  }

  void _checkToken() {
    if (_uid != null) unawaited(refresh());
  }

  Future<void> refresh({bool forceRefresh = false}) async {
    final uid = _uid;
    if (uid == null) return;
    final generation = ++_generation;
    isLoading = true;
    isAdmin = false;
    error = null;
    notifyListeners();
    try {
      final allowed = await repository.hasAdminClaim(
        forceRefresh: forceRefresh,
      );
      if (!_current(uid, generation)) return;
      isAdmin = allowed;
    } catch (_) {
      if (!_current(uid, generation)) return;
      error = 'Admin access could not be checked. Retry.';
    } finally {
      if (_current(uid, generation)) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _current(String uid, int generation) =>
      !_disposed &&
      _uid == uid &&
      _generation == generation &&
      auth.status == AuthStatus.signedIn;

  @override
  void dispose() {
    _disposed = true;
    auth.removeListener(_syncAuth);
    _tokenSubscription.cancel();
    super.dispose();
  }
}
