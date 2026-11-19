import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Yumuşak gölgeli, yuvarlatılmış yüzey.
///
/// İçerideki [ListTile] mürekkebini görebilmesi için asıl zemin bir [Material] üzerindedir.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.radius = AppSpacing.radiusLg,
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final finance = FinanceColors.of(context);
    final background = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border?.top ?? BorderSide(color: finance.line),
    );
    final content = Padding(padding: padding, child: child);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  customBorder: shape,
                  child: content,
                ),
        ),
      ),
    );
  }
}
