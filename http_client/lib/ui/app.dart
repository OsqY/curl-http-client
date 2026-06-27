import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/screens/main_screen.dart';
import 'package:http_client/ui/theme/app_theme.dart';

class HttpClientApp extends StatelessWidget {
  const HttpClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'HTTP Client',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const MainScreen(),
      ),
    );
  }
}
