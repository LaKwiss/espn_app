// lib/widgets/match_content_toggle.dart
import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/match_events_notifier.dart'; // Assurez-vous d'importer ce provider
import 'package:espn_app/widgets/event_list.dart';
import 'package:espn_app/widgets/tactics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchContentToggle extends ConsumerStatefulWidget {
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
  ConsumerState<MatchContentToggle> createState() => _MatchContentToggleState();
}

class _MatchContentToggleState extends ConsumerState<MatchContentToggle> {
  bool _showTactics = false;

  // Extraire l'ID de la ligue à partir de l'URL
  String _extractLeagueId(String leagueUrl) {
    final uriParts = leagueUrl.split('/');
    for (int i = 0; i < uriParts.length; i++) {
      if (uriParts[i] == 'leagues' && i + 1 < uriParts.length) {
        String leagueWithParams = uriParts[i + 1];
        return leagueWithParams.split('?').first;
      }
    }
    return 'uefa.champions'; // Valeur par défaut
  }

  @override
  void initState() {
    super.initState();

    // S'assurer que le provider est bien initialisé lors de la création du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leagueId = _extractLeagueId(widget.event.league);
      final params = MatchParams(
        matchId: widget.event.id,
        leagueId: leagueId,
        isFinished: widget.event.isFinished,
      );

      // Réinitialiser explicitement le provider d'événements
      initializeMatchEvents(ref, params);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observer directement le provider d'événements ici pour éviter les problèmes de synchronisation
    final eventsAsync = ref.watch(matchEventsProvider);

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
            : eventsAsync.when(
              data: (events) {
                // Afficher un message si la liste est vide
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun événement disponible',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 24,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Rafraîchir les événements
                              ref.read(matchEventsProvider.notifier).refresh();
                            },
                            child: const Text('Rafraîchir'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Afficher les événements s'ils existent
                return EventsListWidget(
                  events: events,
                  homeTeam: widget.homeTeam,
                  awayTeam: widget.awayTeam,
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement des événements...'),
                        ],
                      ),
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text('Erreur de chargement des événements'),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Réinitialiser le provider d'événements
                              final leagueId = _extractLeagueId(
                                widget.event.league,
                              );
                              final params = MatchParams(
                                matchId: widget.event.id,
                                leagueId: leagueId,
                                isFinished: widget.event.isFinished,
                              );
                              initializeMatchEvents(ref, params);
                            },
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
