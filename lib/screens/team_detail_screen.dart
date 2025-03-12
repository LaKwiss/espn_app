import 'package:espn_app/models/player_position.dart';
import 'package:espn_app/screens/soccer_field_painter.dart';
import 'package:espn_app/widgets/last_matches.dart';
import 'package:espn_app/widgets/player_circle.dart';
import 'package:espn_app/widgets/stat_row.dart';
import 'package:espn_app/widgets/team_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/models/athlete.dart';
import 'package:espn_app/models/stats.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/league.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/club_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _formation = '';
  Map<String, dynamic> _teamStats = {};

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
      // Fetch team data from API
      final response = await http.get(
        Uri.parse(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/esp.1/seasons/2024/teams/${widget.team.id}',
        ),
      );

      if (response.statusCode == 200) {
        final teamData = json.decode(response.body);

        // Extract data
        setState(() {
          _isLoading = false;
          _formation = teamData['formation'] ?? '4-3-3';
          _teamStats = {
            'position': teamData['standingSummary'] ?? '5th',
            'wins':
                teamData['record']?['items']?[0]?['stats']?[0]?['value'] ?? 10,
            'draws':
                teamData['record']?['items']?[0]?['stats']?[1]?['value'] ?? 5,
            'losses':
                teamData['record']?['items']?[0]?['stats']?[2]?['value'] ?? 3,
            'goalsFor':
                teamData['record']?['items']?[0]?['stats']?[4]?['value'] ?? 35,
            'goalsAgainst':
                teamData['record']?['items']?[0]?['stats']?[5]?['value'] ?? 20,
            'points':
                teamData['record']?['items']?[0]?['stats']?[3]?['value'] ?? 35,
            'form': teamData['form'] ?? 'WDWLW',
          };

          // Get players (this would be done with another API call)
          _fetchPlayers();
        });
      } else {
        // If API call fails, use mock data
        setState(() {
          _isLoading = false;
          _formation = '4-3-3';
          _teamStats = {
            'position': '5th',
            'wins': 10,
            'draws': 5,
            'losses': 3,
            'goalsFor': 35,
            'goalsAgainst': 20,
            'points': 35,
            'form': 'WDWLW',
          };

          // Mock player data
          _fetchPlayers();
        });
      }
    } catch (error) {
      // Default to mock data
      setState(() {
        _isLoading = false;
        _formation = '4-3-3';
        _teamStats = {
          'position': '5th',
          'wins': 10,
          'draws': 5,
          'losses': 3,
          'goalsFor': 35,
          'goalsAgainst': 20,
          'points': 35,
          'form': 'WDWLW',
        };

        // Mock player data
        _fetchPlayers();
      });
    }
  }

  Future<void> _fetchPlayers() async {
    try {
      // In a real app, this would be an API call to get players
      // For now, we'll use mock data

      // Mock players - you'll replace with actual API data
      setState(() {
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
                  id: int.parse(widget.team.id),
                  name: widget.team.name,
                  logo:
                      'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
                  country: 'Spain',
                  flag: 'https://a.espncdn.com/i/flags/20x13/esp.gif',
                  league: const League(
                    id: 1,
                    name: 'La Liga',
                    displayName: 'La Liga',
                    logo:
                        'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png',
                    country: 'Spain',
                    flag: 'https://a.espncdn.com/i/flags/20x13/esp.gif',
                    shortName: 'LIGA',
                  ),
                ),
          ),
        );
      });
    } catch (error) {
      // Use empty player list
      setState(() {
        _players = [];
      });
    }
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
                            child: Image.network(
                              'https://a.espncdn.com/i/teamlogos/soccer/500/${widget.team.id}.png',
                              width: 64,
                              height: 64,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.sports_soccer, size: 64),
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
                          ? const Center(child: CircularProgressIndicator())
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formation: $_formation',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Field markings
                CustomPaint(
                  size: const Size(double.infinity, 400),
                  painter: SoccerFieldPainter(),
                ),

                // Position the players based on formation
                ..._getPlayerPositions().map((position) {
                  return Positioned(
                    top: position.top,
                    left: position.left,
                    child: PlayerCircle(
                      players: _players,
                      playerIndex: position.playerIndex,
                      position: position.position,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PlayerPosition> _getPlayerPositions() {
    // This is a simplified example for a 4-3-3 formation
    // You'll need to adjust positions based on the actual formation
    final width =
        MediaQuery.of(context).size.width - 32; // Accounting for padding

    return [
      // Goalkeeper
      PlayerPosition(
        playerIndex: 0,
        position: 'GK',
        top: 350,
        left: width / 2 - 30,
      ),
      // Defenders
      PlayerPosition(playerIndex: 1, position: 'LB', top: 280, left: 20),
      PlayerPosition(
        playerIndex: 2,
        position: 'CB',
        top: 280,
        left: width / 3 - 20,
      ),
      PlayerPosition(
        playerIndex: 3,
        position: 'CB',
        top: 280,
        left: width * 2 / 3 - 40,
      ),
      PlayerPosition(
        playerIndex: 4,
        position: 'RB',
        top: 280,
        left: width - 80,
      ),
      // Midfielders
      PlayerPosition(
        playerIndex: 5,
        position: 'CM',
        top: 200,
        left: width / 4 - 20,
      ),
      PlayerPosition(
        playerIndex: 6,
        position: 'CM',
        top: 200,
        left: width / 2 - 30,
      ),
      PlayerPosition(
        playerIndex: 7,
        position: 'CM',
        top: 200,
        left: width * 3 / 4 - 40,
      ),
      // Forwards
      PlayerPosition(playerIndex: 8, position: 'LW', top: 100, left: 50),
      PlayerPosition(
        playerIndex: 9,
        position: 'ST',
        top: 80,
        left: width / 2 - 30,
      ),
      PlayerPosition(
        playerIndex: 10,
        position: 'RW',
        top: 100,
        left: width - 110,
      ),
    ];
  }

  Widget _buildPlayersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                player.fullName.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(player.fullName),
            subtitle: Text(
              'Age: ${_calculateAge(player.dateOfBirth)} | ${player.country}',
            ),
            trailing: Text(
              '${player.stats.goals} goals',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {
              // Show player details
              _showPlayerDetails(player);
            },
          ),
        );
      },
    );
  }

  int _calculateAge(String dateOfBirth) {
    final birthDate = DateTime.tryParse(dateOfBirth);
    if (birthDate == null) return 0;

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showPlayerDetails(Athlete player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      player.fullName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.fullName,
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Age: ${_calculateAge(player.dateOfBirth)} | ${player.country}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Statistics',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StatRow(label: 'Goals', value: player.stats.goals.toString()),
              StatRow(label: 'Assists', value: player.stats.assists.toString()),
              StatRow(
                label: 'Appearances',
                value: player.stats.appearances.toString(),
              ),
              StatRow(
                label: 'Minutes Played',
                value: player.stats.minutesPlayed.toString(),
              ),
              StatRow(
                label: 'Yellow Cards',
                value: player.stats.yellowCards.toString(),
              ),
              StatRow(
                label: 'Red Cards',
                value: player.stats.redCards.toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    // Convert form string to list (e.g., "WDWLW" -> ["W", "D", "W", "L", "W"])
    final formString = _teamStats['form'] ?? '';
    final formList = formString.split('');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Statistics',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TeamStatCard(
            label: 'Goals Scored',
            value: _teamStats['goalsFor']?.toString() ?? '34',
          ),
          TeamStatCard(
            label: 'Goals Conceded',
            value: _teamStats['goalsAgainst']?.toString() ?? '18',
          ),
          TeamStatCard(
            label: 'Wins',
            value: _teamStats['wins']?.toString() ?? '10',
          ),
          TeamStatCard(
            label: 'Draws',
            value: _teamStats['draws']?.toString() ?? '5',
          ),
          TeamStatCard(
            label: 'Losses',
            value: _teamStats['losses']?.toString() ?? '3',
          ),
          TeamStatCard(
            label: 'Points',
            value: _teamStats['points']?.toString() ?? '35',
          ),
          const SizedBox(height: 32),
          Text(
            'Last 5 Matches',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LastMatches(results: formList),
        ],
      ),
    );
  }
}
