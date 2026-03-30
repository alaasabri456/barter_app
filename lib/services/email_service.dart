import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_y0r58m9';
  static const String _templateId = 'template_ak01adh';
  static const String _userId = '6BwRbZayUrJsplB96';

  // Returns null if success, or the error message if failed.
  static Future<String?> sendOtpEmail({
    required String userEmail,
    required String otpCode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _userId,
          'template_params': {
            'email': userEmail,
            'otp': otpCode,
          }
        }),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        print('EmailJS Error: ${response.body}');
        return response.body;
      }
    } catch (e) {
      print('Failed to send email: $e');
      return e.toString();
    }
  }
}
