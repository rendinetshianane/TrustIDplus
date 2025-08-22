import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/encryption_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // <-- needed for kIsWeb

late final EncryptionService encryptionService;
late final String apiUrl;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Load Fernet key
  final base64Key = dotenv.env['BASE64_FERNET_KEY'];
  if (base64Key == null || base64Key.isEmpty) {
    throw Exception("BASE64_FERNET_KEY not set in .env");
  }
  encryptionService = EncryptionService(base64Key);

  // Determine API URL automatically based on platform
  if (kIsWeb) {
    apiUrl = dotenv.env['API_URL_WEB']!;
  } else if (Platform.isAndroid) {
    apiUrl = dotenv.env['API_URL_ANDROID']!;
  } else if (Platform.isIOS) {
    apiUrl = dotenv.env['API_URL_IOS']!;
  } else {
    apiUrl = dotenv.env['API_URL_WEB']!;
  }

runApp(CyberSecurityApp(
    encryptionService: encryptionService,
    apiUrl: apiUrl,
  ));
}


class CyberSecurityApp extends StatelessWidget {
  final EncryptionService encryptionService;
  final String apiUrl;

  const CyberSecurityApp({super.key, required this.encryptionService, required this.apiUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(
        encryptionService: encryptionService,
        apiUrl: apiUrl,
      ),
      title: 'Banking Cybersecurity App',
    );
  }
}


