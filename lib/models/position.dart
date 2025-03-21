import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final String id;
  final String name;
  final String abbreviation;

  const Position({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  @override
  List<Object?> get props => [id, name, abbreviation];

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
    );
  }

  static Position empty() {
    return Position(id: '', name: '', abbreviation: '');
  }

  static Position GK() {
    return Position(id: '1', name: 'Goalkeeper', abbreviation: 'GK');
  }

  static Position DF() {
    return Position(id: '2', name: 'Defender', abbreviation: 'DF');
  }

  static Position MF() {
    return Position(id: '3', name: 'Midfielder', abbreviation: 'MF');
  }

  static Position FW() {
    return Position(id: '4', name: 'Forward', abbreviation: 'FW');
  }
}
