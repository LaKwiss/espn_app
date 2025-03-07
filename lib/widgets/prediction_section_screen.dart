import 'package:espn_app/class/probability.dart';
import 'package:espn_app/class/team.dart';
import 'package:espn_app/screens/match_detail_screen.dart';
import 'package:espn_app/widgets/last_5_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PredictionSectionWidget extends StatelessWidget {
  const PredictionSectionWidget({
    super.key,
    required this.widget,
    required this.awayTeam,
    required this.homeTeam,
  });

  final MatchDetailScreen widget;
  final Team awayTeam;
  final Team homeTeam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section "Past Games"
          Row(
            children: [
              Text(
                'Past Games',
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.play_arrow, color: Colors.black, size: 32),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    homeTeam.shortName,
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 28,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Last5RowWidget(homeTeam.id),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Section "Away Team Rating"
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                awayTeam.shortName,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: Colors.black.withValues(alpha: 178),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Last5RowWidget(awayTeam.id),
            ],
          ),
          const SizedBox(height: 48),
          // Section Probabilités (affichage en texte)
          FutureBuilder<List<Probability>>(
            future: Future.wait([
              widget.event.probability.$3,
              widget.event.probability.$2,
              widget.event.probability.$1,
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading probabilities',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackOpsOne(fontSize: 24),
                );
              } else if (snapshot.hasData) {
                final probs = snapshot.data!;
                final awayPerc = (probs[0].value * 100).toStringAsFixed(0);
                final drawPerc = (probs[1].value * 100).toStringAsFixed(0);
                final homePerc = (probs[2].value * 100).toStringAsFixed(0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$awayPerc% ${awayTeam.shortName}',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$drawPerc% DRAW',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$homePerc% ${homeTeam.shortName}',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
          // Section Probabilités (représentation visuelle)
          FutureBuilder<List<Probability>>(
            future: Future.wait([
              widget.event.probability.$3,
              widget.event.probability.$2,
              widget.event.probability.$1,
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 32);
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading probabilities',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackOpsOne(fontSize: 24),
                );
              } else if (snapshot.hasData) {
                final probs = snapshot.data!;
                final int awayFlex = (probs[0].value * 100).round();
                final int drawFlex = (probs[1].value * 100).round();
                final int homeFlex = (probs[2].value * 100).round();
                return Row(
                  children: [
                    Expanded(
                      flex: awayFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: Colors.black.withValues(
                              alpha: probs[0].value,
                            ),
                          ),
                          Text(
                            '${awayTeam.shortName} $awayFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: drawFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: Colors.black.withValues(
                              alpha: probs[1].value,
                            ),
                          ),
                          Text(
                            'DRAW $drawFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: homeFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: Colors.black.withValues(
                              alpha: probs[2].value,
                            ),
                          ),
                          Text(
                            '${homeTeam.shortName} $homeFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
