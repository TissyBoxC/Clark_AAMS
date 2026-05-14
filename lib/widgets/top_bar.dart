import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.trailing, this.leading});

  final String title;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 53,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: leading ?? const SizedBox(width: 56),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xff172033),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: trailing ?? const SizedBox(width: 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
