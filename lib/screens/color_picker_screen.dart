import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorPickerScreen extends ConsumerStatefulWidget {
  const ColorPickerScreen(this.colors, {super.key});

  final List<Color> colors;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ColorState();
}

class _ColorState extends ConsumerState<ColorPickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
