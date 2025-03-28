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
}
