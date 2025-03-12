import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(String url) async {
    return await _client.get(Uri.parse(url));
  }

  Future<http.Response> post(String url, dynamic body) async {
    return await _client.post(
      Uri.parse(url),
      body: body,
      headers: {'Content-Type': 'application/json'},
    );
  }

  void dispose() {
    _client.close();
  }
}
