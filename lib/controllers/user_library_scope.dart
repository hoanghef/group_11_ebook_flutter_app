import 'package:flutter/widgets.dart';

import 'user_library_controller.dart';

class UserLibraryScope extends InheritedNotifier<UserLibraryController> {
  const UserLibraryScope({
    super.key,
    required UserLibraryController controller,
    required super.child,
  }) : super(notifier: controller);

  static UserLibraryController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<UserLibraryScope>();
    assert(scope != null, 'UserLibraryScope is missing');
    return scope!.notifier!;
  }
}
