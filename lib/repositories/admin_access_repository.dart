abstract class AdminAccessRepository {
  Stream<void> get tokenChanges;
  Future<bool> hasAdminClaim({bool forceRefresh = false});
}
