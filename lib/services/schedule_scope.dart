import 'package:flutter/widgets.dart';

import 'class_schedule_store.dart';

class ScheduleScope extends InheritedNotifier<ClassScheduleStore> {
  const ScheduleScope({
    super.key,
    required ClassScheduleStore store,
    required super.child,
  }) : super(notifier: store);

  static ClassScheduleStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ScheduleScope>();
    assert(scope != null, 'ScheduleScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
