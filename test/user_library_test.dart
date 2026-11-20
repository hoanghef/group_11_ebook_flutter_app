import 'dart:async';

import 'package:app_ebook/controllers/auth_controller.dart';
import 'package:app_ebook/controllers/user_library_controller.dart';
import 'package:app_ebook/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const userA = AppUser(uid: 'user-a', email: 'a@example.com', displayName: 'A');
const userB = AppUser(uid: 'user-b', email: 'b@example.com', displayName: 'B');

Future<void> flushAuth() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'Favorites restore by UID and clear immediately on account change',
    () async {
      final authRepository = FakeAuthRepository(currentUser: userA);
      final auth = AuthController(authRepository);
      final repository = FakeUserLibraryRepository()
        ..favorites['user-a'] = {'one'}
        ..favorites['user-b'] = {'two'};
      final library = UserLibraryController(auth, repository);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepository.dispose);

      await flushAuth();
      expect(library.isFavorite('one'), isTrue);
      authRepository.emitUser(userB);
      await flushAuth();
      expect(library.uid, 'user-b');
      expect(library.isFavorite('one'), isFalse);
      expect(library.isFavorite('two'), isTrue);
      authRepository.emitUser(null);
      await flushAuth();
      expect(library.favoriteIds, isEmpty);
      auth.enterGuest();
      expect(await library.setFavorite('one', true), isFalse);
      expect(await library.saveReadingProgress('one', 0.3), isFalse);

      authRepository.emitUser(userA);
      await flushAuth();
      expect(library.isFavorite('one'), isTrue);
    },
  );

  test(
    'Late favorite load and write cannot overwrite another account',
    () async {
      final authRepository = FakeAuthRepository(currentUser: userA);
      final auth = AuthController(authRepository);
      final repository = FakeUserLibraryRepository();
      final pendingLoad = Completer<Set<String>>();
      repository.pendingFavorites['user-a'] = pendingLoad;
      final library = UserLibraryController(auth, repository);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepository.dispose);

      await flushAuth();
      expect(library.isLoadingFavorites, isTrue);
      authRepository.emitUser(userB);
      await flushAuth();
      pendingLoad.complete({'one'});
      await flushAuth();
      expect(library.favoriteIds, isEmpty);

      repository.pendingWrite = Completer<void>();
      final write = library.setFavorite('two', true);
      authRepository.emitUser(userA);
      await flushAuth();
      repository.pendingWrite!.complete();
      expect(await write, isFalse);
      expect(library.isFavorite('one'), isTrue);
      expect(library.isFavorite('two'), isFalse);
    },
  );

  test(
    'Loading, retry and failed write do not claim favorite was saved',
    () async {
      final authRepository = FakeAuthRepository(currentUser: userA);
      final auth = AuthController(authRepository);
      final repository = FakeUserLibraryRepository()..failLoad = true;
      final library = UserLibraryController(auth, repository);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepository.dispose);
      await flushAuth();
      expect(library.favoritesError, isNotNull);
      repository.failLoad = false;
      await library.loadFavorites();
      expect(library.favoritesError, isNull);
      repository.failWrite = true;
      expect(await library.setFavorite('one', true), isFalse);
      expect(library.isFavorite('one'), isFalse);
      expect(library.favoritesError, isNotNull);
      repository.failWrite = false;
      await library.loadFavorites();
      expect(await library.setFavorite('one', true), isTrue);
      expect(library.isFavorite('one'), isTrue);
    },
  );

  test(
    'Reading ratio restores by UID and failed save retries next update',
    () async {
      final authRepository = FakeAuthRepository(currentUser: userA);
      final auth = AuthController(authRepository);
      final repository = FakeUserLibraryRepository()
        ..progress['user-a'] = {'one': 0.4}
        ..progress['user-b'] = {'one': 0.8};
      final library = UserLibraryController(auth, repository);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepository.dispose);
      await flushAuth();
      expect(await library.loadReadingProgress('one'), 0.4);
      repository.failProgress = true;
      expect(await library.saveReadingProgress('one', 0.55), isFalse);
      expect(library.progressError, isNotNull);
      expect(await library.loadReadingProgress('one'), 0.55);
      expect(library.progressLoadFailed, isFalse);
      repository.failProgress = false;
      expect(await library.saveReadingProgress('one', 0.6), isTrue);
      expect(repository.progress['user-a']!['one'], 0.6);
      authRepository.emitUser(userB);
      await flushAuth();
      expect(await library.loadReadingProgress('one'), 0.8);
      authRepository.emitUser(null);
      await flushAuth();
      expect(await library.saveReadingProgress('one', 0.9), isFalse);
      expect(repository.progress['user-b']!['one'], 0.8);
    },
  );

  test('Late reading load and write cannot update a new UID', () async {
    final authRepository = FakeAuthRepository(currentUser: userA);
    final auth = AuthController(authRepository);
    final repository = FakeUserLibraryRepository()
      ..pendingProgressLoad = Completer<double?>();
    final library = UserLibraryController(auth, repository);
    addTearDown(library.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepository.dispose);
    await flushAuth();

    final oldLoad = library.loadReadingProgress('one');
    authRepository.emitUser(userB);
    await flushAuth();
    repository.pendingProgressLoad!.complete(0.9);
    expect(await oldLoad, isNull);

    repository.pendingProgressWrite = Completer<void>();
    final oldWrite = library.saveReadingProgress('one', 0.7);
    await flushAuth();
    authRepository.emitUser(userA);
    await flushAuth();
    repository.pendingProgressWrite!.complete();
    expect(await oldWrite, isFalse);
    expect(library.uid, 'user-a');
    expect(library.progressError, isNull);
  });
}
