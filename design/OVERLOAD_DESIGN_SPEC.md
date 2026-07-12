# LIFT — "Overload" Redesign Spec

Reference doc to hand to an IDE/agent (e.g. Antigravity) alongside `overload_mockup.html`
so it can re-skin the existing Flutter codebase (`lib/`) without guessing at values.

The mockup file shows all 7 screens rendered in this theme. This doc gives the exact
tokens and maps them to the current code so changes are mechanical, not creative.

---

## 1. Design tokens

| Token          | Hex        | Current value (to replace)      |
|----------------|------------|----------------------------------|
| Background     | `#0A0C0A`  | `#FFFFFF` (scaffold bg)          |
| Surface        | `#15181580`| `#F4FAF4` (card surface)         |
| Surface (solid)| `#1B1F1B`  | n/a (new — used for opaque cards)|
| Accent (lime)  | `#C6FF3D`  | `#16A34A` (`_kAccent`)           |
| Accent 2 (PR/warn) | `#FF5A3C` | `#E07070` (danger/finish button) |
| Warmup         | `#FF9F1C`  | `Colors.orange` (unchanged hue family, just brighter) |
| Text primary   | `#F2F5EF`  | `#111111` (`_kTextPrimary`)      |
| Text muted     | `#7C8A7C`  | `#888888` (`_kTextMuted`)        |
| Divider/line   | `#262A24`  | `#BFDFBF` (`_kDivider` / `_kBorder`) |

Radii: cards `10px` (was `12px`), buttons `8px` (was `10px`) — slightly tighter/blockier.
Elevation: still flat (no shadow), but cards get a `1px` solid `--line` border same as before.

## 2. Typography

Add to `pubspec.yaml`:
```yaml
dependencies:
  google_fonts: ^6.2.1
```

Roles:
- **Display / headings / big numbers** → `GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)`
  Used for: home hero volume number, app title, exercise card titles, month label, weekly stat numbers.
- **Data / tabular numbers** (weights, reps, e1RM, timer, dates) → `GoogleFonts.jetBrainsMono()`
  Used for: set tables, timer readout, PR table numbers, calendar day numbers.
- **Body / UI labels** → keep `Inter` (already the implicit Material default is close enough,
  or explicitly `GoogleFonts.inter()`) for buttons, hints, muted captions.

Thai text still needs a Thai-capable fallback — Flutter will already fall back to the
system Thai font (Noto Sans Thai on most devices) for glyphs Space Grotesk/JetBrains Mono
don't cover, so no extra config needed there.

## 3. Signature element — "plate stack" bar

Replaces every place the app currently draws a plain `LinearProgressIndicator`
(stats PR table ratio bar) or a bare number-only summary (home exercise row volume).

Concept: a row of 6 thin vertical bars (like plates on a bar, mini bar-chart), lit up
in `--accent` proportional to the value, unlit ones in `--muted` at 40% height.

```dart
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
            color: on ? const Color(0xFFC6FF3D) : const Color(0xFF7C8A7C),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
```

Use it:
- `home_screen.dart` → `_ExerciseList`: next to each exercise row, ratio = `ex.totalVolume / maxVolumeInSession`.
- `stats_screen.dart` → `_ExercisePrTable`: replace the existing `LinearProgressIndicator` (ratio already computed as `ratio` in that file) with `PlateStack(ratio: ratio)`.
- `active_workout_screen.dart` → `_ExerciseCard`: optional, same as home row.

## 4. File-by-file changes

### `lib/app.dart`
- `ThemeData.colorScheme`: swap seed/brightness to `Brightness.dark`, `seedColor: Color(0xFFC6FF3D)`.
- `scaffoldBackgroundColor`: `Color(0xFF0A0C0A)`.
- `appBarTheme` / `cardTheme` / `navigationBarTheme` / `inputDecorationTheme`: replace every
  hardcoded color constant with the token table above (same structure, new hex values).
- `filledButtonTheme`: `backgroundColor: Color(0xFFC6FF3D)`, `foregroundColor: Color(0xFF0A0C0A)`.
- Set `textTheme` to route through `GoogleFonts.spaceGroteskTextTheme()` as the base, then
  override `bodyMedium`/`bodySmall` etc. to `GoogleFonts.inter()` where the current code
  expects body text (Flutter's `TextTheme` merge handles this cleanly).

### `lib/features/home/home_screen.dart`
- Replace `_kAccent = Color(0xFF16A34A)` → `Color(0xFFC6FF3D)`.
- Replace `_kTextPrimary`, `_kTextMuted`, `_kDivider` per token table.
- Hero volume number (`state.sessionName ?? ...`): wrap in `GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 38, letterSpacing: -1.5)`.
- Timer text: `GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700)`, add a soft glow via
  `Shadow(color: accent.withValues(alpha:0.4), blurRadius: 14)` in `TextStyle.shadows`.
- "เสร็จ" danger button: swap red family `#E07070`/`#6B3030` → `#FF5A3C` / dark card bg.

### `lib/features/workout/active_workout_screen.dart`
- Same constant swap as above.
- `_ExerciseCard` left stripe color → accent lime.
- Set table numbers → mono font.
- PR badge background/text → `Color(0xFFFF5A3C)` / `Color(0xFF1A0800)`.

### `lib/features/workout/add_set_form.dart`
- Stepper buttons (`_stepBtn`, `_microStepBtn`) surface/border colors → token table.
- Progression hint text color → accent lime.

### `lib/features/workout/rest_timer_widget.dart`
- Already dark — just retint: ring "on" color `#2A2835`→`#262A24` track, progress arc
  `#C9A96E`→`#C6FF3D`, timer text glow same technique as home timer.

### `lib/features/workout/add_exercise_dialog.dart`
- Sheet background currently hardcoded `Colors.white` → `Color(0xFF1B1F1B)`.
- Search field fill `#F5F5F5` → `Color(0xFF0A0C0A)`, text/icon colors → token table.

### `lib/features/history/history_screen.dart` & `session_detail_screen.dart`
- Constant swap only; tile dividers → `#262A24`; date-day numbers → Space Grotesk;
  set numbers in detail screen → JetBrains Mono.

### `lib/features/stats/stats_screen.dart`
- Constant swap (`accent` local const in several widgets).
- Calendar "worked" day cell: circle → `BorderRadius.circular(5)` (blockier, matches mockup) with lime fill + subtle glow (`BoxShadow(color: accent.withValues(alpha:0.35), blurRadius:8)`).
- `_ExercisePrTable`: swap `LinearProgressIndicator` for `PlateStack` (see §3).
- `_ExerciseChart` (fl_chart bars): bar color → lime, grid line color → `#262A24`.

## 5. Things intentionally unchanged

- All navigation structure, screen flow, and data logic — this is a re-skin only.
- Warmup/PR badge *positions* and *meaning* — only their color values move.
- Rep-range / progression-suggestion logic — purely visual pass.

---
Generated alongside `overload_mockup.html` (static HTML reference — 7 screens, same copy/labels as the live app) — open both together when implementing.
