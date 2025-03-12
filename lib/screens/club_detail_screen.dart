import 'package:espn_app/models/club.dart';
import 'package:espn_app/widgets/widgets.dart';

class ClubDetailScreen extends StatefulWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  bool _isLoading = true;
  late Map<String, dynamic> _clubDetails;

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  Future<void> _fetchClubData() async {
    // TODO: Replace with actual API call to get club details
    // This is mock data for UI demonstration

    // Simulate API call with a delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _clubDetails = {
        'foundedYear': '1899',
        'president': 'Joan Laporta',
        'stadium': 'Camp Nou',
        'capacity': '99,354',
        'nicknames': ['Barça', 'Blaugrana'],
        'website': 'www.fcbarcelona.com',
        'achievements': [
          {
            'competition': 'La Liga',
            'titles': 26,
            'years': ['2019', '2018', '2016', '2015', '2013', '...'],
          },
          {
            'competition': 'UEFA Champions League',
            'titles': 5,
            'years': ['2015', '2011', '2009', '2006', '1992'],
          },
          {
            'competition': 'Copa del Rey',
            'titles': 31,
            'years': ['2021', '2018', '2017', '2016', '2015', '...'],
          },
        ],
        'currentSeason': {
          'position': 2,
          'points': 68,
          'played': 30,
          'won': 21,
          'drawn': 5,
          'lost': 4,
          'goalsFor': 62,
          'goalsAgainst': 34,
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: CustomAppBar(
                        url: widget.club.logo,
                        backgroundColor: Colors.grey[100],
                        iconOrientation: 3,
                        onArrowButtonPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildClubHeader()),
                    SliverToBoxAdapter(child: _buildClubDetails()),
                    SliverToBoxAdapter(child: _buildCurrentSeasonSection()),
                    SliverToBoxAdapter(child: _buildAchievementsSection()),
                  ],
                ),
      ),
    );
  }

  Widget _buildClubHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.club.logo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 40,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.club.name,
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.network(
                          widget.club.flag,
                          width: 20,
                          height: 15,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const SizedBox(width: 20, height: 15),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.club.country,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Founded: ${_clubDetails['foundedYear']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                'President: ${_clubDetails['president']}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stadium, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                '${_clubDetails['stadium']} (${_clubDetails['capacity']})',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_clubDetails['nicknames'] != null)
            Wrap(
              spacing: 8,
              children:
                  (_clubDetails['nicknames'] as List).map<Widget>((nickname) {
                    return Chip(
                      label: Text(nickname),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClubDetails() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLUB PROFILE',
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 16),
          const Text(
            'FC Barcelona is a professional football club based in Barcelona, Catalonia, Spain, that competes in La Liga, the top flight of Spanish football.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'The club has traditionally played in blue and red stripes, leading to the nickname Blaugrana. Domestically, Barcelona has won 26 La Liga, 31 Copa del Rey, 13 Supercopa de España, 3 Copa Eva Duarte, and 2 Copa de la Liga titles, as well as being the record holder for the latter four competitions.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'In international club football, the club has won 20 European and worldwide titles.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              // TODO: Open club website
            },
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _clubDetails['website'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSeasonSection() {
    final currentSeason = _clubDetails['currentSeason'];
    if (currentSeason == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT SEASON',
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Position',
                currentSeason['position'].toString(),
                Colors.blue[700]!,
              ),
              _buildStatCard(
                'Points',
                currentSeason['points'].toString(),
                Colors.green[700]!,
              ),
              _buildStatCard(
                'Played',
                currentSeason['played'].toString(),
                Colors.orange[700]!,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard(
                'Won',
                currentSeason['won'].toString(),
                Colors.green[700]!,
              ),
              _buildStatCard(
                'Drawn',
                currentSeason['drawn'].toString(),
                Colors.orange[700]!,
              ),
              _buildStatCard(
                'Lost',
                currentSeason['lost'].toString(),
                Colors.red[700]!,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Goals For',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentSeason['goalsFor'].toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Goals Against',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentSeason['goalsAgainst'].toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _clubDetails['achievements'];
    if (achievements == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACHIEVEMENTS',
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 16),
          ...(achievements as List).map<Widget>((achievement) {
            return _buildAchievementCard(
              competition: achievement['competition'],
              titles: achievement['titles'],
              years: achievement['years'],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String competition,
    required int titles,
    required List<String> years,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  competition,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$titles titles',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  years.map<Widget>((year) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        year,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
