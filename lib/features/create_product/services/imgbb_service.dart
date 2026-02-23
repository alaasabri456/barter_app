import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../config/api_config.dart';

class ImgbbService {
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final uri = Uri.parse('https://api.imgbb.com/1/upload');

      final response = await http.post(
        uri,
        body: {
          'key': ApiConfig.imgbbApiKey,
          'image': base64Image,
          'name': path.basename(imageFile.path),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<XFile> imageFiles,
      {Function(bool)? onLoadingStateChanged}) async {
    onLoadingStateChanged?.call(true);
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    onLoadingStateChanged?.call(false);
    return uploadedUrls;
  }
}
