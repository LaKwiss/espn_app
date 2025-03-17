import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/providers/formation_async_notifier.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class FormationScreen extends ConsumerWidget {
  final String matchId;
  final String teamId;
  final String teamName;
  final String leagueId;

  const FormationScreen({
    Key? key,
    required this.matchId,
    required this.teamId,
    required this.teamName,
    required this.leagueId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observer les données de formation
    final formationAsync = ref.watch(formationAsyncProvider);

    // Clé de cache pour cette formation spécifique
    final cacheKey = '$matchId-$teamId';

    // Vérifier si nous avons déjà les données, sinon déclencher la récupération
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formationAsync.value == null ||
          !formationAsync.value!.formationCache.containsKey(cacheKey)) {
        ref
            .read(formationAsyncProvider.notifier)
            .fetchFormation(
              matchId: matchId,
              teamId: teamId,
              leagueId: leagueId,
            );

        ref
            .read(formationAsyncProvider.notifier)
            .fetchEnrichedPlayers(
              matchId: matchId,
              teamId: teamId,
              leagueId: leagueId,
            );
      }
    });

    return formationAsync.when(
      data: (state) {
        // Récupérer les données de formation et joueurs enrichis
        final formation = state.formationCache[cacheKey];
        final enrichedPlayers = state.enrichedPlayersCache[cacheKey] ?? [];

        // Si pas encore de données
        if (formation == null || enrichedPlayers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Séparer les titulaires et remplaçants
        final starters = enrichedPlayers.where((p) => p.isStarter).toList();
        final substitutes = enrichedPlayers.where((p) => !p.isStarter).toList();
        final substitutions = _createSubstitutions(enrichedPlayers);

        // Déterminer la couleur de l'équipe (peut être paramétré)
        final teamColor = _getTeamColor(teamId);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '$teamName - ${formation.formationName}',
              style: GoogleFonts.blackOpsOne(fontSize: 18),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Utiliser un ListView pour permettre le défilement
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // Section Titulaires - Formation sur le terrain
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFormationSection(
                  starters,
                  formation.formationName,
                  teamColor,
                  teamName,
                  context,
                ),
              ),

              // Section Remplaçants
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSubstitutesSection(
                  substitutes,
                  substitutions,
                  teamColor,
                  teamName,
                  context,
                ),
              ),

              // Ajouter un espace en bas pour éviter que le FAB ne cache du contenu
              const SizedBox(height: 80),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }

  // Widget pour afficher la formation tactique
  Widget _buildFormationSection(
    List<EnrichedPlayerEntry> starters,
    String formationName,
    Color teamColor,
    String teamName,
    BuildContext context,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'TITULAIRES',
                style: GoogleFonts.blackOpsOne(fontSize: 20, color: teamColor),
              ),
            ),
            const Divider(),
            // Formation visualizer avec taille adaptable
            SizedBox(
              height: 300, // Hauteur fixe pour éviter les overflows
              child: _buildFormationVisualizer(
                starters,
                formationName,
                teamColor,
                teamName,
                context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher la visualisation de formation
  Widget _buildFormationVisualizer(
    List<EnrichedPlayerEntry> starters,
    String formationName,
    Color teamColor,
    String teamName,
    BuildContext context,
  ) {
    // Utiliser un widget personnalisé pour dessiner la formation
    // Vous pouvez adapter celui-ci ou utiliser celui de votre projet
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Terrain de football stylisé
          Positioned.fill(child: CustomPaint(painter: SoccerFieldPainter())),

          // Joueurs positionnés selon la formation
          ...starters.map(
            (player) => _positionPlayerOnField(
              player,
              teamColor,
              context,
              starters.length,
              formationName,
            ),
          ),
        ],
      ),
    );
  }

  // Positionner un joueur sur le terrain selon ses coordonnées
  Widget _positionPlayerOnField(
    EnrichedPlayerEntry player,
    Color teamColor,
    BuildContext context,
    int totalPlayers,
    String formationName,
  ) {
    // Calculer la position à partir des coordonnées x, y (entre 0 et 1)
    // Si les coordonnées sont manquantes, les calculer à partir de formationPlace
    final (double x, double y) = _calculatePlayerPosition(
      player.formationPlace,
      totalPlayers,
      formationName,
    );

    return Positioned(
      left: x * MediaQuery.of(context).size.width * 0.8,
      top: y * 280, // La hauteur du conteneur est 300
      child: GestureDetector(
        onTap: () => _showPlayerDetails(context, player, teamColor),
        child: Column(
          children: [
            // Cercle avec numéro de maillot
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  player.jerseyNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Nom du joueur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getShortName(player.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher la section des remplaçants
  Widget _buildSubstitutesSection(
    List<EnrichedPlayerEntry> substitutes,
    List<Substitution> substitutions,
    Color teamColor,
    String teamName,
    BuildContext context,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REMPLAÇANTS',
              style: GoogleFonts.blackOpsOne(fontSize: 20, color: teamColor),
            ),
            const Divider(),
            // Liste des joueurs remplaçants
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  substitutes
                      .map(
                        (player) =>
                            _buildSubstituteChip(player, teamColor, context),
                      )
                      .toList(),
            ),

            // Afficher les substitutions si présentes
            if (substitutions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                'CHANGEMENTS',
                style: GoogleFonts.blackOpsOne(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...substitutions.map(
                (sub) => _buildSubstitutionItem(sub, teamColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget pour afficher un remplaçant
  Widget _buildSubstituteChip(
    EnrichedPlayerEntry player,
    Color teamColor,
    BuildContext context,
  ) {
    final isSubbedIn = player.subbedIn;

    return GestureDetector(
      onTap: () => _showPlayerDetails(context, player, teamColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color:
              isSubbedIn
                  ? teamColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSubbedIn ? teamColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isSubbedIn ? teamColor : Colors.grey,
              child: Text(
                player.jerseyNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSubbedIn ? teamColor : Colors.black87,
              ),
            ),
            // Indicateurs de cartons
            if (player.hasYellowCard)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 8,
                height: 12,
                color: Colors.yellow,
              ),
            if (player.hasRedCard)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 8,
                height: 12,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une substitution
  Widget _buildSubstitutionItem(Substitution sub, Color teamColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Indicateur minute
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sub.minute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Flèche d'entrée
          const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerIn.jerseyNumber} ${sub.playerIn is EnrichedPlayerEntry ? _getShortName((sub.playerIn as EnrichedPlayerEntry).displayName) : ''}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          // Flèche de sortie
          const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerOut.jerseyNumber} ${sub.playerOut is EnrichedPlayerEntry ? _getShortName((sub.playerOut as EnrichedPlayerEntry).displayName) : ''}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Afficher les détails d'un joueur dans une boîte de dialogue
  void _showPlayerDetails(
    BuildContext context,
    EnrichedPlayerEntry player,
    Color teamColor,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: teamColor,
                  child: Text(
                    player.jerseyNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Position: ${player.positionName}'),
                const SizedBox(height: 8),
                if (player.subbedOut) Text('Remplacé à la ${player.subMinute}'),
                if (player.subbedIn)
                  Text('Entré en jeu à la ${player.subMinute}'),
                const SizedBox(height: 8),
                if (player.hasYellowCard)
                  const Row(
                    children: [
                      Icon(Icons.square, color: Colors.yellow, size: 16),
                      SizedBox(width: 4),
                      Text('Carton jaune'),
                    ],
                  ),
                if (player.hasRedCard)
                  const Row(
                    children: [
                      Icon(Icons.square, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Carton rouge'),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  // Déterminer la couleur de l'équipe (à adapter selon votre logique)
  Color _getTeamColor(String teamId) {
    // Vous pouvez implémenter une logique plus sophistiquée basée sur l'ID
    // Pour simplifier, on utilise un hash code pour obtenir des couleurs stables
    final int hash = teamId.hashCode;

    // Liste de couleurs pour équipes
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    return colors[hash.abs() % colors.length];
  }

  // Calculer la position d'un joueur selon son rôle dans la formation
  (double, double) _calculatePlayerPosition(
    int formationPlace,
    int totalPlayers,
    String formationName,
  ) {
    // Par défaut, position centrée
    double x = 0.5;
    double y = 0.5;

    // Vérifier les formats standards
    if (totalPlayers != 11 || formationName.isEmpty) {
      y = formationPlace / totalPlayers.toDouble();
      return (x, y);
    }

    // Gardien (toujours formationPlace = 1)
    if (formationPlace == 1) {
      return (0.5, 0.9); // En bas du terrain
    }

    // Parser la formation (ex. "4-4-2" -> [4, 4, 2])
    final formationParts = formationName.split('-').map(int.parse).toList();
    if (formationParts.length < 2) {
      return (x, y); // Formation invalide, retour par défaut
    }

    // Calculer les seuils pour chaque ligne
    int defenders = formationParts[0]; // Défenseurs
    int midfielders = formationParts[1]; // Milieux
    int forwards =
        formationParts.length > 2 ? formationParts[2] : 0; // Attaquants

    // Ajuster si nécessaire pour correspondre au total de 10 joueurs (+ 1 gardien)
    if (defenders + midfielders + forwards != 10) {
      forwards = 10 - defenders - midfielders;
    }

    // Définir les limites de chaque zone
    int defenseEnd = 1 + defenders;
    int midfieldEnd = defenseEnd + midfielders;

    // Défenseurs
    if (formationPlace > 1 && formationPlace <= defenseEnd) {
      y = 0.7; // Près du gardien
      double spacing = 0.8 / (defenders + 1);
      x = 0.1 + (formationPlace - 1) * spacing;
    }
    // Milieux
    else if (formationPlace > defenseEnd && formationPlace <= midfieldEnd) {
      y = 0.4; // Zone médiane
      double spacing = 0.8 / (midfielders + 1);
      x = 0.1 + (formationPlace - defenseEnd) * spacing;
    }
    // Attaquants
    else if (formationPlace > midfieldEnd) {
      y = 0.1; // Zone offensive (haut du terrain)
      double spacing = 0.8 / (forwards + 1);
      x = 0.1 + (formationPlace - midfieldEnd) * spacing;
    }

    return (x, y);
  }

  // Créer une liste de substitutions à partir des joueurs
  List<Substitution> _createSubstitutions(List<EnrichedPlayerEntry> players) {
    final substitutions = <Substitution>[];

    for (var player in players) {
      if (player.subbedOut && player.replacementId != null) {
        final replacement = players.firstWhere(
          (p) => p.playerId == player.replacementId,
          orElse:
              () => EnrichedPlayerEntry.fromPlayerEntry(PlayerEntry.empty()),
        );

        if (replacement.playerId != 0) {
          substitutions.add(
            Substitution(
              playerOut: player,
              playerIn: replacement,
              minute: player.subMinute,
            ),
          );
        }
      }
    }

    return substitutions;
  }

  // Obtenir un nom court pour l'affichage
  String _getShortName(String fullName) {
    if (fullName.isEmpty) return '';

    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;

    // Utiliser le nom de famille, ou un nom court
    if (parts.last.length <= 8) {
      return parts.last;
    } else {
      return parts.last.substring(0, 6) + '...';
    }
  }
}

// Classe pour dessiner un terrain de football
class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Ligne médiane
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Rond central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 8,
      paint,
    );

    // Surface de réparation haut
    final penaltyAreaWidth = size.width * 0.5;
    final penaltyAreaHeight = size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        0,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Surface de réparation bas
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        size.height - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Point central
    final paintFill =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
