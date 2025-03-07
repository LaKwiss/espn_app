import 'package:flutter/material.dart';
import 'package:espn_app/class/club.dart';

class Team {
  final String id;
  final String name;
  final String shortName;
  final IconData? icon;
  final Club? club; // Add club property to associate Team with its Club

  late final List<String> _nameParts;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.icon,
    this.club, // Make club optional in the constructor
  }) {
    _nameParts = name.split(' ');
  }

  String get firstName => _nameParts.isNotEmpty ? _nameParts.first : '';
  String get secondName =>
      _nameParts.length > 1 ? _nameParts.sublist(1).join(' ') : '';

  // Factory method to create a Team with associated Club
  factory Team.withClub({
    required String id,
    required String name,
    required String shortName,
    IconData? icon,
    required Club club,
  }) {
    return Team(
      id: id,
      name: name,
      shortName: shortName,
      icon: icon,
      club: club,
    );
  }
}
