import 'dart:async';
import 'dart:developer';

import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/match_events_notifier.dart';
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

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  String _leagueId = '';

  // Contrôleur pour les onglets
  late TabController _tabController;

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

    // Initialiser le contrôleur de tabs avec 2 onglets
    _tabController = TabController(length: 2, vsync: this);

    // Extraire l'ID de la ligue à partir de l'URL
    _leagueId = _extractLeagueId(widget.event.league);

    // Initialiser les équipes
    _initializeTeams();

    // Initialiser les clubs
    _initializeClubs();

    _leagueName = _getLeagueNameById(_leagueId);

    // Initialiser les scores à partir des données si match terminé
    if (widget.event.isFinished) {
      _initializeScores();
    }

    // Initialiser le provider de match events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeMatchEvents(
        ref,
        MatchParams(
          matchId: widget.event.id,
          leagueId: _leagueId,
          isFinished: widget.event.isFinished,
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fonction pour rafraîchir les données
  Future<void> _refreshData() async {
    log('Rafraîchissement des données du match ${widget.event.id}');

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

    return Scaffold(
      body: Container(
        color: widget.randomColor,
        child: SafeArea(
          child: Column(
            children: [
              // AppBar personnalisée
              CustomAppBar(
                url: _getLeagueLogoUrl(_leagueName),
                backgroundColor: widget.randomColor,
                iconOrientation: 3,
                onArrowButtonPressed: () {
                  Navigator.of(context).pop();
                },
              ),

              // Contenu principal scrollable
              Expanded(
                child: RefreshIndicator(
                  key: _refreshController,
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Section d'en-tête avec le nom du match
                        HeaderSection(event: widget.event),

                        // Section des prédictions (seulement pour les matchs à venir)
                        if (!widget.event.isFinished)
                          PredictionSectionWidget(
                            widget: widget,
                            awayTeam: _awayTeam,
                            homeTeam: _homeTeam,
                          ),

                        // Message "TERMINÉ" pour les matchs finis
                        if (widget.event.isFinished)
                          Padding(
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

                        // Section d'information sur le match (score, heure, etc.)
                        MatchInfoSectionWidget(
                          date: formattedDate,
                          time: formattedTime,
                          awayTeam: _awayTeam,
                          homeTeam: _homeTeam,
                          isFinished: widget.event.isFinished,
                          scores: widget.event.score,
                          showEvents:
                              true, // Modifié pour être toujours visible avec les onglets
                          onToggleEvents:
                              () {}, // Fonction vide car remplacée par les onglets
                        ),

                        // Barre d'onglets dans le contenu scrollable
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.black,
                            tabs: const [
                              Tab(
                                text: 'ÉVÉNEMENTS',
                                icon: Icon(Icons.sports_soccer),
                              ),
                              Tab(text: 'COMPOSITION', icon: Icon(Icons.group)),
                            ],
                          ),
                        ),

                        // Contenu des onglets
                        SizedBox(
                          // Hauteur fixe pour le contenu des onglets
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: Événements du match
                              _buildEventsTab(),

                              // Tab 2: Compositions des équipes
                              _buildTacticsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construit l'onglet des événements
  Widget _buildEventsTab() {
    // Récupération des événements depuis le provider
    final eventsAsync = ref.watch(matchEventsProvider);

    return eventsAsync.when(
      data:
          (events) => EventsListWidget(
            events: events,
            homeTeam: _homeTeam,
            awayTeam: _awayTeam,
          ),
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Erreur de chargement des événements: $error'),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Construit l'onglet des tactiques
  Widget _buildTacticsTab() {
    return TacticsView(
      event: widget.event,
      homeTeam: _homeTeam,
      awayTeam: _awayTeam,
      onToggleView: () {
        // Basculer vers l'onglet des événements
        _tabController.animateTo(0);
      },
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
