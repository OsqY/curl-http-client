import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:http_client/models/models.dart';

// ---------------------------------------------------------------------------
// ScriptContext — mutable context exposed to scripts
// ---------------------------------------------------------------------------

/// Read-only view of an [HttpRequest] exposed to scripts.
class ScriptRequestView {
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String? body;

  ScriptRequestView({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParams,
    this.body,
  });
}

/// Read-only view of an [HttpResponse] exposed to scripts.
class ScriptResponseView {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  ScriptResponseView({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

/// Mutable context passed through pre-request and post-response scripts.
class ScriptContext {
  /// Variables extracted from the active environment (mutable by scripts).
  final Map<String, String> variables;

  /// Read-only request view.
  final ScriptRequestView request;

  /// Optional response view (present only after execution).
  final ScriptResponseView? response;

  /// Assertion results (e.g. "PASS: status is 200" / "FAIL: body contains …").
  final List<String> assertions;

  /// Script runtime or compilation errors.
  final List<String> errors;

  ScriptContext({
    required this.variables,
    required this.request,
    this.response,
    List<String>? assertions,
    List<String>? errors,
  })  : assertions = assertions ?? [],
        errors = errors ?? [];
}

// ---------------------------------------------------------------------------
// ScriptingService
// ---------------------------------------------------------------------------

/// Evaluates user-supplied Dart snippets (pre-request / post-response) using
/// `dart_eval` with a Postman‑inspired `pm` API.
///
/// The injected script context provides the following names in scope:
///
///  * `variables` — a `Map<String, String>` the script can read and write to
///    persist values between pre-request and post-response phases.
///  * `request`   — a `Map<String, dynamic>` with keys `url`, `method`,
///    `headers` (Map), `queryParams` (Map), `body` (String?).
///  * `response`  — a `Map<String, dynamic>?` available only in post-response
///    scripts. Contains `statusCode` (int), `headers` (Map), `body` (String).
///  * `test(name, condition)` — function that records a PASS / FAIL assertion.
///
/// **Note**: Due to dart_eval limitations inside function/method calls,
/// `List.add()` is not available. Assertions and errors are accumulated via
/// string concatenation internally and split back into `List<String>`.
class ScriptingService {
  /// Run a pre‑request script.
  ///
  /// The script may read/write [variables] and read the request details.
  Future<ScriptContext> runPreRequest(
    String script,
    HttpRequest request,
    Map<String, String> variables,
  ) async {
    final reqView = _buildRequestView(request);

    final context = ScriptContext(
      variables: Map<String, String>.from(variables),
      request: reqView,
    );

    if (script.trim().isEmpty) return context;

    try {
      final result = _evaluateScript(
        script: script,
        variables: context.variables,
        requestUrl: reqView.url,
        requestMethod: reqView.method,
        requestHeaders: reqView.headers,
        requestQueryParams: reqView.queryParams,
        requestBody: reqView.body,
        responseStatusCode: null,
        responseHeaders: null,
        responseBody: null,
      );

      context.variables
        ..clear()
        ..addAll(Map<String, String>.from(result['variables'] as Map));
      context.errors.addAll(_splitLines(result['errors'] as String));
      context.assertions.addAll(_splitLines(result['assertions'] as String));
    } catch (e) {
      context.errors.add('Script error: $e');
    }

    return context;
  }

  /// Run a post‑response script.
  ///
  /// The script may read/write [variables] and inspect both the request and
  /// the received [response].
  Future<ScriptContext> runPostResponse(
    String script,
    HttpRequest request,
    HttpResponse response,
    Map<String, String> variables,
  ) async {
    final reqView = _buildRequestView(request);
    final resView = _buildResponseView(response);

    final context = ScriptContext(
      variables: Map<String, String>.from(variables),
      request: reqView,
      response: resView,
    );

    if (script.trim().isEmpty) return context;

    try {
      final result = _evaluateScript(
        script: script,
        variables: context.variables,
        requestUrl: reqView.url,
        requestMethod: reqView.method,
        requestHeaders: reqView.headers,
        requestQueryParams: reqView.queryParams,
        requestBody: reqView.body,
        responseStatusCode: resView.statusCode,
        responseHeaders: resView.headers,
        responseBody: resView.body,
      );

      context.variables
        ..clear()
        ..addAll(Map<String, String>.from(result['variables'] as Map));
      context.errors.addAll(_splitLines(result['errors'] as String));
      context.assertions.addAll(_splitLines(result['assertions'] as String));
    } catch (e) {
      context.errors.add('Script error: $e');
    }

    return context;
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  List<String> _splitLines(String s) {
    if (s.isEmpty) return const [];
    return s.split('\n');
  }

  ScriptRequestView _buildRequestView(HttpRequest req) {
    return ScriptRequestView(
      method: req.method.name,
      url: req.url,
      headers: {
        for (final h in req.headers.where((h) => h.enabled))
          h.key: h.value,
      },
      queryParams: {
        for (final q in req.queryParams.where((q) => q.enabled))
          q.key: q.value,
      },
      body: req.body.mode == BodyMode.raw && req.body.rawContent.isNotEmpty
          ? req.body.rawContent
          : null,
    );
  }

  ScriptResponseView _buildResponseView(HttpResponse res) {
    return ScriptResponseView(
      statusCode: res.statusCode,
      headers: Map<String, String>.from(res.headers),
      body: res.bodyText ?? '',
    );
  }

  /// Compile and evaluate the script with injected context.
  Map<String, dynamic> _evaluateScript({
    required String script,
    required Map<String, String> variables,
    required String requestUrl,
    required String requestMethod,
    required Map<String, String> requestHeaders,
    required Map<String, String> requestQueryParams,
    String? requestBody,
    int? responseStatusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
  }) {
    final source = _buildProgramSource(
      script: script,
      variables: variables,
      requestUrl: requestUrl,
      requestMethod: requestMethod,
      requestHeaders: requestHeaders,
      requestQueryParams: requestQueryParams,
      requestBody: requestBody,
      responseStatusCode: responseStatusCode,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
    );

    // The generated script returns a JSON-encoded string to avoid dart_eval's
    // partial reification of nested collection types.
    final raw = eval(source, function: 'execute');
    final decoded = jsonDecode(raw as String);
    return Map<String, dynamic>.from(decoded as Map);
  }

  static String _escape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll(r'$', r'\$');
  }

  /// Build the full dart_eval source wrapping context and user script.
  String _buildProgramSource({
    required String script,
    required Map<String, String> variables,
    required String requestUrl,
    required String requestMethod,
    required Map<String, String> requestHeaders,
    required Map<String, String> requestQueryParams,
    String? requestBody,
    int? responseStatusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
  }) {
    // Serialise maps for embedding in generated Dart source.
    String mapLit(Map<String, String> m) {
      if (m.isEmpty) return '<String, String>{}';
      return '<String, String>{\n        ${m.entries.map((e) => "'${_escape(e.key)}': '${_escape(e.value)}'").join(',\n        ')}}';
    }

    final varsLit = mapLit(variables);
    final headersLit = mapLit(requestHeaders);
    final queryLit = mapLit(requestQueryParams);
    final escapedBody =
        requestBody != null ? "'${_escape(requestBody)}'" : 'null';

    // Response block (pre-request has no response).
    final String responseBlock;
    if (responseStatusCode != null) {
      final respHeadersLit = mapLit(responseHeaders ?? {});
      final escapedRespBody =
          responseBody != null ? "'${_escape(responseBody)}'" : "''";
      responseBlock = '''
  final response = <String, dynamic>{
    'statusCode': $responseStatusCode,
    'headers': $respHeadersLit,
    'body': $escapedRespBody,
  };''';
    } else {
      responseBlock = '  final Map<String, dynamic>? response; response = null;';
    }

    return '''
import 'dart:convert';

String execute() {
  final variables = $varsLit;
  String _assertions = '';
  String _errors = '';

  final request = <String, dynamic>{
    'url': '${_escape(requestUrl)}',
    'method': '${_escape(requestMethod)}',
    'headers': $headersLit,
    'queryParams': $queryLit,
    'body': $escapedBody,
  };
$responseBlock

  // ---- helper: record assertion ----
  void test(String name, bool condition) {
    if (condition) {
      _assertions += 'PASS: ' + name + '\\n';
    } else {
      _assertions += 'FAIL: ' + name + '\\n';
    }
  }

  // ---- user script ----
  try {
    $script
  } catch (__e) {
    _errors += __e.toString() + '\\n';
  }
  // ---- end user script ----

  return jsonEncode(<String, dynamic>{
    'variables': variables,
    'errors': _errors,
    'assertions': _assertions,
  });
}
''';
  }
}
