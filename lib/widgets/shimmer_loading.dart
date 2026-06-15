import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      builder: (context, color) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 16, width: 150, color: color),
                    Container(height: 16, width: 50, color: color),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 12, width: double.infinity, color: color),
                const SizedBox(height: 8),
                Container(height: 12, width: 200, color: color),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 32, width: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
                    Container(height: 32, width: 100, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
