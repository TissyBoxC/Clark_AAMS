import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_metrics.dart';

/// 全站主题。
///
/// 只在这里定义一次颜色与字体，页面里不再出现十六进制色值。
/// 字体走系统字体（中文用平台自带的思源/苹方/微软雅黑），
/// 不打包字体文件：App 体积比"字号完全一致"更重要。
class AppTheme {
  const AppTheme._();

  static const String _fontFamily = 'PingFang SC';

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.brand600,
      onPrimary: AppColors.inkInverse,
      primaryContainer: AppColors.brand100,
      onPrimaryContainer: AppColors.brand700,
      secondary: AppColors.brand700,
      onSecondary: AppColors.inkInverse,
      surface: AppColors.surface,
      onSurface: AppColors.ink900,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.canvasDeep,
      onSurfaceVariant: AppColors.ink600,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.line,
      error: AppColors.danger600,
      onError: AppColors.inkInverse,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.rXl),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: AppColors.inkInverse,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(
            fontSize: AppMetrics.body,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.rMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink700,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: AppColors.lineStrong),
          textStyle: const TextStyle(
            fontSize: AppMetrics.body,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.rMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand700,
          minimumSize: const Size(0, 40),
          textStyle: const TextStyle(fontSize: AppMetrics.small),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand600,
        foregroundColor: AppColors.inkInverse,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: AppMetrics.h3,
          fontWeight: FontWeight.w600,
          color: AppColors.ink900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.ink400),
        labelStyle: const TextStyle(color: AppColors.ink500),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(AppColors.brand500, width: 1.5),
        errorBorder: _inputBorder(AppColors.danger600),
        focusedErrorBorder: _inputBorder(AppColors.danger600, width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink900,
        contentTextStyle: const TextStyle(color: AppColors.inkInverse),
        actionTextColor: AppColors.brand200,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.rMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.rXl),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: AppMetrics.h3,
          fontWeight: FontWeight.w600,
          color: AppColors.ink900,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: AppMetrics.body,
          height: 1.7,
          color: AppColors.ink600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppMetrics.r2xl),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.ink500,
        textColor: AppColors.ink900,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand600,
        linearTrackColor: AppColors.surfaceSunken,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.inkInverse
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand600
              : AppColors.canvasDeep,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppMetrics.rMd),
      borderSide: color == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.hero,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.6,
            color: AppColors.ink900,
          ),
          headlineLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.h1,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppColors.ink900,
          ),
          headlineMedium: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.h2,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: AppColors.ink900,
          ),
          titleLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.h3,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: AppColors.ink900,
          ),
          titleMedium: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.body,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: AppColors.ink900,
          ),
          bodyLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.body,
            height: 1.7,
            color: AppColors.ink600,
          ),
          bodyMedium: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.small,
            height: 1.7,
            color: AppColors.ink600,
          ),
          bodySmall: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.tiny,
            height: 1.6,
            color: AppColors.ink500,
          ),
          labelLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: AppMetrics.body,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(bodyColor: AppColors.ink600, displayColor: AppColors.ink900);
  }
}

/// 管理台主题：深灰三层。只给管理台页面套一层 Theme 用。
ThemeData adminTheme() {
  final base = AppTheme.light();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.admScreen,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.admAccent,
      onPrimary: Colors.white,
      surface: AppColors.admPanel,
      onSurface: AppColors.admText,
      onSurfaceVariant: AppColors.admText2,
      outline: AppColors.admLine,
      error: AppColors.admBad,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.admPanel,
      foregroundColor: AppColors.admText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.admLineSoft,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: Color(0x47FFFFFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.admLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.admLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x29FFFFFF)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.admText2,
      displayColor: AppColors.admText,
    ),
  );
}
