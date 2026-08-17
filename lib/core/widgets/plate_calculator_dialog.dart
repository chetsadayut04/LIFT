import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlateStyle {
  final Color color;
  final double height;
  final double width;
  const PlateStyle(this.color, this.height, this.width);
}

final Map<double, PlateStyle> kgStyles = {
  25.0: const PlateStyle(Color(0xFFEF4444), 110.0, 18.0),
  20.0: const PlateStyle(Color(0xFF3B82F6), 100.0, 16.0),
  15.0: const PlateStyle(Color(0xFFFBBF24), 90.0, 14.0),
  10.0: const PlateStyle(Color(0xFF10B981), 80.0, 12.0),
  5.0: const PlateStyle(Color(0xFFE5E7EB), 65.0, 10.0),
  2.5: const PlateStyle(Color(0xFF1F2937), 50.0, 8.0),
  1.25: const PlateStyle(Color(0xFF9CA3AF), 40.0, 6.0),
};

final Map<double, PlateStyle> lbsStyles = {
  45.0: const PlateStyle(Color(0xFF3B82F6), 105.0, 18.0),
  35.0: const PlateStyle(Color(0xFFFBBF24), 95.0, 16.0),
  25.0: const PlateStyle(Color(0xFF10B981), 85.0, 14.0),
  10.0: const PlateStyle(Color(0xFF1F2937), 70.0, 11.0),
  5.0: const PlateStyle(Color(0xFF9CA3AF), 55.0, 9.0),
  2.5: const PlateStyle(Color(0xFFE5E7EB), 45.0, 7.0),
};

Future<double?> showPlateCalculator({
  required BuildContext context,
  required double initialWeight,
  required bool isLbs,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlateCalculatorSheet(initialWeight: initialWeight, isLbs: isLbs),
  );
}

class _PlateCalculatorSheet extends StatefulWidget {
  final double initialWeight;
  final bool isLbs;
  const _PlateCalculatorSheet({required this.initialWeight, required this.isLbs});

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  late TextEditingController _weightCtrl;
  late double _barWeight;
  late List<double> _availablePlates;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.initialWeight > 0 ? widget.initialWeight.toStringAsFixed(1) : '',
    );
    _barWeight = widget.isLbs ? 45.0 : 20.0;
    _availablePlates = widget.isLbs
        ? lbsStyles.keys.toList()
        : kgStyles.keys.toList();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  List<double> _calculatePlates(double target) {
    if (target <= _barWeight) return [];
    double remaining = (target - _barWeight) / 2;
    List<double> result = [];

    // Ensure sorted descending
    final sorted = List<double>.from(_availablePlates)..sort((a, b) => b.compareTo(a));

    for (final plate in sorted) {
      while (remaining >= plate - 0.01) { // 0.01 threshold for precision
        result.add(plate);
        remaining -= plate;
      }
    }
    return result;
  }

  void _stepWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0;
    final next = (current + delta).clamp(0.0, 999.0);
    setState(() {
      _weightCtrl.text = next.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final isDark = theme.brightness == Brightness.dark;

    final targetWeight = double.tryParse(_weightCtrl.text) ?? 0.0;
    final plates = _calculatePlates(targetWeight);

    final unit = widget.isLbs ? 'lbs' : 'kg';

    return Container(
      margin: EdgeInsets.only(top: 60, bottom: bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ตัวช่วยคำนวณแผ่นน้ำหนัก',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Target weight input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _stepWeight(widget.isLbs ? -5 : -2.5),
                icon: const Icon(Icons.remove_circle_outline, size: 28),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    suffixText: ' $unit',
                    suffixStyle: TextStyle(fontSize: 14, color: textMuted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _stepWeight(widget.isLbs ? 5 : 2.5),
                icon: const Icon(Icons.add_circle_outline, size: 28),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar weight selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'น้ำหนักบาร์: ',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: (widget.isLbs ? [45.0, 35.0, 25.0] : [20.0, 15.0, 10.0]).map((w) {
                  final selected = _barWeight == w;
                  return ChoiceChip(
                    label: Text('${w.toStringAsFixed(0)} $unit'),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setState(() => _barWeight = w);
                    },
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Visual Barbell representation
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111411) : const Color(0xFFEDF1EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline, width: 0.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Barbell shaft
                Container(
                  width: double.infinity,
                  height: 8,
                  color: const Color(0xFF9CA3AF),
                ),
                // Barbell inner sleeve collar
                Positioned(
                  left: 60,
                  child: Container(
                    width: 14,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Plates on the barbell (from inside out)
                Positioned(
                  left: 76,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: plates.map((p) {
                      final style = widget.isLbs
                          ? lbsStyles[p] ?? const PlateStyle(Colors.grey, 60, 10)
                          : kgStyles[p] ?? const PlateStyle(Colors.grey, 60, 10);
                      final textColor = style.color == const Color(0xFFE5E7EB) ? Colors.black : Colors.white;
                      return Container(
                        width: style.width,
                        height: style.height,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: style.color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.black26,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            p.toStringAsFixed(p % 1 == 0 ? 0 : 2),
                            style: GoogleFonts.spaceGrotesk(
                              color: textColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Left offset indicator or context label
                Positioned(
                  left: 12,
                  child: Text(
                    'ข้างขวา',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Text summary of plates
          if (plates.isNotEmpty) ...[
            Text(
              'แผ่นเหล็กต่อหนึ่งข้าง:',
              style: TextStyle(fontSize: 12, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _buildPlateSummary(plates, unit),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              targetWeight <= _barWeight
                  ? 'กรอกน้ำหนักมากกว่าน้ำหนักบาร์เพื่อคำนวณ'
                  : 'ไม่ต้องใส่แผ่นน้ำหนักเพิ่มเติม',
              style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: targetWeight > 0
                      ? () => Navigator.pop(context, targetWeight)
                      : null,
                  child: const Text('นำไปใช้'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildPlateSummary(List<double> plates, String unit) {
    final counts = <double, int>{};
    for (final p in plates) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final sortedKeys = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys
        .map((k) => '${k.toStringAsFixed(k % 1 == 0 ? 0 : 2)} $unit × ${counts[k]} แผ่น')
        .join(', ');
  }
}
