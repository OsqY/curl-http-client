import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/app.dart';

void main() {
  runApp(const ProviderScope(child: HttpClientApp()));
}
