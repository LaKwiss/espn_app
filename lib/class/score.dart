import 'dart:convert';
import 'package:http/http.dart' as http;

class Score {
  final double value;

  Score({required this.value});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(value: json['value'] as double);
  }

  static Future<Score> fetchScore(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Score.fromJson(jsonData);
    } else {
      throw Exception('Erreur lors de la récupération du score');
    }
  }
}
