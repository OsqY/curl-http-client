import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/widgets.dart';
import 'package:http_client/utils/formatting.dart';
import 'package:http_client/utils/utils.dart';

/// Displays the HTTP response: status bar, body syntax-highlighted, headers.
class ResponsePanel extends ConsumerWidget {
  const ResponsePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final response = ref.watch(responseProvider);
    final error = ref.watch(executionErrorProvider);
    final isSending = ref.watch(isSendingProvider);
    final scriptOutput = ref.watch(scriptOutputProvider);

    if (isSending) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error,
            style: const TextStyle(color: AppColors.bgDanger, fontSize: 13)),
      );
    }

    if (response == null) {
      return const Center(
        child: Text('Send a request to see the response',
            style: TextStyle(color: AppColors.fgMuted, fontSize: 13)),
      );
    }

    final bodyText = response.bodyText ?? '<binary>';
    final contentType =
        response.headers['content-type']?.toLowerCase() ?? '';
    final language = _detectLanguage(contentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status bar
        Container(
          color: AppColors.paneHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              StatusTag(statusCode: response.statusCode),
              const SizedBox(width: 12),
              Text('${response.durationMs} ms',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.paneHeaderFg)),
              const SizedBox(width: 12),
              Text(formatBytes(response.sizeBytes),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.paneHeaderFg)),
              const Spacer(),
              ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.save, size: 16),
                  tooltip: 'Save response',
                  onPressed: () => _saveResponse(context, response),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ],
          ),
        ),
        if (scriptOutput != null)
          Container(
            width: double.infinity,
            color: AppColors.paneHeaderBg,
            padding: const EdgeInsets.all(8),
            child: Text(scriptOutput,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.fgMuted)),
          ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Body'), Tab(text: 'Headers')]),
                Expanded(
                  child: Container(
                    color: AppColors.paneBg,
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: HighlightView(
                            _prettyBody(bodyText, contentType),
                            language: language,
                            theme: vs2015Theme,
                            padding: const EdgeInsets.all(10),
                            textStyle: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                        ListView.builder(
                          itemCount: response.headers.length,
                          itemBuilder: (context, index) {
                            final entry =
                                response.headers.entries.elementAt(index);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: AppColors.border, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(entry.key,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: AppColors.fgMuted)),
                                  ),
                                  Expanded(
                                    child: Text(entry.value,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _detectLanguage(String contentType) {
    if (contentType.contains('json')) return 'json';
    if (contentType.contains('xml')) return 'xml';
    if (contentType.contains('html')) return 'html';
    return 'plaintext';
  }

  String _prettyBody(String body, String contentType) {
    if (contentType.contains('json')) {
      try {
        return prettyJson(jsonDecode(body));
      } catch (_) {}
    }
    if (contentType.contains('xml')) {
      return prettyXml(body);
    }
    return body;
  }

  Future<void> _saveResponse(
      BuildContext context, HttpResponse response) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save response',
      fileName: 'response.txt',
    );
    if (path != null) {
      await File(path).writeAsBytes(response.bodyBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response saved')),
        );
      }
    }
  }
}
