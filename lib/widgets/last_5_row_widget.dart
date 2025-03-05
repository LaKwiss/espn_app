import 'package:espn_app/providers/last_5_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Last5RowWidget extends ConsumerWidget {
  const Last5RowWidget(this.id, {super.key});

  final String id;

  /// Mappe le résultat (0, 1 ou 3) sur une couleur.
  /// Vous pouvez ajuster ces couleurs selon vos besoins.
  Container _mapResultToContainer(int result) {
    switch (result) {
      case 3:
        return Container(
          height: 16,
          width: 16,
          color: Colors.black,
        ); // Victoire
      case 1:
        return Container(
          height: 16,
          width: 16,
          color: Colors.black.withValues(alpha: 0.5),
        ); // Match nul
      case 0:
        return Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(border: Border.all(width: 1.0)),
        );
      default:
        return Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(border: Border.all(width: 1.0)),
        ); // Défaite
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last5Future = ref.read(last5Provider.notifier).get5last(id);

    return FutureBuilder<List<int>>(
      future: last5Future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final results = snapshot.data!;
          return Row(
            children:
                results.map((result) {
                  return Row(
                    children: [
                      _mapResultToContainer(result),
                      const SizedBox(width: 2), // Add space between containers
                    ],
                  );
                }).toList(),
          );
        } else {
          return const Text('Aucun résultat');
        }
      },
    );
  }
}
