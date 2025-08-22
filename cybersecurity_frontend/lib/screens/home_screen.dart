import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';

class HomeScreen extends StatefulWidget {
  final EncryptionService encryptionService;
  final String apiUrl;

  const HomeScreen({super.key, required this.encryptionService, required this.apiUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _result;
  bool _loading = false;

  late final ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(encryptionService: widget.encryptionService, apiUrl: widget.apiUrl);
  }

  void _checkMessage() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final res = await apiService.checkPhishing(_controller.text);
      setState(() {
        _result =
            "Phishing Score: ${res['score']}\nFlags: ${res['flags'].join(', ')}";
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = Colors.grey[200]!;

    if (_result != null) {
      if (_result!.toLowerCase().contains("phishing") ||
          _result!.toLowerCase().contains("flag")) {
        cardColor = Colors.red.shade100;
      } else {
        cardColor = Colors.green.shade100;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Banking Cybersecurity App")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: "Enter a message",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _checkMessage,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Check Message"),
            ),
            const SizedBox(height: 16),
            Card(
              color: cardColor,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _result ?? "Welcome to the app!\nEnter a message above to test phishing detection.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cardColor == Colors.red.shade100
                        ? Colors.red.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}