import 'package:flutter/widgets.dart';

import 'admin_access_controller.dart';

class AdminAccessScope extends InheritedNotifier<AdminAccessController> {
  const AdminAccessScope({
    super.key,
    required AdminAccessController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminAccessController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminAccessScope>();
    assert(scope != null, 'AdminAccessScope is missing');
    return scope!.notifier!;
  }
}
