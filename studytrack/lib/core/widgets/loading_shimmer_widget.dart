import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmerWidget extends StatelessWidget {
  const LoadingShimmerWidget.profile({super.key}) : _itemCount = 5;

  final int _itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) => _ShimmerCard(height: index == 0 ? 110 : 72),
      separatorBuilder: (_, itemIndex) => const SizedBox(height: 12),
      itemCount: _itemCount,
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A2E),
      highlightColor: const Color(0xFF252544),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
