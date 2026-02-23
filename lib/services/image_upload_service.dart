// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../config/api_config.dart';

class ImageUploadService {
  static Future<String?> uploadImageToImgBB(XFile imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare request
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
        // Get the image URL from response
        final imageUrl = data['data']['url'];
        return imageUrl;
      } else {
        print('ImgBB upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      return null;
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages(
    List<XFile> imageFiles,
  ) async {
    final List<String> imageUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadImageToImgBB(imageFile);
      if (url != null) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }
}
