import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'screens/welcome_page.dart';
import 'services/auth_session.dart';
import 'services/class_schedule_store.dart';
import 'services/schedule_scope.dart';
import 'widget/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ClassScheduleStore.load();
  unawaited(WidgetService.updateWidget());
  unawaited(AuthSession.instance.initialize());
  runApp(ClassScheduleApp(store: store));
}

class ClassScheduleApp extends StatelessWidget {
  const ClassScheduleApp({super.key, required this.store});

  final ClassScheduleStore store;

  @override
  Widget build(BuildContext context) {
    return ScheduleScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '珂拉课程表',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff7c6cff),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfffffbff),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xfffffbff),
            foregroundColor: Color(0xff2b2545),
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff7c6cff),
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xff7c6cff),
            foregroundColor: Colors.white,
          ),
        ),
        home: store.settings.schoolId.isEmpty || store.settings.isFirstLaunch
            ? const WelcomePage()
            : const HomePage(),
      ),
    );
  }
}
