import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/set_dao.dart';
import '../../core/models/exercise.dart';
import '../../core/models/session.dart';
import '../../core/models/workout_set.dart';
import '../../core/providers/unit_provider.dart';
import 'history_provider.dart';

const _kTextPrimary = Color(0xFFF2F5EF);
const _kTextSec = Color(0xFFB8C2B4);
const _kTextMuted = Color(0xFF7C8A7C);

class SessionDetailScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  Session? _session;
  List<({Exercise exercise, List<WorkoutSet> sets})> _exercises = [];
  Map<String, List<({double weight, int reps})>> _prevSets = {};
  bool _loading = true;
  final _exerciseDao = ExerciseDao();
  final _setDao = SetDao();

  @override
  void initState() {
    super.initState();
    ref.read(historyProvider.notifier).getDetail(widget.sessionId).then((d) async {
      final prevMap = <String, List<({double weight, int reps})>>{};
      await Future.wait(d.exercises.map((item) async {
        prevMap[item.exercise.name] = await _setDao
            .getLastSessionSetsForExercise(item.exercise.name, d.session.date);
      }));
      if (mounted) {
        setState(() {
          _session = d.session;
          _exercises = List.from(d.exercises);
          _prevSets = prevMap;
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
    await Future.wait([
      for (var i = 0; i < _exercises.length; i++)
        _exerciseDao.updateOrderIndex(_exercises[i].exercise.id!, i),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียด')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _session!;
    final dateStr = session.displayDate;
    final title = session.name ?? dateStr;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (session.name != null)
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kTextSec,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        itemCount: _exercises.length,
        itemBuilder: (_, i) {
          final item = _exercises[i];
          return Padding(
            key: ValueKey(item.exercise.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(Icons.drag_handle, size: 18, color: _kTextMuted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.exercise.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 36,
                          child: Text('Set',
                              style: TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Text(unit,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                        ),
                        const Expanded(
                          child: Text('Reps',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...item.sets.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: s.isWarmup
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9F1C).withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('W',
                                            style: TextStyle(
                                                fontSize: 11, color: Color(0xFFFF9F1C), fontWeight: FontWeight.w700)),
                                      )
                                    : Text('${s.setNumber}',
                                        style: const TextStyle(fontSize: 13, color: _kTextSec)),
                              ),
                              Expanded(
                                child: Text(
                                  s.weightKg.display(isLbs),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: s.isWarmup ? _kTextSec : _kTextPrimary),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${s.reps}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: s.isWarmup ? _kTextSec : _kTextPrimary),
                                ),
                              ),
                            ],
                          ),
                        )),
                    // ── vs ครั้งก่อน ──────────────────────────────
                    () {
                      final prev = _prevSets[item.exercise.name] ?? [];
                      if (prev.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            const Text(
                              'ครั้งก่อน',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kTextMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: prev.asMap().entries.map((e) {
                                final p = e.value;
                                final w = isLbs ? p.weight * kgToLbs : p.weight;
                                final wStr = '${fmtNum(w)} $unit';
                                return Text(
                                  '${e.key + 1}: $wStr × ${p.reps}',
                                  style: const TextStyle(fontSize: 12, color: _kTextSec),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
