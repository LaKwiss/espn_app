import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:espn_app/models/club.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final IconData? icon;
  final Club? club;

  late final List<String> _nameParts;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.icon,
    this.club,
  }) {
    _nameParts = name.split(' ');
  }

  String get firstName => _nameParts.isNotEmpty ? _nameParts.first : '';
  String get secondName =>
      _nameParts.length > 1 ? _nameParts.sublist(1).join(' ') : '';

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

  @override
  List<Object?> get props => [id, name, shortName, icon, club];

  @override
  bool? get stringify => true;
}
