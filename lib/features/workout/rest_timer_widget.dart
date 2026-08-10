import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rest_timer_provider.dart';

class RestTimerBottomSheet extends ConsumerWidget {
  const RestTimerBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);
    final mins = timer.secondsLeft ~/ 60;
    final secs = timer.secondsLeft % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final isDone = timer.secondsLeft == 0 && timer.isRunning == false && timer.totalSeconds > 0;
    final isReady = !timer.isRunning && !isDone && timer.secondsLeft > 0;

    final theme = Theme.of(context);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final accent = theme.colorScheme.primary;
    final border = theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'REST',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 28),
          // Timer circle
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: isReady ? 1.0 : timer.progress,
                    strokeWidth: 6,
                    backgroundColor: border,
                    color: isDone
                        ? accent
                        : isReady
                            ? border
                            : accent,
                  ),
                ),
                Text(
                  isDone ? 'GO!' : timeStr,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    color: isDone
                        ? accent
                        : isReady
                            ? textMuted
                            : textPrimary,
                    shadows: !isReady
                        ? [
                            Shadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Adjust buttons (always visible)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustButton(label: '−30s', onTap: () => notifier.adjust(-30)),
              const SizedBox(width: 8),
              _AdjustButton(label: '−15s', onTap: () => notifier.adjust(-15)),
              const SizedBox(width: 8),
              _AdjustButton(label: '+15s', onTap: () => notifier.adjust(15)),
              const SizedBox(width: 8),
              _AdjustButton(label: '+30s', onTap: () => notifier.adjust(30)),
            ],
          ),
          const SizedBox(height: 16),

          // Start button (when not started) or Skip button (when running)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isReady
                ? FilledButton.icon(
                    onPressed: () => notifier.start(seconds: timer.secondsLeft),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('เริ่ม'),
                  )
                : OutlinedButton(
                    onPressed: () {
                      notifier.skip();
                      Navigator.of(context).pop();
                    },
                    child: const Text('ข้าม'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(72, 40),
      ),
      child: Text(label),
    );
  }
}
