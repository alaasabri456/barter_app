import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmV1Service {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // This is the service account information provided by the user
  static final _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "barter-30a05",
    "private_key_id": "71f487c1547272c05e1ac4d0b390626fb04db38d",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCeMBptLmrPC2uD\nEo1vLNJZUAbXNA5RB2UfQlXGicWVIwnzsiuT3uWd/8K0LaIr9BLnT31a4pPWuKhg\n3wlD96vZcjAOgpANV/YGeQC80TBAtbgx/MvPbpLoTQnuPaJHGWsah4Qq/kG9AWU9\na2+CegQrKG5y6JKrUyTcIQFsG3LiJ4qBZRiFSrvCrE3Gm1hN4ph1YVEBYp96+XlZ\n6ey2CbMc0DErbrmkQSXjCEF61otuJzAvO3/cmqDwvtdhSamzjKWSjOkJHoC3pRBA\ng5qrdhw2x4MjV4rFZ71exLphFKy0E85IRLsRThYaoryrPxICYjTzmejckRwS53Lv\nSHMe6yFxAgMBAAECggEAAP9t7T4flZh9eD1N19ONLJvK/UDCbdupdT/kfVz5WnJX\nAdrf+D3tzhgyxNLsXNFcbKnVUTVQaChwRHMnsm5tnrCgEblcWf8x6bLJ8Mbzglb7\nF1KgQPnSMqWowEBShZcJFEjiSiiiJsRrXG6w7H5jSBfoUXB621qKBxrssL9AE2HY\nrURaatcqp4l3OEp5v8Fg0rqGDh3ycXA6y7QNmsi2/J95gdNf2nPekon12fDD6t4I\nAHmbVC30XlqabGDoma1lkvYAoYQqhuLEoXDVXA1zyXfqp3efqqu6+Wx8gXZUmXYr\ny3dBjYHY1I2u/VHBJvhOc5y05g6ELMENAyEy2xXuQQKBgQDPIpDqHOfi2oyZzyCo\nHkDGHW1q/MnfS1wqcT0N6h+yo7HOMeqPvKQXCbFwP15MRqRS31qBiq8rn9+b7kGy\nZh1ARZj7DihiUlrsGm6qV7cy4nxfYmJE5xhAyAjNBrbRJ7p5sqZLjYdGahLlkWCE\nlzHqzplAm1X2da9wFmafKKYKEQKBgQDDgX2ZMXMHiYepludFmiYlkn5KGfX+kr/E\nJsaI+HXLUIBi8YnvpL8uVbgdPARLdUOfdNB4r2mIKwkEf5k0BHAXb25WeWw41pee\nt3uh+tbGsq/ahFPdQgC/JQp3VQydXFdQUcZeUjfHKJ5d8z6jQ7v9F9JvlM+Oaq8j\nK7yaHUNBYQKBgQDCGP36o4OXzHwcVT+gyligTUsPCjqRB6kiDGLN+yog18vyEExg\nzMBm5ipjqL3QdBHfpnTFFxP2qSV8lNLzPUUDyTQFbcrh95JD1LEG5pNBF4K8TxEO\nyA6uBcRZe4UskTHogEPcYI72qMd0X7o2BQg9o8NwCx+Oh9ESE6uuUQTmQQKBgAqZ\nXZbNkH/rG9i83qLuXX0R+RjJWYXIrO7Ub1UDq1cvcRZsI99DHj5D1Wx4UX9JxzXA\n3oB8egsw0hdVV5fzWaRbnS7A/HYEZEnthp1cfQJes5v0KpvHNUUnm+6mRL3PQMiQ\n9mEssetxL0zGoDG3vVxWS0lTVwFQlVghyeLNDVVhAoGAYniSxGhbo06YaEQ1H4Yf\n7KhE3c+BdqN712GzNKeO5fLAygnaHZ/Wke2vRAAvCdQO3ZhV2o9H2LsE7ubJ8z8T\n5XNhATmRe3LV+knYWpMDU/hHguj/oYbfcAAAN/eAIvD6hcnP7c3Tthnt2DMShblx\nL/08WE1D+awSSaeANQOM06E=\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@barter-30a05.iam.gserviceaccount.com",
    "client_id": "111725538542768915469",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40barter-30a05.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static Future<String> getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson(
      _serviceAccountCredentials,
    );
    final client = await clientViaServiceAccount(accountCredentials, _scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }
}
