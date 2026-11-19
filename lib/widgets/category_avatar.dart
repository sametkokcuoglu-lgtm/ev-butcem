import 'package:flutter/material.dart';

/// Kategori emojisini renkli, yuvarlatılmış bir zeminde gösterir.
class CategoryAvatar extends StatelessWidget {
  final String icon;
  final int? colorValue;
  final double size;

  const CategoryAvatar({
    super.key,
    required this.icon,
    this.colorValue,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue ?? 0xFF64748B);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(icon, style: TextStyle(fontSize: size * 0.46, height: 1.1)),
    );
  }
}
