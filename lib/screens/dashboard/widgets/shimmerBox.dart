import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';

Widget shimmerBox({
  required BuildContext context,
  required double height,
  double width = double.infinity,
  double radius = 12,
  EdgeInsets margin = EdgeInsets.zero,
}) {
  final isDark = Theme.of(context).brightness != Brightness.dark;
  final colors = AppColors.fromTheme(isDark);

  final baseColor = colors.divider.withOpacity(isDark ? 0.75 : 0.85);
  final highlightColor = colors.divider.withOpacity(isDark ? 0.9 : 0.95);
  final boxColor = colors.divider.withOpacity(isDark ? 0.55 : 0.65);

  return Container(
    margin: margin,
    child: Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
  );
}
