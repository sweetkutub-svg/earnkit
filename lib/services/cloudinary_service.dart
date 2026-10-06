import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // TODO: apna Cloudinary cloud name aur unsigned preset daalo
  static const String _cloudName = 'efpfnvt0';
  static const String _uploadPreset = 'earnkit_unsigned';

  Future<String?> uploadImage(String filePath) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}