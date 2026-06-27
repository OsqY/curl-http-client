import 'dart:convert';
import 'dart:typed_data';

/// Substitutes `{{variableName}}` in [input] using values from [variables].
String substituteVariables(
  String input,
  Map<String, String> variables,
) {
  final regex = RegExp(r'\{\{(\s*[a-zA-Z_][a-zA-Z0-9_]*\s*)\}\}');
  return input.replaceAllMapped(regex, (match) {
    final name = match.group(1)!.trim();
    return variables[name] ?? match.group(0)!;
  });
}

/// Substitutes variables in a URL, headers, query params, and body content.
Map<String, String> substituteInHeaders(
  Map<String, String> headers,
  Map<String, String> variables,
) {
  return headers.map((k, v) =>
      MapEntry(substituteVariables(k, variables), substituteVariables(v, variables)));
}

String substituteInUrl(String url, Map<String, String> variables) =>
    substituteVariables(url, variables);

Map<String, String> substituteInQueryParams(
  Map<String, String> params,
  Map<String, String> variables,
) {
  return params.map((k, v) =>
      MapEntry(substituteVariables(k, variables), substituteVariables(v, variables)));
}

String? substituteInBody(String? body, Map<String, String> variables) =>
    body == null ? null : substituteVariables(body, variables);

/// Returns the best text encoding for the response body.
String? decodeBody(Uint8List bytes, Map<String, String> headers) {
  final contentType = headers['content-type']?.toLowerCase() ?? '';
  if (contentType.contains('charset=')) {
    final charset = RegExp(r'charset=([^;]+)').firstMatch(contentType)?.group(1)?.trim();
    try {
      if (charset != null) return Encoding.getByName(charset)?.decode(bytes);
    } catch (_) {}
  }
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return null;
  }
}

/// Formats a number of bytes as human-readable string.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

/// Slugifies a string for filesystem use.
String slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
}
