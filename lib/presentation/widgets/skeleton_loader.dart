import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

// ─── Shimmer base ─────────────────────────────────────────────────────────────
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

// ─── Internal shimmer box using flutter_animate ───────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: borderRadius,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.surface,
          angle: 0.15,
        );
  }
}

// ─── SkeletonText ─────────────────────────────────────────────────────────────
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

// ─── SkeletonAvatar ───────────────────────────────────────────────────────────
class SkeletonAvatar extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;

  const SkeletonAvatar({
    super.key,
    this.size = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(size / 3),
    );
  }
}

// ─── Faculty Card Skeleton ────────────────────────────────────────────────────
class SkeletonCard extends StatelessWidget {
  final double? height;
  final int index;

  const SkeletonCard({super.key, this.height, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 88,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          _ShimmerBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 14),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: 120,
                  height: 11,
                  borderRadius: BorderRadius.circular(5.5),
                ),
                if (height != null && height! > 80) ...[
                  const SizedBox(height: 8),
                  _ShimmerBox(
                    width: 80,
                    height: 11,
                    borderRadius: BorderRadius.circular(5.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge
          _ShimmerBox(
            width: 64,
            height: 24,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: const Duration(milliseconds: 400), curve: Curves.easeOut)
        .slideY(begin: 0.15, end: 0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }
}

// ─── Staggered skeleton list ──────────────────────────────────────────────────
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, i) => SkeletonCard(height: itemHeight, index: i),
    );
  }
}

// ─── Profile skeleton ─────────────────────────────────────────────────────────
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _ShimmerBox(width: 64, height: 64, borderRadius: BorderRadius.circular(20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 140, height: 16, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(6)),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 120, height: 12, borderRadius: BorderRadius.circular(6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ShimmerBox(width: 28, height: 28, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: 32, height: 18, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 4),
                    _ShimmerBox(width: 48, height: 10, borderRadius: BorderRadius.circular(5)),
                  ],
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),
          // Settings skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _ShimmerBox(width: 36, height: 36, borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBox(width: 100, height: 13, borderRadius: BorderRadius.circular(6)),
                          const SizedBox(height: 4),
                          _ShimmerBox(width: 160, height: 10, borderRadius: BorderRadius.circular(5)),
                        ],
                      ),
                    ),
                    _ShimmerBox(width: 24, height: 14, borderRadius: BorderRadius.circular(7)),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }
}

// ─── Dashboard hero skeleton ──────────────────────────────────────────────────
class SkeletonDashboardHero extends StatelessWidget {
  const SkeletonDashboardHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _ShimmerBox(width: 56, height: 56, borderRadius: BorderRadius.circular(16)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 80, height: 11, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 6),
                _ShimmerBox(width: 140, height: 20, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 4),
                _ShimmerBox(width: 100, height: 11, borderRadius: BorderRadius.circular(5)),
              ],
            ),
          ),
          _ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: -0.1, end: 0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }
}
