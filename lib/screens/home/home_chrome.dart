import 'package:flutter/material.dart';

import '../../resources/app_strings.dart';
import 'home_style.dart';

/// 首页底部导航栏（带插画图标）。
class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_NavArtSpec>[
    _NavArtSpec(
      label: AppStrings.homeTab,
      idleAsset: 'assets/nav/nav_home_idle.png',
      activeAsset: 'assets/nav/nav_home_active.png',
    ),
    _NavArtSpec(
      label: AppStrings.scheduleTab,
      idleAsset: 'assets/nav/nav_schedule_idle.png',
      activeAsset: 'assets/nav/nav_schedule_active.png',
    ),
    _NavArtSpec(
      label: AppStrings.mineTab,
      idleAsset: 'assets/nav/nav_mine_idle.png',
      activeAsset: 'assets/nav/nav_mine_active.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: const [
              BoxShadow(
                color: Color(0x160b0550),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _NavArtButton(
                      spec: _items[index],
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavArtSpec {
  const _NavArtSpec({
    required this.label,
    required this.idleAsset,
    required this.activeAsset,
  });

  final String label;
  final String idleAsset;
  final String activeAsset;
}

class _NavArtButton extends StatelessWidget {
  const _NavArtButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavArtSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = selected ? spec.activeAsset : spec.idleAsset;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.fromLTRB(5, selected ? 4 : 7, 5, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? const Color(0xfffff2f5)
                : Colors.white.withAlpha(0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 28,
                child: Center(
                  child: AnimatedScale(
                    scale: selected ? 1.04 : 0.9,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0.58,
                      duration: const Duration(milliseconds: 220),
                      child: Image.asset(
                        image,
                        height: 24,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: selected ? homeLavender : homeMuted.withAlpha(180),
                  fontSize: selected ? 10 : 9,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  height: 1,
                ),
                child: Text(spec.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
