import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  final encrypt.Key key;
  final encrypt.IV iv;

  EncryptionService(String base64Key)
      : key = encrypt.Key.fromBase64(base64Key),
        iv = encrypt.IV.fromLength(16); // match backend IV if needed

  String encryptMessage(String message) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64;
  }

  String decryptMessage(String encryptedMessage) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
    return decrypted;
  }
}
