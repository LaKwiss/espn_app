import 'dart:async';
import 'dart:developer';

import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/match_events_notifier.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/header_section.dart';
import 'package:espn_app/widgets/match_content_toggle.dart';
import 'package:espn_app/widgets/match_info_section.dart';
import 'package:espn_app/widgets/prediction_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  final _refreshController = GlobalKey<RefreshIndicatorState>();

  late Team _homeTeam;
  late Team _awayTeam;

  Club? _homeClub;
  Club? _awayClub;

  String _leagueName = '';

  @override
  void initState() {
    super.initState();

    _leagueId = _extractLeagueId(widget.event.league);

    _initializeTeams();

    _initializeClubs();

    _leagueName = _getLeagueNameById(_leagueId);

    _determineMatchStatus();

    if (_matchStatus == MatchStatus.finished) {
      _initializeScores();
    }

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
    final matchDateTime = DateTime.tryParse(widget.event.date);
    if (matchDateTime == null) {
      _matchStatus = MatchStatus.notStarted;
      return;
    }

    final now = DateTime.now();

    if (matchDateTime.isAfter(now)) {
      _matchStatus = MatchStatus.notStarted;
      return;
    }

    if (widget.event.isFinished) {
      _matchStatus = MatchStatus.finished;
      return;
    }

    final matchEndEstimate = matchDateTime.add(const Duration(minutes: 135));
    if (now.isBefore(matchEndEstimate)) {
      _matchStatus = MatchStatus.inProgress;
      return;
    }

    _matchStatus = MatchStatus.finished;
  }

  Future<void> _refreshData() async {
    log('Rafraîchissement des données du match ${widget.event.id}');

    setState(() {
      _determineMatchStatus();
    });

    ref.read(matchEventsProvider.notifier).refresh();

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
    _homeClub = widget.event.homeClub;
    _awayClub = widget.event.awayClub;

    _homeClub ??= widget.event.getDefaultClub(_homeTeam.id);

    _awayClub ??= widget.event.getDefaultClub(_awayTeam.id);

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
      await Future.wait([widget.event.score.$1, widget.event.score.$2]);
    } catch (e) {
      debugPrint('Error initializing scores: $e');
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
    return 'uefa.champions';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();

    final matchDate = DateTime.tryParse(widget.event.date) ?? DateTime.now();
    final formattedDate = DateFormat(
      'dd MMMM',
      currentLocale,
    ).format(matchDate);
    final formattedTime = DateFormat('HH:mm', currentLocale).format(matchDate);

    final eventsAsync = ref.watch(matchEventsProvider);

    return Scaffold(
      body: RefreshIndicator(
        key: _refreshController,
        onRefresh: _refreshData,
        child: Container(
          color: widget.randomColor,
          child: SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        l10n.matchStatusInProgress,
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
                        l10n.matchStatusFinished,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (_matchStatus == MatchStatus.notStarted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.matchStatusUpcoming,
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
                    randomColor: widget.randomColor,
                  ),
                ),

                SliverToBoxAdapter(
                  child: MatchContentToggle(
                    event: widget.event,
                    homeTeam: _homeTeam,
                    awayTeam: _awayTeam,
                    eventsAsync: eventsAsync,
                    hasStarted: _matchStatus != MatchStatus.notStarted,
                    isWhite:
                        widget.randomColor.computeLuminance() > 0.5
                            ? false
                            : true,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLeagueLogoUrl(String englishLeagueName) {
    switch (englishLeagueName) {
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
}
