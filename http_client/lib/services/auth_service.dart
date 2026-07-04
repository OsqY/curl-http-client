import 'dart:convert';
import 'dart:io';

import 'package:http_client/models/models.dart';

/// Handles OAuth2 client-credentials token fetching.
class AuthService {
  /// Returns an access token for [oauth2], fetching/refreshing if necessary.
  Future<String?> getAccessToken(OAuth2Auth oauth2) async {
    if (oauth2.accessToken != null && !oauth2.isExpired) {
      return oauth2.accessToken;
    }

    final uri = Uri.parse(oauth2.tokenUrl);
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      final credentials = base64Encode(
        utf8.encode('${oauth2.clientId}:${oauth2.clientSecret}'),
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Basic $credentials',
      );

      final bodyParts = <String>[
        'grant_type=client_credentials',
        if (oauth2.scope.isNotEmpty)
          'scope=${Uri.encodeComponent(oauth2.scope)}',
      ];
      request.write(bodyParts.join('&'));

      final response = await request.close();
      final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
      final text = utf8.decode(bytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(text) as Map<String, dynamic>;
        final token = json['access_token'] as String?;
        if (token != null) {
          // Return updated auth with token and expiry.
          return token;
        }
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// Computes the expiry DateTime from an expires_in seconds value.
  DateTime? expiryFromSeconds(int? seconds) =>
      seconds == null ? null : DateTime.now().add(Duration(seconds: seconds));
}
