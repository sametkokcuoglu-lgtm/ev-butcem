import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Geniş ekranda içeriği ortalar; telefonda tam genişlik kalır.
class ContentFrame extends StatelessWidget {
  final Widget child;

  const ContentFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxWidth),
        child: child,
      ),
    );
  }
}
