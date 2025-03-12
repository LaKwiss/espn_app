import 'package:espn_app/models/match_event.dart';
import 'package:flutter/material.dart';

class EventWidget extends StatelessWidget {
  const EventWidget({super.key, required this.event});

  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (event.type) {
      case MatchEventType.yellowCard:
        icon = Icons.square;
        color = Colors.amber;
        break;
      case MatchEventType.redCard:
        icon = Icons.square;
        color = Colors.red;
        break;
      case MatchEventType.substitution:
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case MatchEventType.foul:
        icon = Icons.not_interested;
        color = Colors.orange;
        break;
      case MatchEventType.kickoff:
        icon = Icons.sports_soccer;
        color = Colors.grey;
        break;
      case MatchEventType.freeKick:
        icon = Icons.sports_soccer;
        color = Colors.deepPurple;
        break;
      case MatchEventType.throwIn:
        icon = Icons.pan_tool;
        color = Colors.brown;
        break;
      case MatchEventType.shotOffTarget:
        icon = Icons.sports_soccer;
        color = Colors.grey;
        break;
      case MatchEventType.shotBlocked:
        icon = Icons.block;
        color = Colors.orange;
        break;
      default:
        icon = Icons.sports;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              event.time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 51),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.shortText ?? event.text,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
