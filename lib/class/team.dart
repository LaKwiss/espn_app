import 'package:flutter/material.dart';

class Team {
  final String id;
  final String name;
  final String shortName;
  final IconData? icon;

  late final List<String> _nameParts;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.icon,
  }) {
    _nameParts = name.split(' ');
  }

  String get firstName => _nameParts.isNotEmpty ? _nameParts.first : '';
  String get secondName =>
      _nameParts.length > 1 ? _nameParts.sublist(1).join(' ') : '';
}
