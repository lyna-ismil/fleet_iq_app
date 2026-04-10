import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/theme.dart';

/// Skeleton shimmer placeholder for a card layout.
class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    Key? key,
    this.height = 120,
    this.width,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceBorder,
      highlightColor: AppTheme.surfaceGray,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusXl),
        ),
      ),
    );
  }
}

/// Skeleton list for loading states — shows multiple shimmer cards.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;

  const SkeletonList({
    Key? key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? EdgeInsets.all(24),
      itemCount: itemCount,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (ctx, i) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonCard(height: itemHeight),
      ),
    );
  }
}

/// Skeleton for profile-style layouts
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceBorder,
      highlightColor: AppTheme.surfaceGray,
      child: Column(
        children: [
          SizedBox(height: 32),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 24),
          Container(height: 20, width: 160, color: AppTheme.surfaceWhite),
          SizedBox(height: 12),
          Container(height: 14, width: 200, color: AppTheme.surfaceWhite),
          SizedBox(height: 32),
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
          ),
        ],
      ),
    );
  }
}
