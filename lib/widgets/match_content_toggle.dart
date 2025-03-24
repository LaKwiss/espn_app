import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/widgets/event_list.dart';
import 'package:espn_app/widgets/tactics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchContentToggle extends StatefulWidget {
  final Event event;
  final Team homeTeam;
  final Team awayTeam;
  final AsyncValue<List<MatchEvent>> eventsAsync;
  final bool hasStarted;

  const MatchContentToggle({
    super.key,
    required this.event,
    required this.homeTeam,
    required this.awayTeam,
    required this.eventsAsync,
    required this.hasStarted,
  });

  @override
  State<MatchContentToggle> createState() => _MatchContentToggleState();
}

class _MatchContentToggleState extends State<MatchContentToggle> {
  bool _showTactics = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de bascule
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showTactics = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showTactics ? Colors.transparent : Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'ÉVÉNEMENTS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 16,
                        color: _showTactics ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showTactics = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showTactics ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'FORMATIONS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 16,
                        color: _showTactics ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contenu selon la sélection
        !widget.hasStarted
            ? Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upcoming, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Les informations suivront',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revenez après le début du match pour consulter les détails',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
            : _showTactics
            ? TacticsView(
              event: widget.event,
              homeTeam: widget.homeTeam,
              awayTeam: widget.awayTeam,
              onToggleView: () => setState(() => _showTactics = false),
            )
            : widget.eventsAsync.when(
              data:
                  (events) => EventsListWidget(
                    events: events,
                    homeTeam: widget.homeTeam,
                    awayTeam: widget.awayTeam,
                  ),
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Erreur de chargement des événements: $error'),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
      ],
    );
  }
}
