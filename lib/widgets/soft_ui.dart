import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';

/// 页面骨架：宽度自适应。
///
/// 手机上是单列；窗口变宽时内容居中、最大宽度受限，
/// 让桌面端不会出现"一行文字横跨 2000 像素"的排版。
/// 这就是 App 与桌面端共用同一套页面的关键：不写两份 UI。
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.child,
    this.description,
    this.actions = const [],
    this.maxWidth = AppMetrics.content,
    this.scrollable = true,
    this.padding,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> actions;
  final Widget child;
  final double maxWidth;
  final bool scrollable;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final insets =
        padding ??
        EdgeInsets.fromLTRB(
          AppMetrics.pagePadding(width),
          AppMetrics.sp5,
          AppMetrics.pagePadding(width),
          AppMetrics.sp6,
        );

    final header = SectionHeader(
      title: title,
      description: description,
      actions: actions,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppMetrics.sp5),
        child,
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: scrollable
            ? SingleChildScrollView(padding: insets, child: body)
            : Padding(padding: insets, child: body),
      ),
    );
  }
}

/// 页面标题区：标题 + 一句说明 + 可选操作。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.description,
    this.actions = const [],
    this.compact = false,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? AppMetrics.h3 : AppMetrics.h1,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppColors.ink900,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppMetrics.sp2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              description!,
              style: const TextStyle(
                fontSize: AppMetrics.small,
                height: 1.75,
                color: AppColors.ink500,
              ),
            ),
          ),
        ],
      ],
    );

    if (actions.isEmpty) {
      return text;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: AppMetrics.sp3),
              Wrap(
                spacing: AppMetrics.sp2,
                runSpacing: AppMetrics.sp2,
                children: actions,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: AppMetrics.sp4),
            Wrap(
              spacing: AppMetrics.sp2,
              runSpacing: AppMetrics.sp2,
              children: actions,
            ),
          ],
        );
      },
    );
  }
}

/// 白色圆角卡片：柔和阴影、22 圆角，与学生侧网页端一致。
class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppMetrics.sp5),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.sunken = false,
    this.tone,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final bool sunken;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppMetrics.rXl);
    final background =
        tone ?? (sunken ? AppColors.surfaceSunken : AppColors.surface);

    return Padding(
      padding: margin,
      child: Material(
        color: background,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: sunken ? null : AppColors.shadowMd,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// 小节标题：标题 + 可选右侧动作。
class CardHeading extends StatelessWidget {
  const CardHeading({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: AppMetrics.small,
                    height: 1.7,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppMetrics.sp3), action!],
      ],
    );
  }
}

/// 主按钮（动词 + 对象）。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.inkInverse,
                ),
              ),
              const SizedBox(width: AppMetrics.sp2),
              Text(label),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppMetrics.sp2),
              ],
              Text(label),
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 次要按钮：白底、细描边。
class QuietButton extends StatelessWidget {
  const QuietButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppMetrics.sp2),
          ],
          Text(label),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 危险操作按钮：删除、清空。用浅红底而不是纯红，避免过度刺眼。
class DangerButton extends StatelessWidget {
  const DangerButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.danger100,
        foregroundColor: AppColors.danger600,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppMetrics.sp2),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// 小组件徽标：品牌浅底 + 深字，用于状态与分类。
class SoftTag extends StatelessWidget {
  const SoftTag({
    required this.label,
    this.tone = SoftTagTone.brand,
    super.key,
  });

  final String label;
  final SoftTagTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      SoftTagTone.brand => (AppColors.brand100, AppColors.brand700),
      SoftTagTone.mint => (AppColors.mint100, AppColors.mint600),
      SoftTagTone.amber => (AppColors.amber100, AppColors.amber600),
      SoftTagTone.danger => (AppColors.danger100, AppColors.danger600),
      SoftTagTone.neutral => (AppColors.surfaceSunken, AppColors.ink600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppMetrics.rPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppMetrics.tiny,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

enum SoftTagTone { brand, mint, amber, danger, neutral }

/// 空状态：说明为什么空、下一步做什么。
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      sunken: true,
      padding: const EdgeInsets.all(AppMetrics.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: AppMetrics.sp2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: AppMetrics.small,
                height: 1.8,
                color: AppColors.ink600,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppMetrics.sp4),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 读取中：短文案 + 细转动环，不写「努力加载中」。
class LoadingPanel extends StatelessWidget {
  const LoadingPanel({this.text = AppStrings.loading, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.sp6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppMetrics.sp3),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppMetrics.small,
              color: AppColors.ink500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 提示条：说明发生了什么、能做什么。可带操作。
class NoticeBar extends StatelessWidget {
  const NoticeBar({
    required this.message,
    this.tone = NoticeTone.info,
    this.action,
    super.key,
  });

  final String message;
  final NoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      NoticeTone.info => (
        AppColors.brand050,
        AppColors.ink700,
        Icons.info_outline,
      ),
      NoticeTone.warn => (
        AppColors.amber100,
        AppColors.ink700,
        Icons.error_outline,
      ),
      NoticeTone.error => (
        AppColors.danger100,
        AppColors.ink700,
        Icons.report_gmailerrorred_outlined,
      ),
      NoticeTone.success => (
        AppColors.mint100,
        AppColors.ink700,
        Icons.check_circle_outline,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.sp4,
        vertical: AppMetrics.sp3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppMetrics.rLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppMetrics.sp3),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppMetrics.small,
                height: 1.75,
                color: foreground,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppMetrics.sp3),
            action!,
          ],
        ],
      ),
    );
  }
}

enum NoticeTone { info, warn, error, success }

/// 键值行：左侧名称、右侧内容。
class KvRow extends StatelessWidget {
  const KvRow({
    required this.label,
    required this.value,
    this.trailing,
    this.showDivider = true,
    super.key,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.sp3),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppMetrics.small,
                color: AppColors.ink500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppMetrics.small,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 圆形头像占位：用名字首字，不依赖网络图片。
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({required this.name, this.size = 44, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '珂' : name.trim().substring(0, 1);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand100,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.brand700,
        ),
      ),
    );
  }
}

/// 带标题的浅色分组容器，用于设置项。
class SoftGroup extends StatelessWidget {
  const SoftGroup({
    required this.children,
    this.title,
    this.description,
    super.key,
  });

  final String? title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppMetrics.sp3),
            child: CardHeading(title: title!, subtitle: description),
          ),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const SizedBox(height: AppMetrics.sp3),
        ],
      ],
    );
  }
}
