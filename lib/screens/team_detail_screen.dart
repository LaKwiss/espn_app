import 'dart:convert';
import 'package:espn_app/models/lineup_player.dart';
import 'package:espn_app/models/player_position.dart';
import 'package:espn_app/providers/athletes_notifier.dart';
import 'package:espn_app/providers/lineup_notifier.dart';
import 'package:espn_app/screens/soccer_field_painter.dart';
import 'package:espn_app/widgets/last_matches.dart';
import 'package:espn_app/widgets/player_circle.dart';
import 'package:espn_app/widgets/team_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/models/athlete.dart';
import 'package:espn_app/models/stats.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/league.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/club_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Athlete> _players = [];
  Map<String, dynamic> _teamStats = {};
  String _stadiumName = '';
  String _foundedYear = '';
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamData() async {
    try {
      // Fetch team data from API with proper error handling
      final response = await http
          .get(
            Uri.parse(
              'http://sports.core.api.espn.com/v2/sports/soccer/leagues/esp.1/seasons/2024/teams/${widget.team.id}',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final teamData = json.decode(response.body);

        // Extract data with null checks and default values
        setState(() {
          _isLoading = false;

          // Extract team bio from various possible locations in the API

          // Extract stadium info safely
          final venueData = teamData['venue'];
          if (venueData != null && venueData is Map) {
            _stadiumName = venueData['fullName'] ?? 'Unknown Stadium';
          } else {
            _stadiumName = 'Unknown Stadium';
          }

          // Extract founded year
          _foundedYear = teamData['established'] ?? 'Unknown';

          // Extract nickname
          final displayNames = teamData['displayNames'];
          if (displayNames != null &&
              displayNames is List &&
              displayNames.isNotEmpty) {
            for (var nameData in displayNames) {
              if (nameData['type'] == 'nickname') {
                _nickname = nameData['value'] ?? '';
                break;
              }
            }
          }

          // Parse team stats more robustly
          _teamStats = _extractTeamStats(teamData);

          // Get players (fetch player data separately)
          _fetchPlayers(teamData);
        });
      } else {
        // Handle API error with more detailed information
        _handleApiError(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      _handleApiError('Error fetching team data: $error');
    }
  }

  Map<String, dynamic> _extractTeamStats(Map<String, dynamic> teamData) {
    final stats = <String, dynamic>{};

    // Try to extract standing summary
    stats['position'] = teamData['standingSummary'] ?? 'Unknown';

    // Try to extract record and stats
    if (teamData.containsKey('record') &&
        teamData['record'] != null &&
        teamData['record'].containsKey('items') &&
        teamData['record']['items'] is List &&
        teamData['record']['items'].isNotEmpty) {
      final recordItems = teamData['record']['items'] as List;
      if (recordItems.isNotEmpty && recordItems[0].containsKey('stats')) {
        final statsList = recordItems[0]['stats'] as List?;

        if (statsList != null && statsList.isNotEmpty) {
          for (var statItem in statsList) {
            if (statItem.containsKey('name') && statItem.containsKey('value')) {
              final name = statItem['name'];
              final value = statItem['value'];

              switch (name) {
                case 'wins':
                  stats['wins'] = value;
                  break;
                case 'losses':
                  stats['losses'] = value;
                  break;
                case 'ties':
                case 'draws':
                  stats['draws'] = value;
                  break;
                case 'pointsFor':
                case 'goalsFor':
                  stats['goalsFor'] = value;
                  break;
                case 'pointsAgainst':
                case 'goalsAgainst':
                  stats['goalsAgainst'] = value;
                  break;
                case 'points':
                  stats['points'] = value;
                  break;
                default:
                  stats[name] = value;
                  break;
              }
            }
          }
        }
      }
    }

    // Extract form if available
    stats['form'] = teamData['form'] ?? 'WWDLD';

    // Set defaults for missing values
    stats.putIfAbsent('wins', () => 0);
    stats.putIfAbsent('draws', () => 0);
    stats.putIfAbsent('losses', () => 0);
    stats.putIfAbsent('goalsFor', () => 0);
    stats.putIfAbsent('goalsAgainst', () => 0);
    stats.putIfAbsent('points', () => 0);

    return stats;
  }

  void _handleApiError(String errorMessage) {
    setState(() {
      _isLoading = false;
      _teamStats = {
        'position': 'Unknown',
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'points': 0,
        'form': 'WWDLD',
      };
      // Prepare minimal mock data
      _generateMockPlayers();
    });
  }

  Future<void> _fetchPlayers(Map<String, dynamic> teamData) async {
    try {
      final List<Athlete> playersList = [];
      // Check if there's a roster/players endpoint in the teamData
      String? playersUrl;

      if (teamData.containsKey('roster') &&
          teamData['roster'] != null &&
          teamData['roster'].containsKey('\$ref')) {
        playersUrl = teamData['roster']['\$ref'];
      } else if (teamData.containsKey('athletes') &&
          teamData['athletes'] != null &&
          teamData['athletes'].containsKey('\$ref')) {
        playersUrl = teamData['athletes']['\$ref'];
      }

      if (playersUrl != null) {
        // Fetch player data from roster URL
        final response = await http
            .get(Uri.parse(playersUrl))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final rosterData = json.decode(response.body);

          if (rosterData.containsKey('items') && rosterData['items'] is List) {
            final playerItems = rosterData['items'] as List;

            for (var item in playerItems) {
              if (item.containsKey('athlete') &&
                  item['athlete'] != null &&
                  item['athlete'].containsKey('\$ref')) {
                final athleteUrl = item['athlete']['\$ref'];
                // Fetch individual athlete data
                final athleteResponse = await http.get(Uri.parse(athleteUrl));

                if (athleteResponse.statusCode == 200) {
                  final athleteData = json.decode(athleteResponse.body);

                  // Extract and create an Athlete object
                  final athlete = _parseAthleteData(athleteData);
                  if (athlete != null) {
                    playersList.add(athlete);
                  }
                }
              }
            }
          }
        }
      }

      setState(() {
        // Use fetched players or generate mock ones if list is empty
        if (playersList.isNotEmpty) {
          _players = playersList;
        } else {
          _generateMockPlayers();
        }
      });
    } catch (error) {
      setState(() {
        _generateMockPlayers();
      });
    }
  }

  Athlete? _parseAthleteData(Map<String, dynamic> athleteData) {
    try {
      // Extract basic player info
      final id = athleteData['id'] ?? 0;
      final fullName = athleteData['displayName'] ?? 'Unknown Player';

      // Extract birthdate
      String dateOfBirth = 'Unknown';
      if (athleteData.containsKey('dateOfBirth') &&
          athleteData['dateOfBirth'] != null) {
        dateOfBirth = athleteData['dateOfBirth'];
      }

      // Extract country
      String country = 'Unknown';
      if (athleteData.containsKey('nationality') &&
          athleteData['nationality'] != null &&
          athleteData['nationality'].containsKey('name')) {
        country = athleteData['nationality']['name'];
      } else if (athleteData.containsKey('country') &&
          athleteData['country'] != null &&
          athleteData['country'].containsKey('name')) {
        country = athleteData['country']['name'];
      }

      // Extract stats
      final stats = _parsePlayerStats(athleteData);

      // Use the team's club
      final club =
          widget.team.club ??
          Club(
            id: int.parse(widget.team.id),
            name: widget.team.name,
            logo:
                'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
            country: 'Unknown',
            flag: '',
            league: const League(
              id: 1,
              name: 'Unknown League',
              displayName: 'Unknown League',
              logo: '',
              country: 'Unknown',
              flag: '',
              shortName: '',
            ),
          );

      return Athlete(
        id: id,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        country: country,
        stats: stats,
        club: club,
      );
    } catch (e) {
      return null;
    }
  }

  Stats _parsePlayerStats(Map<String, dynamic> athleteData) {
    int goals = 0;
    int assists = 0;
    int appearances = 0;
    int minutesPlayed = 0;
    int yellowCards = 0;
    int redCards = 0;

    // Try to extract statistics data
    if (athleteData.containsKey('statistics') &&
        athleteData['statistics'] != null &&
        athleteData['statistics'] is List) {
      final statsList = athleteData['statistics'] as List;
      for (var statItem in statsList) {
        if (statItem is Map<String, dynamic>) {
          // Look for various stat names that might be in the API
          if (statItem.containsKey('name') && statItem.containsKey('value')) {
            final name = statItem['name']?.toString().toLowerCase();
            final value = int.tryParse(statItem['value'].toString()) ?? 0;

            switch (name) {
              case 'goals':
              case 'totalgoals':
                goals = value;
                break;
              case 'assists':
              case 'totalassists':
                assists = value;
                break;
              case 'appearances':
              case 'games':
              case 'matches':
                appearances = value;
                break;
              case 'minutesplayed':
              case 'minutes':
                minutesPlayed = value;
                break;
              case 'yellowcards':
              case 'cautions':
                yellowCards = value;
                break;
              case 'redcards':
              case 'ejections':
                redCards = value;
                break;
            }
          }
        }
      }
    }

    return Stats(
      id: 0,
      goals: goals,
      assists: assists,
      appearances: appearances,
      minutesPlayed: minutesPlayed,
      yellowCards: yellowCards,
      redCards: redCards,
    );
  }

  void _generateMockPlayers() {
    _players = List.generate(
      18,
      (index) => Athlete(
        id: 1000 + index,
        fullName: 'Player ${index + 1}',
        dateOfBirth: '1990-01-01',
        country: 'Spain',
        stats: Stats(
          id: index,
          goals: 5,
          assists: 3,
          appearances: 15,
          minutesPlayed: 1200,
          yellowCards: 2,
          redCards: 0,
        ),
        club:
            widget.team.club ??
            Club(
              id: int.tryParse(widget.team.id) ?? 0,
              name: widget.team.name,
              logo:
                  'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
              country: 'Spain',
              flag: 'https://a.espncdn.com/i/flags/20x13/esp.gif',
              league: const League(
                id: 1,
                name: 'La Liga',
                displayName: 'La Liga',
                logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png',
                country: 'Spain',
                flag: 'https://a.espncdn.com/i/flags/20x13/esp.gif',
                shortName: 'LIGA',
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomAppBar(
                  url:
                      'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
                  backgroundColor: Colors.grey[100],
                  iconOrientation: 3,
                  onArrowButtonPressed: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.team.name.toUpperCase(),
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 32,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Hero(
                            tag: 'team-logo-${widget.team.id}',
                            child: ClipOval(
                              child: Image.network(
                                'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.sports_soccer,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Position:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _teamStats['position'] ?? '3rd in League',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_nickname.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nickname: $_nickname',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(text: 'LINEUP'),
                    Tab(text: 'PLAYERS'),
                    Tab(text: 'STATS'),
                  ],
                ),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading team data...'),
                              ],
                            ),
                          )
                          : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLineupTab(),
                              _buildPlayersTab(),
                              _buildStatsTab(),
                            ],
                          ),
                ),
              ],
            ),

            // Widget d'information sur le club en haut à droite
            if (widget.team.club != null)
              Positioned(
                top: 80, // Position sous la barre d'apps
                right: 16,
                child: ClubInfoWidget(club: widget.team.club!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineupTab() {
    return Consumer(
      builder: (context, ref, child) {
        final lineupAsync = ref.watch(lineupProvider);

        // Ajouter ceci dans initState() pour charger les données
        // ref.read(lineupProvider.notifier).fetchLineup('ger.1', widget.team.id, 'SOME_EVENT_ID');
        // ref.read(athletesProvider.notifier).fetchTeamAthletes('ger.1', widget.team.id);

        return lineupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) =>
                  Center(child: Text('Failed to load lineup: $error')),
          data: (lineup) {
            final formation = lineup.formationSummary;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Formation: $formation',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Stadium: $_stadiumName',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.blue[50],
                        avatar: const Icon(Icons.stadium, size: 16),
                      ),
                    ],
                  ),
                  if (_foundedYear.isNotEmpty && _foundedYear != 'Unknown')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Founded: $_foundedYear',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Field markings
                        CustomPaint(
                          size: const Size(double.infinity, 400),
                          painter: SoccerFieldPainter(),
                        ),

                        // Team name in the center
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.team.name,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // Position the players based on formation
                        ..._getPlayerPositions(formation, lineup.players).map((
                          position,
                        ) {
                          return Positioned(
                            top: position.top,
                            left: position.left,
                            child: PlayerCircle(
                              playerId: position.playerId,
                              position: position.position,
                              leagueId: 'ger.1',
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Reste du contenu...
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<PlayerPosition> _getPlayerPositions(
    String formation,
    List<LineupPlayer> players,
  ) {
    final formationParts = formation.split('-').map(int.parse).toList();
    final positions = <PlayerPosition>[];
    final width = MediaQuery.of(context).size.width - 32; // Avec padding

    // Toujours récupérer le gardien (qui a la formationPlace = 1)
    final goalkeeper = players.firstWhere(
      (p) => p.formationPlace == '1',
      orElse:
          () => players.firstWhere(
            (p) => p.positionId == '1',
            orElse: () => LineupPlayer.empty(),
          ),
    );

    if (goalkeeper.id.isNotEmpty) {
      positions.add(
        PlayerPosition(
          playerIndex: int.parse(goalkeeper.formationPlace) - 1,
          playerId: goalkeeper.id,
          position: 'GK',
          top: 350,
          left: width / 2 - 30,
        ),
      );
    }

    // Placer les défenseurs
    int defenderCount = formationParts[0];
    List<LineupPlayer> defenders =
        players
            .where(
              (p) =>
                  p.isStarter &&
                  int.parse(p.formationPlace) > 1 &&
                  int.parse(p.formationPlace) <= 1 + defenderCount,
            )
            .toList();

    if (defenders.length == defenderCount) {
      double defenderSpacing = width / (defenderCount + 1);
      defenders.sort(
        (a, b) =>
            int.parse(a.formationPlace).compareTo(int.parse(b.formationPlace)),
      );

      for (int i = 0; i < defenders.length; i++) {
        positions.add(
          PlayerPosition(
            playerIndex: int.parse(defenders[i].formationPlace) - 1,
            playerId: defenders[i].id,
            position: i == 0 ? 'LB' : (i == defenderCount - 1 ? 'RB' : 'CB'),
            top: 280,
            left: defenderSpacing * (i + 1) - 30,
          ),
        );
      }
    }

    // Placer les milieux de terrain
    int midfielderCount = formationParts[1];
    int midfielderStart = 1 + defenderCount;
    List<LineupPlayer> midfielders =
        players
            .where(
              (p) =>
                  p.isStarter &&
                  int.parse(p.formationPlace) > midfielderStart &&
                  int.parse(p.formationPlace) <=
                      midfielderStart + midfielderCount,
            )
            .toList();

    if (midfielders.length == midfielderCount) {
      double midfielderSpacing = width / (midfielderCount + 1);
      midfielders.sort(
        (a, b) =>
            int.parse(a.formationPlace).compareTo(int.parse(b.formationPlace)),
      );

      for (int i = 0; i < midfielders.length; i++) {
        positions.add(
          PlayerPosition(
            playerIndex: int.parse(midfielders[i].formationPlace) - 1,
            playerId: midfielders[i].id,
            position: 'CM',
            top: 200,
            left: midfielderSpacing * (i + 1) - 30,
          ),
        );
      }
    }

    // Placer les attaquants
    int forwardCount = formationParts.length > 2 ? formationParts[2] : 0;
    int forwardStart = midfielderStart + midfielderCount;
    List<LineupPlayer> forwards =
        players
            .where(
              (p) =>
                  p.isStarter &&
                  int.parse(p.formationPlace) > forwardStart &&
                  int.parse(p.formationPlace) <= forwardStart + forwardCount,
            )
            .toList();

    if (forwards.length == forwardCount) {
      double forwardSpacing = width / (forwardCount + 1);
      forwards.sort(
        (a, b) =>
            int.parse(a.formationPlace).compareTo(int.parse(b.formationPlace)),
      );

      for (int i = 0; i < forwards.length; i++) {
        String position = 'ST';
        if (forwardCount >= 3) {
          if (i == 0)
            position = 'LW';
          else if (i == forwardCount - 1)
            position = 'RW';
        }

        positions.add(
          PlayerPosition(
            playerIndex: int.parse(forwards[i].formationPlace) - 1,
            playerId: forwards[i].id,
            position: position,
            top: 100,
            left: forwardSpacing * (i + 1) - 30,
          ),
        );
      }
    }

    // Gestion des formations avec 4 lignes comme le 4-2-3-1
    if (formationParts.length > 3) {
      int attackingMidsCount = formationParts[2];
      int attackingMidsStart = forwardStart;
      forwardStart = attackingMidsStart + attackingMidsCount;

      List<LineupPlayer> attackingMids =
          players
              .where(
                (p) =>
                    p.isStarter &&
                    int.parse(p.formationPlace) > attackingMidsStart &&
                    int.parse(p.formationPlace) <= forwardStart,
              )
              .toList();

      if (attackingMids.length == attackingMidsCount) {
        double attackingMidSpacing = width / (attackingMidsCount + 1);
        attackingMids.sort(
          (a, b) => int.parse(
            a.formationPlace,
          ).compareTo(int.parse(b.formationPlace)),
        );

        for (int i = 0; i < attackingMids.length; i++) {
          String position = 'CAM';
          if (attackingMidsCount >= 3) {
            if (i == 0)
              position = 'LAM';
            else if (i == attackingMidsCount - 1)
              position = 'RAM';
          }

          positions.add(
            PlayerPosition(
              playerIndex: int.parse(attackingMids[i].formationPlace) - 1,
              playerId: attackingMids[i].id,
              position: position,
              top: 150,
              left: attackingMidSpacing * (i + 1) - 30,
            ),
          );
        }

        // Réajuster les attaquants pour une formation comme 4-2-3-1
        if (formationParts[3] == 1) {
          List<LineupPlayer> strikers =
              players
                  .where(
                    (p) =>
                        p.isStarter &&
                        int.parse(p.formationPlace) > forwardStart,
                  )
                  .toList();

          if (strikers.isNotEmpty) {
            positions.add(
              PlayerPosition(
                playerIndex: int.parse(strikers[0].formationPlace) - 1,
                playerId: strikers[0].id,
                position: 'ST',
                top: 80,
                left: width / 2 - 30,
              ),
            );
          }
        }
      }
    }

    return positions;
  }

  Widget _buildPlayersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final athletesAsync = ref.watch(athletesProvider);

        return athletesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  Center(child: Text('Error loading players: $error')),
          data: (athletes) {
            if (athletes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No players data available'),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(athletesProvider.notifier)
                            .fetchTeamAthletes('ger.1', widget.team.id);
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            // Tri des joueurs par position
            final goalkeepers =
                athletes
                    .where(
                      (p) =>
                          p.position?.toLowerCase().contains('goalkeeper') ??
                          false,
                    )
                    .toList();
            final defenders =
                athletes
                    .where(
                      (p) =>
                          p.position?.toLowerCase().contains('defender') ??
                          false,
                    )
                    .toList();
            final midfielders =
                athletes
                    .where(
                      (p) =>
                          p.position?.toLowerCase().contains('midfielder') ??
                          false,
                    )
                    .toList();
            final forwards =
                athletes
                    .where(
                      (p) =>
                          p.position?.toLowerCase().contains('forward') ??
                          false,
                    )
                    .toList();

            // Autres joueurs sans position identifiée
            final others =
                athletes
                    .where(
                      (p) =>
                          !(p.position?.toLowerCase().contains('goalkeeper') ??
                              false) &&
                          !(p.position?.toLowerCase().contains('defender') ??
                              false) &&
                          !(p.position?.toLowerCase().contains('midfielder') ??
                              false) &&
                          !(p.position?.toLowerCase().contains('forward') ??
                              false),
                    )
                    .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    // Implémentation future de la recherche
                  },
                ),
                const SizedBox(height: 16),

                // Listes de joueurs par position
                if (goalkeepers.isNotEmpty) ...[
                  _buildPositionHeader(
                    'Goalkeepers',
                    Icons.sports_handball,
                    Colors.orange,
                  ),
                  ...goalkeepers.map((player) => _buildPlayerCard(player)),
                ],

                if (defenders.isNotEmpty) ...[
                  _buildPositionHeader('Defenders', Icons.shield, Colors.blue),
                  ...defenders.map((player) => _buildPlayerCard(player)),
                ],

                if (midfielders.isNotEmpty) ...[
                  _buildPositionHeader(
                    'Midfielders',
                    Icons.center_focus_strong,
                    Colors.green,
                  ),
                  ...midfielders.map((player) => _buildPlayerCard(player)),
                ],

                if (forwards.isNotEmpty) ...[
                  _buildPositionHeader(
                    'Forwards',
                    Icons.trending_up,
                    Colors.red,
                  ),
                  ...forwards.map((player) => _buildPlayerCard(player)),
                ],

                if (others.isNotEmpty) ...[
                  _buildPositionHeader(
                    'Squad Players',
                    Icons.group,
                    Colors.purple,
                  ),
                  ...others.map((player) => _buildPlayerCard(player)),
                ],

                // Si aucun tri par position n'a fonctionné, afficher tous les joueurs
                if (goalkeepers.isEmpty &&
                    defenders.isEmpty &&
                    midfielders.isEmpty &&
                    forwards.isEmpty) ...[
                  _buildPositionHeader(
                    'Team Squad',
                    Icons.group,
                    Colors.blueGrey,
                  ),
                  ...athletes.map((player) => _buildPlayerCard(player)),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPositionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Athlete player) {
    final age = _calculateAge(player.dateOfBirth);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPlayerDetails(player),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Player avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: Text(
                  player.fullName.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Age: $age',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.flag, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          player.country,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Player stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '${player.stats.goals} goals',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.stats.appearances} apps',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateAge(String dateOfBirth) {
    if (dateOfBirth == 'Unknown') return 0;

    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  void _showPlayerDetails(Athlete player) {
    // Implement player details modal or navigation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Player header
                      Center(
                        child: Text(
                          player.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Player details
                      // Add more details here
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team record card
          TeamStatCard(
            title: 'Season Record',
            stats: [
              StatRow(
                label: 'Wins',
                value: '${_teamStats['wins'] ?? 0}',
                color: Colors.green,
              ),
              StatRow(
                label: 'Draws',
                value: '${_teamStats['draws'] ?? 0}',
                color: Colors.amber,
              ),
              StatRow(
                label: 'Losses',
                value: '${_teamStats['losses'] ?? 0}',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goals card
          TeamStatCard(
            title: 'Goal Statistics',
            stats: [
              StatRow(
                label: 'Goals For',
                value: '${_teamStats['goalsFor'] ?? 0}',
                color: Colors.blue,
              ),
              StatRow(
                label: 'Goals Against',
                value: '${_teamStats['goalsAgainst'] ?? 0}',
                color: Colors.orange,
              ),
              StatRow(
                label: 'Goal Difference',
                value:
                    '${((_teamStats['goalsFor'] ?? 0) - (_teamStats['goalsAgainst'] ?? 0))}',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Last matches
          LastMatches(formString: _teamStats['form']?.toString() ?? 'WDLWD'),

          // Add more stat widgets as needed
        ],
      ),
    );
  }
}
