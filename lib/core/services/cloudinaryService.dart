import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'dtjscibjc';
  static const _uploadPreset = 'CartagenaApp';
  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Sube una imagen a Cloudinary y retorna la URL segura
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resStream = await response.stream.bytesToString();
        final data = json.decode(resStream);
        return data['secure_url']; // ← URL que puedes guardar en Firestore
      } else {
        debugPrint('❌ Error al subir imagen: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error al subir imagen a Cloudinary: $e');
      return null;
    }
  }
}
