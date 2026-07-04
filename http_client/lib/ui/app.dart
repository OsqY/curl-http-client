import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/screens/main_screen.dart';
import 'package:http_client/ui/theme/app_theme.dart';

class HttpClientApp extends ConsumerWidget {
  const HttpClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorSetProvider);
    final theme = buildAppTheme(colors);

    return MaterialApp(
      title: 'HTTP Client',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const MainScreen(),
    );
  }
}
