import 'dart:convert';

import 'package:http/http.dart' as http;

class LeaguePictureRepository {
  static Future<String> getUrlByLeagueCode(String code) async {
    final response = await http.get(
      Uri.parse(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$code',
      ),
    );
    final json = jsonDecode(response.body);
    return json['logos'][1]['href'] as String;
  }
}
