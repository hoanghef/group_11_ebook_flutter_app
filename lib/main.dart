import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/auth_scope.dart';
import 'controllers/admin_access_controller.dart';
import 'controllers/admin_access_scope.dart';
import 'controllers/admin_catalog_controller.dart';
import 'controllers/admin_catalog_scope.dart';
import 'controllers/catalog_controller.dart';
import 'controllers/catalog_scope.dart';
import 'controllers/user_library_controller.dart';
import 'controllers/user_library_scope.dart';
import 'repositories/auth_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_catalog_repository.dart';
import 'repositories/sample_catalog_repository.dart';
import 'repositories/unavailable_auth_repository.dart';
import 'repositories/firestore_user_library_repository.dart';
import 'repositories/unavailable_user_library_repository.dart';
import 'repositories/user_library_repository.dart';
import 'repositories/admin_access_repository.dart';
import 'repositories/admin_catalog_repository.dart';
import 'repositories/firebase_admin_access_repository.dart';
import 'repositories/firestore_admin_catalog_repository.dart';
import 'repositories/unavailable_admin_access_repository.dart';
import 'repositories/unavailable_admin_catalog_repository.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      EbookApp(
        authRepository: FirebaseAuthRepository(firebase.FirebaseAuth.instance),
        catalogRepository: FirestoreCatalogRepository(
          FirebaseFirestore.instance,
        ),
        userLibraryRepository: FirestoreUserLibraryRepository(
          FirebaseFirestore.instance,
        ),
        adminAccessRepository: FirebaseAdminAccessRepository(
          firebase.FirebaseAuth.instance,
        ),
        adminCatalogRepository: FirestoreAdminCatalogRepository(
          FirebaseFirestore.instance,
        ),
      ),
    );
  } catch (_) {
    runApp(
      EbookApp(
        authRepository: UnavailableAuthRepository(),
        catalogRepository: SampleCatalogRepository(),
        userLibraryRepository: UnavailableUserLibraryRepository(),
        adminAccessRepository: UnavailableAdminAccessRepository(),
        adminCatalogRepository: UnavailableAdminCatalogRepository(),
      ),
    );
  }
}

class EbookApp extends StatefulWidget {
  const EbookApp({
    super.key,
    required this.authRepository,
    this.catalogRepository,
    this.userLibraryRepository,
    this.adminAccessRepository,
    this.adminCatalogRepository,
  });

  final AuthRepository authRepository;
  final CatalogRepository? catalogRepository;
  final UserLibraryRepository? userLibraryRepository;
  final AdminAccessRepository? adminAccessRepository;
  final AdminCatalogRepository? adminCatalogRepository;

  @override
  State<EbookApp> createState() => _EbookAppState();
}

class _EbookAppState extends State<EbookApp> {
  late final CatalogController _catalog;
  late final AuthController _auth;
  late final UserLibraryController _library;
  late final AdminAccessController _adminAccess;
  late final AdminCatalogController _adminCatalog;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogController(
      widget.catalogRepository ?? SampleCatalogRepository(),
    );
    _auth = AuthController(widget.authRepository);
    _library = UserLibraryController(
      _auth,
      widget.userLibraryRepository ?? UnavailableUserLibraryRepository(),
    );
    _adminAccess = AdminAccessController(
      _auth,
      widget.adminAccessRepository ?? UnavailableAdminAccessRepository(),
    );
    _adminCatalog = AdminCatalogController(
      _adminAccess,
      widget.adminCatalogRepository ?? UnavailableAdminCatalogRepository(),
    );
    _catalog.load();
  }

  @override
  void dispose() {
    _catalog.dispose();
    _library.dispose();
    _adminCatalog.dispose();
    _adminAccess.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: AdminAccessScope(
        controller: _adminAccess,
        child: AdminCatalogScope(
          controller: _adminCatalog,
          child: UserLibraryScope(
            controller: _library,
            child: CatalogScope(
              controller: _catalog,
              child: AnimatedBuilder(
                animation: _auth,
                builder: (context, _) => MaterialApp(
                  key: ValueKey(_auth.status),
                  title: 'Flutter Ebook App',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primarySwatch: Colors.blue,
                    useMaterial3: true,
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                  ),
                  home: const AuthGate(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
