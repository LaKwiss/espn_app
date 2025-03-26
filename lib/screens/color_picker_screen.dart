import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class ColorPickerScreen extends ConsumerStatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  ConsumerState<ColorPickerScreen> createState() => _ColorState();
}

class _ColorState extends ConsumerState<ColorPickerScreen> {
  void _showColorPickerDialog(BuildContext context, {int? indexToUpdate}) {
    final isEditing = indexToUpdate != null;
    final initialColor =
        isEditing ? ref.read(colorsProvider)[indexToUpdate] : Colors.red;

    Color selectedColor = initialColor;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Edit color' : 'Add new color'),
            content: SingleChildScrollView(
              child: MaterialPicker(
                pickerColor: initialColor,
                onColorChanged: (color) {
                  selectedColor = color;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (isEditing) {
                    // Mettre à jour la couleur existante
                    ref
                        .read(colorsProvider.notifier)
                        .updateColor(indexToUpdate, selectedColor);
                  } else {
                    // Ajouter une nouvelle couleur
                    ref.read(colorsProvider.notifier).addColor(selectedColor);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir la liste des couleurs du provider
    final colors = ref.watch(colorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Picker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'COLORS',
              style: GoogleFonts.blackOpsOne(
                fontSize: 45,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      'Color #${index + 1}',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'HEX: ${_colorToHex(color)}',
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                        Text(
                          'RGB: ${color.red}, ${color.green}, ${color.blue}',
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit color',
                          onPressed:
                              () => _showColorPickerDialog(
                                context,
                                indexToUpdate: index,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete color',
                          onPressed: () {
                            ref
                                .read(colorsProvider.notifier)
                                .deleteColor(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showColorPickerDialog(context),
        tooltip: 'Add new color',
        child: const Icon(Icons.add),
      ),
    );
  }
}
