import 'dart:io';

import 'package:http_client/models/models.dart';

/// Stores and manages cookies per domain/path.
class CookieJar {
  final List<StoredCookie> _cookies;

  CookieJar({List<StoredCookie> cookies = const []})
    : _cookies = List.from(cookies);

  List<StoredCookie> get cookies => List.unmodifiable(_cookies);

  factory CookieJar.fromJson(List<dynamic> json) => CookieJar(
    cookies: json
        .map((e) => StoredCookie.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  List<Map<String, dynamic>> toJson() =>
      _cookies.map((e) => e.toJson()).toList();

  /// Returns cookies applicable to [uri].
  List<StoredCookie> cookiesFor(Uri uri) {
    return _cookies.where((cookie) {
      if (cookie.isExpired && cookie.expires != null) return false;
      if (!_domainMatches(uri.host, cookie.domain)) return false;
      if (!uri.path.startsWith(cookie.path)) return false;
      if (cookie.secure && uri.scheme != 'https') return false;
      return true;
    }).toList();
  }

  /// Parses Set-Cookie headers from an HTTP response and stores them.
  void storeFromResponse(Uri uri, HttpClientResponse response) {
    for (final setCookie in response.headers['set-cookie'] ?? []) {
      final cookie = _parseSetCookie(setCookie, uri.host);
      if (cookie != null) {
        _upsert(cookie);
      }
    }
  }

  void _upsert(StoredCookie cookie) {
    _cookies.removeWhere(
      (c) =>
          c.name == cookie.name &&
          c.domain == cookie.domain &&
          c.path == cookie.path,
    );
    _cookies.add(cookie);
  }

  StoredCookie? _parseSetCookie(String header, String defaultDomain) {
    final parts = header.split(';').map((p) => p.trim()).toList();
    if (parts.isEmpty) return null;

    final nameValue = parts.first.split('=');
    if (nameValue.length < 2) return null;
    final name = nameValue.first.trim();
    final value = nameValue.sublist(1).join('=').trim();

    var domain = defaultDomain;
    var path = '/';
    DateTime? expires;
    var httpOnly = false;
    var secure = false;
    String? sameSite;

    for (final part in parts.skip(1)) {
      final kv = part.split('=');
      final key = kv.first.trim().toLowerCase();
      final val = kv.length > 1 ? kv.sublist(1).join('=').trim() : '';
      switch (key) {
        case 'domain':
          domain = val.isEmpty ? defaultDomain : val;
          if (domain.startsWith('.')) domain = domain.substring(1);
        case 'path':
          path = val.isEmpty ? '/' : val;
        case 'expires':
          expires = _parseCookieExpires(val);
        case 'max-age':
          final seconds = int.tryParse(val);
          if (seconds != null) {
            expires = DateTime.now().add(Duration(seconds: seconds));
          }
        case 'httponly':
          httpOnly = true;
        case 'secure':
          secure = true;
        case 'samesite':
          sameSite = val;
      }
    }

    return StoredCookie(
      name: name,
      value: value,
      domain: domain,
      path: path,
      expires: expires,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: sameSite,
    );
  }

  DateTime? _parseCookieExpires(String value) {
    final formats = [
      'EEE, dd MMM yyyy HH:mm:ss GMT',
      'EEEE, dd-MMM-yy HH:mm:ss GMT',
      'EEE MMM dd HH:mm:ss yyyy',
    ];
    for (final _ in formats) {
      try {
        return HttpDate.parse(value);
      } catch (_) {}
    }
    return null;
  }

  bool _domainMatches(String host, String cookieDomain) {
    if (cookieDomain == host) return true;
    if (host.endsWith('.$cookieDomain')) return true;
    return false;
  }

  void clear() => _cookies.clear();
}
