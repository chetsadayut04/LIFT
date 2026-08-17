import 'package:flutter/material.dart';

/// Signature "plate stack" bar — a row of thin vertical bars lit up
/// in the accent color proportional to [ratio], like plates on a bar.
class PlateStack extends StatelessWidget {
  final double ratio; // 0..1
  final int segments;
  const PlateStack({super.key, required this.ratio, this.segments = 6});

  @override
  Widget build(BuildContext context) {
    final lit = (ratio * segments).round().clamp(0, segments);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(segments, (i) {
        final on = i < lit;
        return Container(
          width: 5,
          height: on ? 16 : 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: on
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF718E7E),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
