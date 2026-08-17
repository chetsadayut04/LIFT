import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/widgets/plate_calculator_dialog.dart';

// ลบสีค่าคงที่ฮาร์ดโค้ดออกเพื่อให้ใช้สีระบบตาม Theme ได้อย่างสมบูรณ์แบบ

class AddSetForm extends ConsumerStatefulWidget {
  final void Function(double weight, int reps, bool isWarmup) onAdd;
  final VoidCallback? onAfterAdd;
  final List<({double weight, int reps})> previousSets;
  final List<({double weight, int reps})> lastSessionSets;
  final int repMin;
  final int repMax;

  const AddSetForm({
    super.key,
    required this.onAdd,
    this.onAfterAdd,
    this.previousSets = const [],
    this.lastSessionSets = const [],
    this.repMin = kRepMin,
    this.repMax = kRepMax,
  });

  @override
  ConsumerState<AddSetForm> createState() => _AddSetFormState();
}

class _AddSetFormState extends ConsumerState<AddSetForm> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  bool _isWarmup = false;

  @override
  void initState() {
    super.initState();
    _syncFields();
  }

  @override
  void didUpdateWidget(AddSetForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previousSets.length < widget.previousSets.length) {
      _syncFields();
    }
  }

  // Fills weight+reps from the matching last-session set index.
  // Falls back to keeping weight + clearing reps once past last-session set count.
  void _syncFields() {
    final isLbs = ref.read(isLbsProvider);
    final nextIdx = widget.previousSets.length;
    if (nextIdx < widget.lastSessionSets.length) {
      final src = widget.lastSessionSets[nextIdx];
      _weightCtrl.text = fmtNum(isLbs ? src.weight * kgToLbs : src.weight);
      _repsCtrl.text = src.reps.toString();
    } else if (widget.previousSets.isNotEmpty) {
      final last = widget.previousSets.last;
      _weightCtrl.text = fmtNum(isLbs ? last.weight * kgToLbs : last.weight);
      _repsCtrl.clear();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _stepField(TextEditingController ctrl, double delta, {bool isInt = false}) {
    final current = double.tryParse(ctrl.text) ?? 0;
    final next = (current + delta).clamp(0.0, double.maxFinite);
    setState(() {
      ctrl.text = isInt ? next.toInt().toString() : fmtNum(next);
    });
  }

  void _submit(bool isLbs) {
    final rawWeight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);
    if (rawWeight == null || reps == null || rawWeight <= 0 || reps <= 0) return;
    final weightKg = inputToKg(rawWeight, isLbs);
    widget.onAdd(weightKg, reps, _isWarmup);
    if (!_isWarmup) widget.onAfterAdd?.call();
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final border = theme.colorScheme.outline;
    final surfaceHi = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceHi,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: accent),
      ),
    );
  }

  Widget _microStepBtn(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final border = theme.colorScheme.outline;
    final surfaceHi = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: surfaceHi,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    final weightStep = isLbs ? 5.0 : 2.5;

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final textSec = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final border = theme.colorScheme.outline;
    final surfaceHi = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Previous session hint ──────────────────────────────
        if (widget.lastSessionSets.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'ครั้งก่อน  ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.lastSessionSets.asMap().entries.map((e) {
                      final s = e.value;
                      final w = isLbs ? s.weight * kgToLbs : s.weight;
                      final wStr = fmtNum(w);
                      final isCurrent = e.key == widget.previousSets.length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${e.key + 1}: $wStr $unit × ${s.reps}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrent ? accent : textSec,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _ProgressionHint(
            lastSessionSets: widget.lastSessionSets,
            previousSets: widget.previousSets,
            isLbs: isLbs,
            repMin: widget.repMin,
            repMax: widget.repMax,
          ),
          const SizedBox(height: 6),
        ],

        // ── Warmup toggle & Plate Calc ─────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isWarmup = !_isWarmup),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isWarmup ? const Color(0xFFFF9F1C).withValues(alpha: 0.18) : surfaceHi,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isWarmup ? const Color(0xFFFF9F1C) : border,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Warm-up',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isWarmup ? const Color(0xFFFF9F1C) : textSec,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final currentWeight = double.tryParse(_weightCtrl.text) ?? 0.0;
                final result = await showPlateCalculator(
                  context: context,
                  initialWeight: currentWeight,
                  isLbs: isLbs,
                );
                if (result != null && mounted) {
                  setState(() {
                    _weightCtrl.text = fmtNum(result);
                  });
                }
              },
              icon: Icon(Icons.fitness_center, size: 14, color: accent),
              label: Text(
                'คำนวณแผ่นเหล็ก',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Weight / Reps inputs with steppers (Two-Column Layout) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left Column: Weight
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLbs) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _microStepBtn('−2.5', () => _stepField(_weightCtrl, -2.5)),
                        const SizedBox(width: 4),
                        _microStepBtn('+2.5', () => _stepField(_weightCtrl, 2.5)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      _stepBtn(Icons.remove, () => _stepField(_weightCtrl, -weightStep)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: unit,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _stepBtn(Icons.add, () => _stepField(_weightCtrl, weightStep)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12), // Spacer between columns
            // Right Column: Reps
            Expanded(
              child: Row(
                children: [
                  _stepBtn(Icons.remove, () => _stepField(_repsCtrl, -1, isInt: true)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _repsCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'reps',
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onSubmitted: (_) => _submit(isLbs),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _stepBtn(Icons.add, () => _stepField(_repsCtrl, 1, isInt: true)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Full Width Add Set Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _submit(isLbs),
            style: _isWarmup
                ? FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F1C).withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                  )
                : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('เพิ่มเซ็ต'),
          ),
        ),
      ],
    );
  }
}

class _ProgressionHint extends StatelessWidget {
  final List<({double weight, int reps})> lastSessionSets;
  final List<({double weight, int reps})> previousSets;
  final bool isLbs;
  final int repMin;
  final int repMax;

  const _ProgressionHint({
    required this.lastSessionSets,
    required this.previousSets,
    required this.isLbs,
    required this.repMin,
    required this.repMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unit = isLbs ? 'lbs' : 'kg';

    // Celebration: Check if any set in this session achieved or exceeded repMax
    final achievedGoal = previousSets.isNotEmpty &&
        previousSets.any((s) => s.reps >= repMax);

    if (achievedGoal) {
      return Row(
        children: [
          const Icon(Icons.star, size: 12, color: Color(0xFFFF9F1C)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'พิชิตเป้าหมายแล้ว! แนะนำให้ปรับเพิ่มน้ำหนักในรอบหน้า',
              style: TextStyle(fontSize: 10, color: const Color(0xFFFF9F1C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    final nextIdx = previousSets.length;
    if (nextIdx >= lastSessionSets.length) return const SizedBox.shrink();

    final lastSet = lastSessionSets[nextIdx];
    final s = progressionSuggestion(lastSet.weight, lastSet.reps, repMin: repMin, repMax: repMax);
    final display = isLbs ? s.weightKg * kgToLbs : s.weightKg;
    final hint = s.addedWeight
        ? 'เพิ่มน้ำหนัก: ${fmtNum(display)} $unit × ${s.reps} reps'
        : 'เพิ่ม reps: ${fmtNum(display)} $unit × ${s.reps} reps';

    return Row(
      children: [
        Icon(Icons.trending_up, size: 11, color: accent),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            hint,
            style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
