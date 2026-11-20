import 'dart:async';

import 'package:app_ebook/controllers/admin_access_controller.dart';
import 'package:app_ebook/controllers/admin_catalog_controller.dart';
import 'package:app_ebook/controllers/admin_catalog_validator.dart';
import 'package:app_ebook/controllers/auth_controller.dart';
import 'package:app_ebook/models/admin_book.dart';
import 'package:app_ebook/models/category.dart';
import 'package:app_ebook/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_admin_repositories.dart';
import 'fake_auth_repository.dart';

const adminUser = AppUser(
  uid: 'admin-user',
  email: 'admin@example.com',
  displayName: 'Admin',
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('Admin claim controls access and refresh can revoke it', () async {
    final authRepo = FakeAuthRepository(currentUser: adminUser);
    final auth = AuthController(authRepo);
    final token = FakeAdminAccessRepository(claim: true);
    final access = AdminAccessController(auth, token);
    final repository = FakeAdminCatalogRepository();
    final catalog = AdminCatalogController(access, repository);
    addTearDown(catalog.dispose);
    addTearDown(access.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepo.dispose);
    addTearDown(token.dispose);
    await flush();
    expect(access.isAdmin, isTrue);
    expect(
      catalog.books.map((item) => item.status),
      containsAll(['draft', 'archived']),
    );
    token.claim = false;
    token.emitToken();
    await flush();
    expect(access.isAdmin, isFalse);
    expect(catalog.books, isEmpty);
    token.claim = true;
    await access.refresh(forceRefresh: true);
    await flush();
    expect(token.lastForce, isTrue);
    expect(access.isAdmin, isTrue);
    authRepo.emitUser(null);
    await flush();
    expect(access.isAdmin, isFalse);
    expect(catalog.categories, isEmpty);
  });

  test(
    'Late token result and errors never grant another session access',
    () async {
      final authRepo = FakeAuthRepository(currentUser: adminUser);
      final auth = AuthController(authRepo);
      final token = FakeAdminAccessRepository()..pending = Completer<bool>();
      final access = AdminAccessController(auth, token);
      addTearDown(access.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepo.dispose);
      addTearDown(token.dispose);
      await flush();
      expect(access.isLoading, isTrue);
      authRepo.emitUser(null);
      await flush();
      token.pending!.complete(true);
      await flush();
      expect(access.isAdmin, isFalse);
      token.pending = null;
      token.fail = true;
      authRepo.emitUser(adminUser);
      await flush();
      expect(access.error, isNotNull);
      expect(access.isAdmin, isFalse);
    },
  );

  test('Validator enforces generated covers and active categories', () {
    expect(
      AdminCatalogValidator.coverStyles,
      hasLength(greaterThanOrEqualTo(3)),
    );
    for (final style in AdminCatalogValidator.coverStyles) {
      expect(style, startsWith('generated:'));
    }
    final repository = FakeAdminCatalogRepository();
    final valid = repository.books.first;
    expect(
      AdminCatalogValidator.bookError(valid, repository.categories),
      isNull,
    );
    final invalidCover = AdminBook(
      id: 'new',
      title: 'Title',
      author: 'Writer',
      description: '',
      coverRef: 'https://example.com/cover.jpg',
      categoryIds: ['fiction'],
      status: 'draft',
      preview: '',
      contentRef: '',
    );
    expect(
      AdminCatalogValidator.bookError(invalidCover, repository.categories),
      contains('generated cover'),
    );
    final inactive = AdminBook(
      id: 'new',
      title: 'Title',
      author: 'Writer',
      description: '',
      coverRef: AdminCatalogValidator.coverStyles.first,
      categoryIds: ['hidden'],
      status: 'draft',
      preview: '',
      contentRef: '',
    );
    expect(
      AdminCatalogValidator.bookError(inactive, repository.categories),
      contains('active'),
    );
    expect(
      AdminCatalogValidator.bookError(
        repository.books.last,
        repository.categories,
        original: repository.books.last,
      ),
      isNull,
    );
    final tooLong = AdminBook(
      id: 'new',
      title: 'Title',
      author: 'Writer',
      description: '',
      coverRef: AdminCatalogValidator.coverStyles.first,
      categoryIds: ['fiction'],
      status: 'draft',
      preview: List.filled(2001, 'x').join(),
      contentRef: '',
    );
    expect(
      AdminCatalogValidator.bookError(tooLong, repository.categories),
      contains('Preview'),
    );
    expect(
      AdminCatalogValidator.categoryError(
        Category(id: 'Invalid ID', name: 'Name', description: ''),
      ),
      contains('lowercase'),
    );
  });

  test(
    'Admin saves status and category; failed write does not update state',
    () async {
      final authRepo = FakeAuthRepository(currentUser: adminUser);
      final auth = AuthController(authRepo);
      final token = FakeAdminAccessRepository(claim: true);
      final access = AdminAccessController(auth, token);
      final repository = FakeAdminCatalogRepository();
      final catalog = AdminCatalogController(access, repository);
      addTearDown(catalog.dispose);
      addTearDown(access.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepo.dispose);
      addTearDown(token.dispose);
      await flush();
      expect(
        await catalog.saveBook(catalog.books.first),
        'Book ID already exists.',
      );
      expect(
        await catalog.saveCategory(catalog.categories.first),
        'Category ID already exists.',
      );
      repository.failSave = true;
      final original = catalog.books.first;
      expect(
        await catalog.saveBook(
          original.withStatus('published'),
          original: original,
        ),
        'Save failed. Retry.',
      );
      expect(catalog.books.first.status, 'draft');
      repository.failSave = false;
      expect(
        await catalog.saveBook(
          original.withStatus('published'),
          original: original,
        ),
        isNull,
      );
      expect(catalog.books.first.status, 'published');
      final category = catalog.categories.last;
      expect(
        await catalog.saveCategory(
          Category(
            id: category.id,
            name: category.name,
            description: category.description,
            isActive: true,
            createdAt: category.createdAt,
          ),
          original: category,
        ),
        isNull,
      );
      expect(catalog.categories.last.isActive, isTrue);
    },
  );
}
