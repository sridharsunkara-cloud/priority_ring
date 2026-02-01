import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 600px is the standard 2026 breakpoint for Mobile vs Tablet/Web
        if (constraints.maxWidth < 600) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
