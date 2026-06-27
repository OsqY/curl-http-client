import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:diff_match_patch/diff_match_patch.dart' show diff, cleanupSemantic, Diff, DIFF_DELETE, DIFF_INSERT, DIFF_EQUAL;
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
    final language = detectLanguage(contentType);

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
                  icon: const Icon(Icons.compare_arrows, size: 16),
                  tooltip: 'Compare with saved response',
                  onPressed: () => _compareResponse(context, response.bodyText ?? ''),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
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
                        _VirtualBody(
                          bodyText: bodyText,
                          contentType: contentType,
                          language: language,
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

  Future<void> _compareResponse(
    BuildContext context,
    String currentBody,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a saved response to compare',
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;

    final otherBody = await File(result.files.first.path!).readAsString();
    if (!context.mounted) return;

    final diffs = diff(otherBody, currentBody);
    cleanupSemantic(diffs);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Diff with ${result.files.first.name}'),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: _buildDiffText(diffs),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffText(List<Diff> diffs) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.fgDefault,
        ),
        children: diffs.map((diff) {
          final style = switch (diff.operation) {
            DIFF_INSERT => const TextStyle(
              backgroundColor: Color(0x4027AE60),
              color: Color(0xFF27AE60),
            ),
            DIFF_DELETE => const TextStyle(
              backgroundColor: Color(0x40E74C3C),
              color: Color(0xFFE74C3C),
              decoration: TextDecoration.lineThrough,
            ),
            DIFF_EQUAL => const TextStyle(color: AppColors.fgDefault),
            _ => const TextStyle(color: AppColors.fgDefault),
          };
          return TextSpan(text: diff.text, style: style);
        }).toList(),
      ),
    );
  }
}

// ---- Top-level helpers ----

/// Detects syntax highlighting language from content-type header.
String detectLanguage(String contentType) {
  if (contentType.contains('json')) return 'json';
  if (contentType.contains('xml')) return 'xml';
  if (contentType.contains('html')) return 'html';
  return 'plaintext';
}

/// Pretty-prints a response body for display.
String prettyBody(String body, String contentType) {
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

/// Virtualized body viewer that truncates large responses.
class _VirtualBody extends StatefulWidget {
  final String bodyText;
  final String contentType;
  final String language;

  const _VirtualBody({
    required this.bodyText,
    required this.contentType,
    required this.language,
  });

  @override
  State<_VirtualBody> createState() => _VirtualBodyState();
}

class _VirtualBodyState extends State<_VirtualBody> {
  bool _fullContent = false;

  @override
  Widget build(BuildContext context) {
    const threshold = 100 * 1024; // 100 KB
    const previewSize = 5 * 1024; // 5 KB preview

    final pretty = prettyBody(widget.bodyText, widget.contentType);
    final bytes = utf8.encode(pretty).length;

    if (bytes <= threshold || _fullContent) {
      return SingleChildScrollView(
        child: HighlightView(
          pretty,
          language: widget.language,
          theme: vs2015Theme,
          padding: const EdgeInsets.all(10),
          textStyle: const TextStyle(
              fontFamily: 'monospace', fontSize: 13),
        ),
      );
    }

    // Show truncated preview with load-full option.
    final preview = pretty.substring(0, min(pretty.length, previewSize));
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.bgNotice.withAlpha(40),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, size: 14),
              const SizedBox(width: 6),
              Text(
                'Large response: ${formatBytes(bytes)} — showing first ${formatBytes(previewSize)}',
                style: const TextStyle(fontSize: 11),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.unfold_more, size: 14),
                label: const Text('Show full', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _fullContent = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: HighlightView(
              preview,
              language: widget.language,
              theme: vs2015Theme,
              padding: const EdgeInsets.all(10),
              textStyle: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
