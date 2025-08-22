import 'dart:convert';
import 'package:http/http.dart' as http;
import 'encryption_service.dart';

class ApiService {
  final EncryptionService encryptionService;
  final String apiUrl;

  ApiService({required this.encryptionService, required this.apiUrl});

  Future<Map<String, dynamic>> checkPhishing(String message) async {
    // Encrypt message before sending
    final encryptedMessage = encryptionService.encryptMessage(message);

    final response = await http.post(
      Uri.parse('$apiUrl/phishing'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': encryptedMessage}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Decrypt response if backend returns 'encrypted'
      if (data.containsKey('encrypted')) {
        final decrypted = encryptionService.decryptMessage(data['encrypted']);
        return jsonDecode(decrypted);
      }

      return data;
    } else {
      throw Exception('Failed to fetch: ${response.statusCode}');
    }
  }
}