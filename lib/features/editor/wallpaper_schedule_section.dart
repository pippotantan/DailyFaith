import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/wallpaper_schedule.dart';

/// One time of day and the weekdays it repeats on.
class WallpaperScheduleSection extends StatelessWidget {
  const WallpaperScheduleSection({
    super.key,
    required this.schedule,
    required this.onChanged,
  });

  final WallpaperSchedule schedule;
  final Future<void> Function(WallpaperSchedule schedule) onChanged;

  Future<void> _commit(BuildContext context, WallpaperSchedule next) async {
    final error = next.validationError;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
    final summary = WallpaperSchedule.describeDays(schedule.daysOfWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Wallpaper Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Enable schedule',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Switch(
              value: schedule.enabled,
              activeThumbColor: Colors.amber,
              onChanged: (enabled) {
                _commit(context, schedule.copyWith(enabled: enabled));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(
              width: 56,
              child: Text('Time', style: TextStyle(color: Colors.white)),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked == null || !context.mounted) return;
                  await _commit(
                    context,
                    schedule.copyWith(hour: picked.hour, minute: picked.minute),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: Text(time.format(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Repeat on', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final day in WallpaperSchedule.displayOrder)
              Expanded(
                child: _DayChip(
                  label: WallpaperSchedule.shortLabel(day),
                  name: WallpaperSchedule.fullName(day),
                  selected: schedule.daysOfWeek.contains(day),
                  onTap: () {
                    final next = Set<int>.of(schedule.daysOfWeek);
                    if (next.contains(day)) {
                      next.remove(day);
                    } else {
                      next.add(day);
                    }
                    _commit(context, schedule.copyWith(daysOfWeek: next));
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          summary,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Runs around this time on the selected days. Android may delay the update.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        key: ValueKey<String>('schedule-day-$name'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.amber : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.amber : Colors.white54,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
