import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/widgets/tactics_view.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';

class MatchContentToggle extends StatefulWidget {
  final Event event;
  final Team homeTeam;
  final Team awayTeam;
  final AsyncValue<List<MatchEvent>> eventsAsync;

  const MatchContentToggle({
    super.key,
    required this.event,
    required this.homeTeam,
    required this.awayTeam,
    required this.eventsAsync,
  });

  @override
  State<MatchContentToggle> createState() => _MatchContentToggleState();
}

class _MatchContentToggleState extends State<MatchContentToggle>
    with SingleTickerProviderStateMixin {
  bool _showTactics = false;
  late AnimationController _animationController;
  late Animation<Offset> _eventsSlideAnimation;
  late Animation<Offset> _tacticsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    _eventsSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _tacticsSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      if (_showTactics) {
        _animationController.reverse().then((_) {
          setState(() {
            _showTactics = false;
          });
        });
      } else {
        _showTactics = true;
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle bar
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
                  onTap: () {
                    if (_showTactics) _toggleView();
                  },
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
                  onTap: () {
                    if (!_showTactics) _toggleView();
                  },
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

        // Content with animation
        Container(
          height: 500,
          child: Stack(
            clipBehavior: Clip.none, // Allow content to overflow
            children: [
              // Events view
              SlideTransition(
                position: _eventsSlideAnimation,
                child: widget.eventsAsync.when(
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
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Erreur de chargement des événements: $error',
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),

              // Tactics view
              if (_showTactics)
                SlideTransition(
                  position: _tacticsSlideAnimation,
                  child: TacticsView(
                    event: widget.event,
                    homeTeam: widget.homeTeam,
                    awayTeam: widget.awayTeam,
                    onToggleView: _toggleView,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
