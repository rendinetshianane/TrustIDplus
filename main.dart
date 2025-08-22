import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const backendUrl = 'http://10.0.2.2:3000'; // Android emulator localhost

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TrustIDHome(),
    );
  }
}

class TrustIDHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TrustID App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: TrustIDForm()),
      ),
    );
  }
}

class TrustIDForm extends StatefulWidget {
  @override
  _TrustIDFormState createState() => _TrustIDFormState();
}

class _TrustIDFormState extends State<TrustIDForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _selectedFile;
  String _mediaType = 'face';
  String _idToken = '';
  bool _isUploading = false;

  final picker = ImagePicker();

  Future<void> registerUser() async {
    final url = Uri.parse('${MyApp.backendUrl}/register');
    final body = jsonEncode({
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
    });

    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);

    final data = jsonDecode(res.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Registered UID: ${data['uid']}')));
  }

  Future<void> loginUser() async {
    final url = Uri.parse('${MyApp.backendUrl}/login');
    final body = jsonEncode({
      'email': _emailController.text,
      'password': _passwordController.text,
    });

    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);
    final data = jsonDecode(res.body);
    _idToken = data['idToken'];
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Logged in successfully!')));
  }

  Future<void> pickFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
      });
    }
  }

  Future<void> uploadVerification() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    final bytes = await _selectedFile!.readAsBytes();
    final base64File = base64Encode(bytes);

    final url = Uri.parse('${MyApp.backendUrl}/verification/upload');
    final body = jsonEncode({
      'mediaBase64': base64File,
      'mediaType': _mediaType,
    });

    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_idToken',
          },
          body: body);

      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload ID: ${data['id']}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool obscure = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed,
      {Color? color, IconData? icon}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.teal,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : SizedBox(),
      label: Text(text, style: TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 5,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Register / Login',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                buildTextField('Name', _nameController, icon: Icons.person),
                buildTextField('Email', _emailController, icon: Icons.email),
                buildTextField('Password', _passwordController,
                    obscure: true, icon: Icons.lock),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: buildButton('Register', registerUser,
                            icon: Icons.app_registration)),
                    SizedBox(width: 10),
                    Expanded(
                        child: buildButton('Login', loginUser,
                            color: Colors.blueGrey, icon: Icons.login)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Card(
          elevation: 5,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Upload Verification',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                buildButton(
                    _selectedFile == null
                        ? 'Pick File'
                        : 'File Selected: ${_selectedFile!.path.split('/').last}',
                    pickFile,
                    color: Colors.deepPurple,
                    icon: Icons.file_upload),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _mediaType,
                  onChanged: (v) => setState(() => _mediaType = v!),
                  items: ['face', 'voice']
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
                SizedBox(height: 10),
                _isUploading
                    ? LinearProgressIndicator()
                    : buildButton('Upload', uploadVerification,
                    color: Colors.green, icon: Icons.cloud_upload),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
