import 'package:flutter/material.dart';
import '../../core/database/exercise_dao.dart';

// ลบค่าสีคงที่เพื่อให้ดึงจาก Theme.of(context) ไดนามิก

Future<String?> showAddExerciseSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddExerciseSheet(),
  );
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet();

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _all = [];
  List<String> _recent = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    final dao = ExerciseDao();
    Future.wait([dao.getAllNames(), dao.getRecentNames()]).then((results) {
      if (mounted) {
        setState(() {
          _all = results[0];
          _recent = results[1];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _select(String name) => Navigator.of(context).pop(name.trim());

  Future<void> _deleteExercise(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบท่า?'),
        content: Text('ลบ "$name" ออกจากรายการ?\nประวัติ set ทั้งหมดของท่านี้จะถูกลบด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A0800),
              foregroundColor: const Color(0xFFFF5A3C),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final dao = ExerciseDao();
    await dao.deleteByName(name);
    final results = await Future.wait([dao.getAllNames(), dao.getRecentNames()]);
    if (mounted) {
      setState(() {
        _all = results[0];
        _recent = results[1];
      });
    }
  }

  List<String> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((s) => s.toLowerCase().contains(q)).toList();
  }

  bool get _hasExactMatch =>
      _all.any((s) => s.toLowerCase() == _query.toLowerCase().trim());

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filtered;
    final theme = Theme.of(context);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final accent = theme.colorScheme.primary;
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final outlineColor = theme.colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: outlineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'ค้นหาท่า...',
                prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _select(v);
              },
            ),
          ),
          const SizedBox(height: 8),

          // List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                // Recent section (only when not searching)
                if (_query.isEmpty && _recent.isNotEmpty) ...[
                  const _SectionLabel('ล่าสุด'),
                  ..._recent.map((n) => _ExerciseItem(
                        name: n,
                        onTap: () => _select(n),
                        onLongPress: () => _deleteExercise(n),
                      )),
                  const SizedBox(height: 8),
                  const _SectionLabel('ทั้งหมด'),
                ],

                // Filtered / all list
                if (_all.isEmpty && _query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center, size: 32, color: outlineColor),
                        const SizedBox(height: 10),
                        Text('ยังไม่มีท่าในระบบ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted)),
                        const SizedBox(height: 4),
                        Text('พิมพ์ชื่อท่าด้านบนเพื่อเพิ่มใหม่',
                            style: TextStyle(fontSize: 12, color: textMuted)),
                      ],
                    ),
                  )
                else if (filtered.isEmpty && _query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'ไม่พบ "$_query"',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  )
                else
                  ...filtered.map((n) => _ExerciseItem(
                        name: n,
                        onTap: () => _select(n),
                        onLongPress: () => _deleteExercise(n),
                      )),

                // Create new option
                if (_query.trim().isNotEmpty && !_hasExactMatch) ...[
                  const Divider(height: 16),
                  _ExerciseItem(
                    name: 'เพิ่ม "${_query.trim()}"',
                    icon: Icons.add_circle_outline,
                    iconColor: accent,
                    nameColor: accent,
                    onTap: () => _select(_query.trim()),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: textMuted,
        ),
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;
  final Color? iconColor;
  final Color? nameColor;

  const _ExerciseItem({
    required this.name,
    required this.onTap,
    this.onLongPress,
    this.icon = Icons.fitness_center,
    this.iconColor,
    this.nameColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? theme.textTheme.bodySmall?.color ?? Colors.grey;
    final resolvedNameColor = nameColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: resolvedIconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: resolvedNameColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
