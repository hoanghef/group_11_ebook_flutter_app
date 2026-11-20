import 'admin_access_repository.dart';

class UnavailableAdminAccessRepository implements AdminAccessRepository {
  @override
  Stream<void> get tokenChanges => const Stream.empty();

  @override
  Future<bool> hasAdminClaim({bool forceRefresh = false}) async => false;
}
