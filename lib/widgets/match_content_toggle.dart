import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/match_events_notifier.dart';
import 'package:espn_app/widgets/event_list.dart';
import 'package:espn_app/widgets/tactics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MatchContentToggle extends ConsumerStatefulWidget {
  final Event event;
  final Team homeTeam;
  final Team awayTeam;
  final AsyncValue<List<MatchEvent>> eventsAsync;
  final bool hasStarted;
  final bool isWhite;

  const MatchContentToggle({
    super.key,
    required this.event,
    required this.homeTeam,
    required this.awayTeam,
    required this.eventsAsync,
    required this.hasStarted,
    required this.isWhite,
  });

  @override
  ConsumerState<MatchContentToggle> createState() => _MatchContentToggleState();
}

class _MatchContentToggleState extends ConsumerState<MatchContentToggle> {
  bool _showTactics = false;

  String _extractLeagueId(String leagueUrl) {
    final uriParts = leagueUrl.split('/');
    for (int i = 0; i < uriParts.length; i++) {
      if (uriParts[i] == 'leagues' && i + 1 < uriParts.length) {
        String leagueWithParams = uriParts[i + 1];
        return leagueWithParams.split('?').first;
      }
    }
    return 'uefa.champions';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leagueId = _extractLeagueId(widget.event.league);
      final params = MatchParams(
        matchId: widget.event.id,
        leagueId: leagueId,
        isFinished: widget.event.isFinished,
      );

      ref.read(matchEventsProvider.notifier).initialize(params);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final eventsAsync = ref.watch(matchEventsProvider);

    final Color activeBackgroundColor = theme.colorScheme.onSurface;
    final Color inactiveBackgroundColor = theme.cardColor;
    final Color activeTextColor = theme.colorScheme.surface;
    final Color inactiveTextColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.8,
    );

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: inactiveBackgroundColor,
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
                      color:
                          !_showTactics
                              ? activeBackgroundColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      l10n.eventsTab,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 16,
                        color:
                            !_showTactics ? activeTextColor : inactiveTextColor,
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
                      color:
                          _showTactics
                              ? activeBackgroundColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      l10n.formationsTab,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 16,
                        color:
                            _showTactics ? activeTextColor : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        !widget.hasStarted
            ? Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upcoming,
                      size: 64,
                      color:
                          widget.isWhite
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.informationWillFollow,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color:
                            widget.isWhite
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.checkBackAfterKickoff,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            widget.isWhite
                                ? Colors.white.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                      ),
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
                            l10n.noEventsAvailable,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 24,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(matchEventsProvider.notifier).refresh();
                            },
                            child: Text(l10n.refresh),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return EventsListWidget(
                  events: events,
                  homeTeam: widget.homeTeam,
                  awayTeam: widget.awayTeam,
                );
              },
              loading:
                  () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.loadingEvents),
                        ],
                      ),
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.errorLoadingEventsGeneric(error.toString()),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
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
                            child: Text(l10n.tryAgain),
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
