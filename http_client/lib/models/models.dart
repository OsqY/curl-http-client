import 'dart:convert';
import 'dart:typed_data';

/// Supported HTTP methods.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  String get name => switch (this) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
    HttpMethod.head => 'HEAD',
    HttpMethod.options => 'OPTIONS',
  };

  static HttpMethod fromName(String name) {
    final lower = name.toLowerCase();
    return HttpMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => HttpMethod.get,
    );
  }
}

/// A single key-value parameter that can be enabled/disabled (headers, query params, form fields).
class KeyValuePair {
  final String key;
  final String value;
  final bool enabled;

  const KeyValuePair({
    required this.key,
    required this.value,
    this.enabled = true,
  });

  factory KeyValuePair.fromJson(Map<String, dynamic> json) => KeyValuePair(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'enabled': enabled,
  };

  KeyValuePair copyWith({String? key, String? value, bool? enabled}) =>
      KeyValuePair(
        key: key ?? this.key,
        value: value ?? this.value,
        enabled: enabled ?? this.enabled,
      );
}

/// Body content modes.
enum BodyMode {
  none,
  formData,
  urlEncoded,
  raw,
  binary;

  String get displayName => switch (this) {
    BodyMode.none => 'none',
    BodyMode.formData => 'form-data',
    BodyMode.urlEncoded => 'x-www-form-urlencoded',
    BodyMode.raw => 'raw',
    BodyMode.binary => 'binary',
  };

  static BodyMode fromName(String name) {
    final lower = name.toLowerCase();
    return BodyMode.values.firstWhere(
      (e) =>
          e.displayName.toLowerCase() == lower || e.name.toLowerCase() == lower,
      orElse: () => BodyMode.none,
    );
  }
}

/// Authentication configurations.
abstract class AuthConfig {
  const AuthConfig();
  String get type;
  Map<String, dynamic> toJson();
  AuthConfig copy();

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'bearer' => BearerAuth.fromJson(json),
      'basic' => BasicAuth.fromJson(json),
      'apiKey' => ApiKeyAuth.fromJson(json),
      'oauth2' => OAuth2Auth.fromJson(json),
      _ => const NoAuth(),
    };
  }
}

class NoAuth extends AuthConfig {
  const NoAuth();

  @override
  String get type => 'none';

  @override
  Map<String, dynamic> toJson() => {'type': type};

  @override
  AuthConfig copy() => const NoAuth();

  factory NoAuth.fromJson(Map<String, dynamic> json) => const NoAuth();
}

class BearerAuth extends AuthConfig {
  final String token;

  BearerAuth({required this.token});

  @override
  String get type => 'bearer';

  @override
  Map<String, dynamic> toJson() => {'type': type, 'token': token};

  @override
  AuthConfig copy() => BearerAuth(token: token);

  factory BearerAuth.fromJson(Map<String, dynamic> json) =>
      BearerAuth(token: json['token'] as String? ?? '');

  BearerAuth copyWith({String? token}) =>
      BearerAuth(token: token ?? this.token);
}

class BasicAuth extends AuthConfig {
  final String username;
  final String password;

  BasicAuth({required this.username, required this.password});

  @override
  String get type => 'basic';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'username': username,
    'password': password,
  };

  @override
  AuthConfig copy() => BasicAuth(username: username, password: password);

  factory BasicAuth.fromJson(Map<String, dynamic> json) => BasicAuth(
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
  );

  BasicAuth copyWith({String? username, String? password}) => BasicAuth(
    username: username ?? this.username,
    password: password ?? this.password,
  );
}

enum ApiKeyLocation { header, query }

class ApiKeyAuth extends AuthConfig {
  final String key;
  final String value;
  final ApiKeyLocation location;

  ApiKeyAuth({
    required this.key,
    required this.value,
    this.location = ApiKeyLocation.header,
  });

  @override
  String get type => 'apiKey';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'key': key,
    'value': value,
    'location': location.name,
  };

  @override
  AuthConfig copy() => ApiKeyAuth(key: key, value: value, location: location);

  factory ApiKeyAuth.fromJson(Map<String, dynamic> json) => ApiKeyAuth(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    location: ApiKeyLocation.values.firstWhere(
      (e) => e.name == (json['location'] as String? ?? 'header'),
      orElse: () => ApiKeyLocation.header,
    ),
  );

  ApiKeyAuth copyWith({String? key, String? value, ApiKeyLocation? location}) =>
      ApiKeyAuth(
        key: key ?? this.key,
        value: value ?? this.value,
        location: location ?? this.location,
      );
}

class OAuth2Auth extends AuthConfig {
  final String tokenUrl;
  final String clientId;
  final String clientSecret;
  final String scope;
  final String? accessToken;
  final DateTime? expiresAt;

  OAuth2Auth({
    required this.tokenUrl,
    required this.clientId,
    required this.clientSecret,
    this.scope = '',
    this.accessToken,
    this.expiresAt,
  });

  @override
  String get type => 'oauth2';

  bool get isExpired =>
      accessToken == null ||
      expiresAt == null ||
      DateTime.now().isAfter(expiresAt!);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'tokenUrl': tokenUrl,
    'clientId': clientId,
    'clientSecret': clientSecret,
    'scope': scope,
    if (accessToken != null) 'accessToken': accessToken,
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
  };

  @override
  AuthConfig copy() => OAuth2Auth(
    tokenUrl: tokenUrl,
    clientId: clientId,
    clientSecret: clientSecret,
    scope: scope,
    accessToken: accessToken,
    expiresAt: expiresAt,
  );

  factory OAuth2Auth.fromJson(Map<String, dynamic> json) => OAuth2Auth(
    tokenUrl: json['tokenUrl'] as String? ?? '',
    clientId: json['clientId'] as String? ?? '',
    clientSecret: json['clientSecret'] as String? ?? '',
    scope: json['scope'] as String? ?? '',
    accessToken: json['accessToken'] as String?,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
  );

  OAuth2Auth copyWith({
    String? tokenUrl,
    String? clientId,
    String? clientSecret,
    String? scope,
    String? accessToken,
    DateTime? expiresAt,
  }) => OAuth2Auth(
    tokenUrl: tokenUrl ?? this.tokenUrl,
    clientId: clientId ?? this.clientId,
    clientSecret: clientSecret ?? this.clientSecret,
    scope: scope ?? this.scope,
    accessToken: accessToken ?? this.accessToken,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}

/// Raw body content type.
enum RawContentType {
  json,
  xml,
  text;

  String get mime => switch (this) {
    RawContentType.json => 'application/json',
    RawContentType.xml => 'application/xml',
    RawContentType.text => 'text/plain',
  };

  String get displayName => switch (this) {
    RawContentType.json => 'JSON',
    RawContentType.xml => 'XML',
    RawContentType.text => 'Text',
  };

  static RawContentType fromMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.contains('json')) return RawContentType.json;
    if (lower.contains('xml')) return RawContentType.xml;
    return RawContentType.text;
  }
}

class RequestBody {
  final BodyMode mode;
  final String rawContent; // For raw mode.
  final RawContentType rawContentType;
  final List<KeyValuePair> formData; // For form-data / url-encoded.
  final String? binaryFilePath;

  const RequestBody({
    this.mode = BodyMode.none,
    this.rawContent = '',
    this.rawContentType = RawContentType.json,
    this.formData = const [],
    this.binaryFilePath,
  });

  factory RequestBody.fromJson(Map<String, dynamic> json) => RequestBody(
    mode: BodyMode.fromName(json['mode'] as String? ?? 'none'),
    rawContent: json['rawContent'] as String? ?? '',
    rawContentType: RawContentType.values.firstWhere(
      (e) => e.name == (json['rawContentType'] as String? ?? 'json'),
      orElse: () => RawContentType.json,
    ),
    formData: (json['formData'] as List<dynamic>? ?? [])
        .map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
        .toList(),
    binaryFilePath: json['binaryFilePath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode.displayName,
    'rawContent': rawContent,
    'rawContentType': rawContentType.name,
    'formData': formData.map((e) => e.toJson()).toList(),
    if (binaryFilePath != null) 'binaryFilePath': binaryFilePath,
  };

  RequestBody copyWith({
    BodyMode? mode,
    String? rawContent,
    RawContentType? rawContentType,
    List<KeyValuePair>? formData,
    String? binaryFilePath,
  }) => RequestBody(
    mode: mode ?? this.mode,
    rawContent: rawContent ?? this.rawContent,
    rawContentType: rawContentType ?? this.rawContentType,
    formData: formData ?? this.formData,
    binaryFilePath: binaryFilePath ?? this.binaryFilePath,
  );
}

/// Pre/post request scripts.
class RequestScripts {
  final String preRequest;
  final String postResponse;

  const RequestScripts({this.preRequest = '', this.postResponse = ''});

  factory RequestScripts.fromJson(Map<String, dynamic> json) => RequestScripts(
    preRequest: json['preRequest'] as String? ?? '',
    postResponse: json['postResponse'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'preRequest': preRequest,
    'postResponse': postResponse,
  };

  RequestScripts copyWith({String? preRequest, String? postResponse}) =>
      RequestScripts(
        preRequest: preRequest ?? this.preRequest,
        postResponse: postResponse ?? this.postResponse,
      );
}

/// A saved HTTP request.
class HttpRequest {
  final String id;
  final String name;
  final HttpMethod method;
  final String url;
  final List<KeyValuePair> headers;
  final List<KeyValuePair> queryParams;
  final RequestBody body;
  final AuthConfig auth;
  final RequestScripts scripts;
  final String? parentFolderId;
  final String? collectionId;

  const HttpRequest({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const [],
    this.queryParams = const [],
    this.body = const RequestBody(),
    this.auth = const NoAuth(),
    this.scripts = const RequestScripts(),
    this.parentFolderId,
    this.collectionId,
  });

  factory HttpRequest.fromJson(Map<String, dynamic> json) => HttpRequest(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Untitled',
    method: HttpMethod.fromName(json['method'] as String? ?? 'GET'),
    url: json['url'] as String? ?? '',
    headers: (json['headers'] as List<dynamic>? ?? [])
        .map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
        .toList(),
    queryParams: (json['queryParams'] as List<dynamic>? ?? [])
        .map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
        .toList(),
    body: json['body'] == null
        ? const RequestBody()
        : RequestBody.fromJson(json['body'] as Map<String, dynamic>),
    auth: json['auth'] == null
        ? const NoAuth()
        : AuthConfig.fromJson(json['auth'] as Map<String, dynamic>),
    scripts: json['scripts'] == null
        ? const RequestScripts()
        : RequestScripts.fromJson(json['scripts'] as Map<String, dynamic>),
    parentFolderId: json['parentFolderId'] as String?,
    collectionId: json['collectionId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'method': method.name,
    'url': url,
    'headers': headers.map((e) => e.toJson()).toList(),
    'queryParams': queryParams.map((e) => e.toJson()).toList(),
    'body': body.toJson(),
    'auth': auth.toJson(),
    'scripts': scripts.toJson(),
    if (parentFolderId != null) 'parentFolderId': parentFolderId,
    if (collectionId != null) 'collectionId': collectionId,
  };

  HttpRequest copyWith({
    String? id,
    String? name,
    HttpMethod? method,
    String? url,
    List<KeyValuePair>? headers,
    List<KeyValuePair>? queryParams,
    RequestBody? body,
    AuthConfig? auth,
    RequestScripts? scripts,
    String? parentFolderId,
    String? collectionId,
  }) => HttpRequest(
    id: id ?? this.id,
    name: name ?? this.name,
    method: method ?? this.method,
    url: url ?? this.url,
    headers: headers ?? this.headers,
    queryParams: queryParams ?? this.queryParams,
    body: body ?? this.body,
    auth: auth ?? this.auth,
    scripts: scripts ?? this.scripts,
    parentFolderId: parentFolderId ?? this.parentFolderId,
    collectionId: collectionId ?? this.collectionId,
  );

  static String generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000)).toString()}';
}

/// A folder inside a collection.
class RequestFolder {
  final String id;
  final String name;
  final String? parentFolderId;

  const RequestFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
  });

  factory RequestFolder.fromJson(Map<String, dynamic> json) => RequestFolder(
    id: json['id'] as String? ?? HttpRequest.generateId(),
    name: json['name'] as String? ?? 'Folder',
    parentFolderId: json['parentFolderId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (parentFolderId != null) 'parentFolderId': parentFolderId,
  };

  RequestFolder copyWith({String? id, String? name, String? parentFolderId}) =>
      RequestFolder(
        id: id ?? this.id,
        name: name ?? this.name,
        parentFolderId: parentFolderId ?? this.parentFolderId,
      );
}

/// A collection of requests and folders.
class RequestCollection {
  final String id;
  final String name;
  final List<RequestFolder> folders;
  final String? description;

  const RequestCollection({
    required this.id,
    required this.name,
    this.folders = const [],
    this.description,
  });

  factory RequestCollection.fromJson(Map<String, dynamic> json) =>
      RequestCollection(
        id: json['id'] as String? ?? HttpRequest.generateId(),
        name: json['name'] as String? ?? 'Collection',
        folders: (json['folders'] as List<dynamic>? ?? [])
            .map((e) => RequestFolder.fromJson(e as Map<String, dynamic>))
            .toList(),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'folders': folders.map((e) => e.toJson()).toList(),
    if (description != null) 'description': description,
  };

  RequestCollection copyWith({
    String? id,
    String? name,
    List<RequestFolder>? folders,
    String? description,
  }) => RequestCollection(
    id: id ?? this.id,
    name: name ?? this.name,
    folders: folders ?? this.folders,
    description: description ?? this.description,
  );
}

/// Environment variable.
class EnvironmentVariable {
  final String key;
  final String value;
  final bool secret;
  final bool enabled;

  const EnvironmentVariable({
    required this.key,
    required this.value,
    this.secret = false,
    this.enabled = true,
  });

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) =>
      EnvironmentVariable(
        key: json['key'] as String? ?? '',
        value: json['value'] as String? ?? '',
        secret: json['secret'] as bool? ?? false,
        enabled: json['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'secret': secret,
    'enabled': enabled,
  };

  EnvironmentVariable copyWith({
    String? key,
    String? value,
    bool? secret,
    bool? enabled,
  }) => EnvironmentVariable(
    key: key ?? this.key,
    value: value ?? this.value,
    secret: secret ?? this.secret,
    enabled: enabled ?? this.enabled,
  );
}

/// A named environment.
class Environment {
  final String id;
  final String name;
  final List<EnvironmentVariable> variables;

  const Environment({
    required this.id,
    required this.name,
    this.variables = const [],
  });

  factory Environment.fromJson(Map<String, dynamic> json) => Environment(
    id: json['id'] as String? ?? HttpRequest.generateId(),
    name: json['name'] as String? ?? 'Environment',
    variables: (json['variables'] as List<dynamic>? ?? [])
        .map((e) => EnvironmentVariable.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'variables': variables.map((e) => e.toJson()).toList(),
  };

  Environment copyWith({
    String? id,
    String? name,
    List<EnvironmentVariable>? variables,
  }) => Environment(
    id: id ?? this.id,
    name: name ?? this.name,
    variables: variables ?? this.variables,
  );
}

/// A recorded history entry.
class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final HttpRequest request;
  final int statusCode;
  final String statusText;
  final int durationMs;
  final int responseSizeBytes;
  final String? responseBodyPreview;
  final String? responseBodyPath; // Full response may be saved separately.

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.request,
    required this.statusCode,
    required this.statusText,
    required this.durationMs,
    required this.responseSizeBytes,
    this.responseBodyPreview,
    this.responseBodyPath,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String? ?? HttpRequest.generateId(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    request: HttpRequest.fromJson(json['request'] as Map<String, dynamic>),
    statusCode: json['statusCode'] as int? ?? 0,
    statusText: json['statusText'] as String? ?? '',
    durationMs: json['durationMs'] as int? ?? 0,
    responseSizeBytes: json['responseSizeBytes'] as int? ?? 0,
    responseBodyPreview: json['responseBodyPreview'] as String?,
    responseBodyPath: json['responseBodyPath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'request': request.toJson(),
    'statusCode': statusCode,
    'statusText': statusText,
    'durationMs': durationMs,
    'responseSizeBytes': responseSizeBytes,
    if (responseBodyPreview != null) 'responseBodyPreview': responseBodyPreview,
    if (responseBodyPath != null) 'responseBodyPath': responseBodyPath,
  };

  HistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    HttpRequest? request,
    int? statusCode,
    String? statusText,
    int? durationMs,
    int? responseSizeBytes,
    String? responseBodyPreview,
    String? responseBodyPath,
  }) => HistoryEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    request: request ?? this.request,
    statusCode: statusCode ?? this.statusCode,
    statusText: statusText ?? this.statusText,
    durationMs: durationMs ?? this.durationMs,
    responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
    responseBodyPreview: responseBodyPreview ?? this.responseBodyPreview,
    responseBodyPath: responseBodyPath ?? this.responseBodyPath,
  );
}

/// A single stored cookie.
class StoredCookie {
  final String name;
  final String value;
  final String domain;
  final String path;
  final DateTime? expires;
  final bool httpOnly;
  final bool secure;
  final String? sameSite;

  const StoredCookie({
    required this.name,
    required this.value,
    required this.domain,
    this.path = '/',
    this.expires,
    this.httpOnly = false,
    this.secure = false,
    this.sameSite,
  });

  factory StoredCookie.fromJson(Map<String, dynamic> json) => StoredCookie(
    name: json['name'] as String? ?? '',
    value: json['value'] as String? ?? '',
    domain: json['domain'] as String? ?? '',
    path: json['path'] as String? ?? '/',
    expires: json['expires'] == null
        ? null
        : DateTime.parse(json['expires'] as String),
    httpOnly: json['httpOnly'] as bool? ?? false,
    secure: json['secure'] as bool? ?? false,
    sameSite: json['sameSite'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'domain': domain,
    'path': path,
    if (expires != null) 'expires': expires!.toUtc().toIso8601String(),
    'httpOnly': httpOnly,
    'secure': secure,
    if (sameSite != null) 'sameSite': sameSite,
  };

  bool get isExpired => expires != null && DateTime.now().isAfter(expires!);

  StoredCookie copyWith({
    String? name,
    String? value,
    String? domain,
    String? path,
    DateTime? expires,
    bool? httpOnly,
    bool? secure,
    String? sameSite,
  }) => StoredCookie(
    name: name ?? this.name,
    value: value ?? this.value,
    domain: domain ?? this.domain,
    path: path ?? this.path,
    expires: expires ?? this.expires,
    httpOnly: httpOnly ?? this.httpOnly,
    secure: secure ?? this.secure,
    sameSite: sameSite ?? this.sameSite,
  );
}

/// Response from executing a request.
class HttpResponse {
  final int statusCode;
  final String statusText;
  final Map<String, String> headers;
  final Uint8List bodyBytes;
  final int durationMs;
  final String? error;
  final DateTime receivedAt;

  const HttpResponse({
    required this.statusCode,
    required this.statusText,
    required this.headers,
    required this.bodyBytes,
    required this.durationMs,
    this.error,
    required this.receivedAt,
  });

  String? get bodyText {
    try {
      return utf8.decode(bodyBytes);
    } catch (_) {
      return null;
    }
  }

  int get sizeBytes => bodyBytes.length;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
