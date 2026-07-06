import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/unit_provider.dart';

const _kAccent = Color(0xFF16A34A);
const _kTextSec = Color(0xFF444444);
const _kTextMuted = Color(0xFF888888);
const _kBorder = Color(0xFFBFDFBF);
const _kSurfaceHi = Color(0xFFEAF5EA);

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

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kSurfaceHi,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: _kAccent),
        ),
      );

  Widget _microStepBtn(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _kSurfaceHi,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, color: _kAccent, fontWeight: FontWeight.w600)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    final weightStep = isLbs ? 5.0 : 2.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Previous session hint ──────────────────────────────
        if (widget.lastSessionSets.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'ครั้งก่อน  ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kTextMuted, letterSpacing: 0.5),
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
                            color: isCurrent ? _kAccent : _kTextSec,
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

        // ── Warmup toggle ──────────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isWarmup = !_isWarmup),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isWarmup ? Colors.orange.withValues(alpha: 0.18) : _kSurfaceHi,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isWarmup ? Colors.orange : _kBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Warm-up',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isWarmup ? Colors.orange : _kTextSec,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Weight / Reps inputs with steppers ────────────────
        if (isLbs) ...[
          Row(
            children: [
              const SizedBox(width: 34),
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
                decoration: InputDecoration(labelText: unit),
              ),
            ),
            const SizedBox(width: 4),
            _stepBtn(Icons.add, () => _stepField(_weightCtrl, weightStep)),
            const SizedBox(width: 10),
            _stepBtn(Icons.remove, () => _stepField(_repsCtrl, -1, isInt: true)),
            const SizedBox(width: 4),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'reps'),
                onSubmitted: (_) => _submit(isLbs),
              ),
            ),
            const SizedBox(width: 4),
            _stepBtn(Icons.add, () => _stepField(_repsCtrl, 1, isInt: true)),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _submit(isLbs),
              style: _isWarmup
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(_isWarmup ? '+ W' : '+ Set'),
            ),
          ],
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
    final nextIdx = previousSets.length;
    if (nextIdx >= lastSessionSets.length) return const SizedBox.shrink();

    final lastSet = lastSessionSets[nextIdx];
    final s = progressionSuggestion(lastSet.weight, lastSet.reps, repMin: repMin, repMax: repMax);
    final display = isLbs ? s.weightKg * kgToLbs : s.weightKg;
    final unit = isLbs ? 'lbs' : 'kg';
    final hint = s.addedWeight
        ? 'เพิ่มน้ำหนัก: ${fmtNum(display)} $unit × ${s.reps} reps'
        : 'เพิ่ม reps: ${fmtNum(display)} $unit × ${s.reps} reps';

    return Row(
      children: [
        const Icon(Icons.trending_up, size: 11, color: _kAccent),
        const SizedBox(width: 3),
        Text(
          hint,
          style: const TextStyle(fontSize: 10, color: _kAccent, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
