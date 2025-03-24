import 'dart:async';
import 'dart:developer';

import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/providers/match_events_notifier.dart';
import 'package:espn_app/widgets/call_to_action.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/event_list.dart';
import 'package:espn_app/widgets/header_section.dart';
import 'package:espn_app/widgets/match_info_section.dart';
import 'package:espn_app/widgets/prediction_section.dart';
import 'package:espn_app/widgets/tactics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum MatchStatus { notStarted, inProgress, finished }

class MatchDetailScreen extends ConsumerStatefulWidget {
  static const route = '/match-detail';

  final Event event;
  final Color randomColor;

  const MatchDetailScreen({
    super.key,
    required this.event,
    required this.randomColor,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _showEvents = false;
  String _leagueId = '';
  MatchStatus _matchStatus = MatchStatus.notStarted;

  // Contrôleur pour le RefreshIndicator
  final _refreshController = GlobalKey<RefreshIndicatorState>();

  // Pour garder une trace des équipes
  late Team _homeTeam;
  late Team _awayTeam;

  // Pour garder une trace des clubs
  Club? _homeClub;
  Club? _awayClub;

  String _leagueName = '';

  @override
  void initState() {
    super.initState();

    // Extraire l'ID de la ligue à partir de l'URL
    _leagueId = _extractLeagueId(widget.event.league);

    // Initialiser les équipes
    _initializeTeams();

    // Initialiser les clubs
    _initializeClubs();

    _leagueName = _getLeagueNameById(_leagueId);

    // Déterminer le statut du match
    _determineMatchStatus();

    // Initialiser les scores si match terminé
    if (_matchStatus == MatchStatus.finished) {
      _initializeScores();
    }

    // Initialiser le provider de match events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeMatchEvents(
        ref,
        MatchParams(
          matchId: widget.event.id,
          leagueId: _leagueId,
          isFinished: _matchStatus == MatchStatus.finished,
        ),
      );
    });
  }

  void _determineMatchStatus() {
    // Convertir la date du match
    final matchDateTime = DateTime.tryParse(widget.event.date);
    if (matchDateTime == null) {
      _matchStatus = MatchStatus.notStarted;
      return;
    }

    final now = DateTime.now();

    // Match pas encore commencé
    if (matchDateTime.isAfter(now)) {
      _matchStatus = MatchStatus.notStarted;
      return;
    }

    // Vérifier si le match est marqué comme terminé explicitement
    if (widget.event.isFinished) {
      _matchStatus = MatchStatus.finished;
      return;
    }

    // Match en cours - si le match a commencé il y a moins de 135 minutes
    final matchEndEstimate = matchDateTime.add(const Duration(minutes: 135));
    if (now.isBefore(matchEndEstimate)) {
      _matchStatus = MatchStatus.inProgress;
      return;
    }

    // Par défaut, supposer qu'il est terminé si plus de 135 minutes sont passées
    _matchStatus = MatchStatus.finished;
  }

  // Fonction pour rafraîchir les données
  Future<void> _refreshData() async {
    log('Rafraîchissement des données du match ${widget.event.id}');

    // Mettre à jour le statut du match
    setState(() {
      _determineMatchStatus();
    });

    // Rafraîchir les événements du match
    ref.read(matchEventsProvider.notifier).refresh();

    // Attendre un peu pour montrer l'indicateur de chargement (plus une bonne expérience utilisateur)
    await Future.delayed(const Duration(milliseconds: 500));

    return Future.value();
  }

  void _initializeTeams() {
    final parts = widget.event.name.split(" at ");
    final awayTeamName = parts.isNotEmpty ? parts.first.trim() : "Away Team";
    final homeTeamName = parts.length > 1 ? parts.last.trim() : "Home Team";

    final awayTeamShortName = widget.event.teamsShortName.$1;
    final homeTeamShortName = widget.event.teamsShortName.$2;

    _awayTeam = Team(
      id: widget.event.idTeam.$2,
      name: awayTeamName,
      shortName: awayTeamShortName,
    );

    _homeTeam = Team(
      id: widget.event.idTeam.$1,
      name: homeTeamName,
      shortName: homeTeamShortName,
    );
  }

  void _initializeClubs() {
    // Utiliser les clubs de l'événement s'ils sont disponibles
    _homeClub = widget.event.homeClub;
    _awayClub = widget.event.awayClub;

    // Si les clubs ne sont pas disponibles dans l'événement, créer des clubs par défaut
    _homeClub ??= widget.event.getDefaultClub(_homeTeam.id);

    _awayClub ??= widget.event.getDefaultClub(_awayTeam.id);

    // Mettre à jour les équipes pour inclure leurs clubs
    _homeTeam = Team(
      id: _homeTeam.id,
      name: _homeTeam.name,
      shortName: _homeTeam.shortName,
      club: _homeClub,
    );

    _awayTeam = Team(
      id: _awayTeam.id,
      name: _awayTeam.name,
      shortName: _awayTeam.shortName,
      club: _awayClub,
    );
  }

  Future<void> _initializeScores() async {
    try {
      // Pour un match terminé, on récupère les scores via un Future
      await Future.wait([widget.event.score.$1, widget.event.score.$2]);
      // Les scores seront affichés dans le FutureBuilder du score terminé.
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des scores: $e');
    }
  }

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
  Widget build(BuildContext context) {
    final matchDate = DateTime.tryParse(widget.event.date) ?? DateTime.now();
    final formattedDate = DateFormat('dd MMMM').format(matchDate);
    final formattedTime = DateFormat('HH:mm').format(matchDate);

    // Récupération des événements depuis le provider
    final eventsAsync = ref.watch(matchEventsProvider);

    return Scaffold(
      body: RefreshIndicator(
        key: _refreshController,
        onRefresh: _refreshData,
        child: Container(
          color: widget.randomColor,
          child: SafeArea(
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Important pour le RefreshIndicator
              slivers: [
                SliverToBoxAdapter(
                  child: CustomAppBar(
                    url: _getLeagueLogoUrl(_leagueName),
                    backgroundColor: widget.randomColor,
                    iconOrientation: 3,
                    onArrowButtonPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SliverToBoxAdapter(child: HeaderSection(event: widget.event)),

                // Affichage conditionnel en fonction du statut du match
                if (_matchStatus == MatchStatus.notStarted)
                  SliverToBoxAdapter(
                    child: PredictionSectionWidget(
                      widget: widget,
                      awayTeam: _awayTeam,
                      homeTeam: _homeTeam,
                    ),
                  ),
                if (_matchStatus == MatchStatus.inProgress)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'EN COURS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (_matchStatus == MatchStatus.finished)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'TERMINÉ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: MatchInfoSectionWidget(
                    date: formattedDate,
                    time: formattedTime,
                    awayTeam: _awayTeam,
                    homeTeam: _homeTeam,
                    isFinished: _matchStatus == MatchStatus.finished,
                    scores: widget.event.score,
                    showEvents: _showEvents,
                    onToggleEvents: () {
                      setState(() {
                        _showEvents = !_showEvents;
                      });
                    },
                  ),
                ),

                // Widget de bascule entre formations et événements
                SliverToBoxAdapter(
                  child: MatchContentToggle(
                    event: widget.event,
                    homeTeam: _homeTeam,
                    awayTeam: _awayTeam,
                    eventsAsync: eventsAsync,
                  ),
                ),

                // Call to action seulement pour les matchs à venir
                if (_matchStatus == MatchStatus.notStarted)
                  SliverToBoxAdapter(
                    child: CallToActionWidget(
                      text: 'CHOISIR LE GAGNANT',
                      onTap: () {
                        // Action à effectuer lors du clic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité à venir...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Obtenir le nom complet de la ligue à partir de son ID
  String _getLeagueNameById(String leagueId) {
    switch (leagueId) {
      case 'ger.1':
        return 'Bundesliga';
      case 'esp.1':
        return 'LALIGA';
      case 'fra.1':
        return 'French Ligue 1';
      case 'eng.1':
        return 'Premier League';
      case 'ita.1':
        return 'Italian Serie A';
      case 'uefa.europa':
        return 'UEFA Europa League';
      case 'uefa.champions':
        return 'Champions League';
      default:
        return 'Champions League';
    }
  }

  // Obtenir l'URL du logo de la ligue
  String _getLeagueLogoUrl(String leagueName) {
    switch (leagueName) {
      case 'Bundesliga':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
      case 'LALIGA':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
      case 'French Ligue 1':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
      case 'Premier League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png';
      case 'Italian Serie A':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
      case 'UEFA Europa League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2310.png';
      case 'Champions League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
      default:
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
    }
  }
}

class MatchContentToggle extends StatefulWidget {
  final Event event;
  final Team homeTeam;
  final Team awayTeam;
  final AsyncValue<List<MatchEvent>> eventsAsync;

  const MatchContentToggle({
    Key? key,
    required this.event,
    required this.homeTeam,
    required this.awayTeam,
    required this.eventsAsync,
  }) : super(key: key);

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
        _showTactics
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
