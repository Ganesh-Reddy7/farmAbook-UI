import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../theme/app_colors.dart';

class InterestHistoryShimmer extends StatelessWidget {
  const InterestHistoryShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return _shimmerCard(colors);
      },
    );
  }

  Widget _shimmerCard(AppColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.divider.withOpacity(0.3),
      highlightColor: colors.divider.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bar(width: 70, height: 20),
                _bar(width: 100, height: 14),
              ],
            ),

            const SizedBox(height: 12),
            _bar(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _bar(width: double.infinity, height: 14),

            const Divider(height: 20),
            _bar(width: 120, height: 16),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
