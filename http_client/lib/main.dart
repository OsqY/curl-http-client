import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/app.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final opts = WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(800, 600),
    title: 'HTTP Client',
    center: true,
  );
  await windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('  stack: ${details.stack}');
  };
  ErrorWidget.builder = (details) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'An unexpected error occurred:\n\n${details.exception}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  await runZonedGuarded(
    () async {
      runApp(const ProviderScope(child: HttpClientApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('  stack: $stack');
    },
  );
}
