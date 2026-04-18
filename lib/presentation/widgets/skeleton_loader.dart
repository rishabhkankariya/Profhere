import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

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
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? height;
  const SkeletonCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 120,
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceElevated,
        highlightColor: AppColors.surface,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              if (height == null || height! > 80) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;
  
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  
  const SkeletonText({
    super.key,
    required this.width,
    this.height = 16,
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

class SkeletonAvatar extends StatelessWidget {
  final double size;
  
  const SkeletonAvatar({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}