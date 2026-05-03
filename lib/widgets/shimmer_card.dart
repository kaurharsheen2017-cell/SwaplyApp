import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ShimmerCard  — loading skeleton for PostCard
//  Uses Theme.of(context) brightness so it renders correctly in dark mode.
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF252540)
        : AppColors.shimmerBase;
    final highlightColor = isDark
        ? const Color(0xFF2D2D4E)
        : AppColors.shimmerHigh;
    final cardBg = isDark
        ? AppColors.darkCardBg
        : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.divider;
    final blockColor = isDark
        ? const Color(0xFF2D2D4E)
        : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                _circle(38, blockColor),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(130, 12, blockColor),
                    const SizedBox(height: 5),
                    _box(80, 10, blockColor),
                  ],
                ),
                const Spacer(),
                _circle(22, blockColor),
              ],
            ),
            const SizedBox(height: 14),
            // ── Title lines ────────────────────────────────────────────────
            _box(double.infinity, 15, blockColor),
            const SizedBox(height: 6),
            _box(220, 13, blockColor),
            const SizedBox(height: 4),
            _box(160, 13, blockColor),
            const SizedBox(height: 14),
            // ── Exchange strip ─────────────────────────────────────────────
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double width, double height, Color color) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}