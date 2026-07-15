import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/analytics.dart';
import '../../../../l10n/app_localizations.dart';

/// Per-room occupancy bars. Colour shifts green → amber → red as a room fills.
/// Pure-widget implementation (LayoutBuilder for the bar width), no painter.
class RoomOccupancyBars extends StatelessWidget {
  final List<RoomOccupancy> rooms;
  const RoomOccupancyBars({super.key, required this.rooms});

  static Color colorFor(double fraction) {
    if (fraction >= 0.9) return AppColors.danger;
    if (fraction >= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppLocalizations.of(context).chartNoRooms,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < rooms.length; i++) ...[
          _RoomBar(room: rooms[i], color: colorFor(rooms[i].fraction)),
          if (i < rooms.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _RoomBar extends StatelessWidget {
  final RoomOccupancy room;
  final Color color;
  const _RoomBar({required this.room, required this.color});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = room.capacity > 0 ? (room.fraction * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.roomName.isEmpty ? l.roomUnnamed : room.roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${room.occupied}/${room.capacity} · $pct%',
              style: AppTextStyles.caption.copyWith(color: AppColors.textBody),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 8, width: w, color: AppColors.border),
                  Container(
                    height: 8,
                    width: w * room.fraction.clamp(0.0, 1.0),
                    color: color,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          '${room.boxes} ${room.boxes == 1 ? l.roomBoxSingular : l.roomBoxPlural} · ${room.vacant} ${l.roomSlotsFree}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textBody.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
