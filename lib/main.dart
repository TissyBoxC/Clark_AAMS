import 'dart:async';

import 'package:flutter/material.dart';

import 'resources/app_strings.dart';
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
        title: AppStrings.appName,
        // 与网页端同一套粉白体系：最深只到深梅灰，不用纯黑；
        // 主色用饱和糖果粉，因为浅粉 #F7A8BF 配白字对比度只有 1.86:1，看不清。
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffc93c7d),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xffc93c7d),
            onPrimary: Colors.white,
            surface: const Color(0xffffffff),
            onSurface: const Color(0xff4a2e3b),
            secondary: const Color(0xffb23a68),
            outline: const Color(0xfff0bdcb),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfffff9fa),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xfffff9fa),
            foregroundColor: Color(0xff4a2e3b),
            centerTitle: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xfff7d9e2)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffc93c7d),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffb23a68),
              side: const BorderSide(color: Color(0xfff0bdcb)),
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffc93c7d),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xffc93c7d),
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xfff0bdcb)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xfff0bdcb)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffc93c7d), width: 2),
            ),
          ),
          dividerTheme: const DividerThemeData(color: Color(0xfff7d9e2)),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xff4a2e3b),
            contentTextStyle: TextStyle(color: Colors.white),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: store.settings.schoolId.isEmpty || store.settings.isFirstLaunch
            ? const WelcomePage()
            : const HomePage(),
      ),
    );
  }
}
