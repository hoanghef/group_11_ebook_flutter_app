import 'package:flutter/widgets.dart';

import 'admin_catalog_controller.dart';

class AdminCatalogScope extends InheritedNotifier<AdminCatalogController> {
  const AdminCatalogScope({
    super.key,
    required AdminCatalogController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminCatalogController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminCatalogScope>();
    assert(scope != null, 'AdminCatalogScope is missing');
    return scope!.notifier!;
  }
}
