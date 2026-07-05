import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:diff_match_patch/diff_match_patch.dart'
    show diff, cleanupSemantic, Diff, DIFF_DELETE, DIFF_INSERT, DIFF_EQUAL;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
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
    final colors = ref.watch(colorSetProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final response = ref.watch(responseProvider);
    final error = ref.watch(executionErrorProvider);
    final isSending = ref.watch(isSendingProvider);
    final scriptOutput = ref.watch(scriptOutputProvider);

    if (isSending) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error,
          style: TextStyle(color: colors.accent, fontSize: fontSize),
        ),
      );
    }

    if (response == null) {
      return Center(
        child: Text(
          'Send a request to see the response',
          style: TextStyle(color: colors.textMuted, fontSize: fontSize),
        ),
      );
    }

    final bodyText = response.bodyText ?? '<binary>';
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final language = detectLanguage(contentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status bar
        Container(
          color: colors.elevated,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              StatusTag(statusCode: response.statusCode),
              SizedBox(width: 12),
              Text(
                '${response.durationMs} ms',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              SizedBox(width: 12),
              Text(
                formatBytes(response.sizeBytes),
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              Spacer(),
              ClickCursor(
                child: IconButton(
                  icon: Icon(Icons.copy, size: 16),
                  tooltip: 'Copy response body',
                  onPressed: () {
                    final text = response.bodyText;
                    if (text != null) {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
              ClickCursor(
                child: IconButton(
                  icon: Icon(Icons.compare_arrows, size: 16),
                  tooltip: 'Compare with saved response',
                  onPressed: () =>
                      _compareResponse(context, response.bodyText ?? ''),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
              ClickCursor(
                child: IconButton(
                  icon: Icon(Icons.save, size: 16),
                  tooltip: 'Save response',
                  onPressed: () => _saveResponse(context, response),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ],
          ),
        ),
        if (scriptOutput != null)
          Container(
            width: double.infinity,
            color: colors.elevated,
            padding: const EdgeInsets.all(8),
            child: Text(
              scriptOutput,
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Formatted'),
                    Tab(text: 'Raw'),
                    Tab(text: 'Headers'),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: colors.bg,
                    child: TabBarView(
                      children: [
                        _VirtualBody(
                          colors: colors,
                          bodyText: bodyText,
                          contentType: contentType,
                          language: language,
                          fontSize: fontSize,
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.all(10),
                          child: SelectableText(
                            bodyText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: fontSize,
                              color: colors.text,
                            ),
                          ),
                        ),
                        ListView.builder(
                          itemCount: response.headers.length,
                          itemBuilder: (context, index) {
                            final entry = response.headers.entries.elementAt(
                              index,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: colors.border,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
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
    BuildContext context,
    HttpResponse response,
  ) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save response',
      fileName: 'response.txt',
    );
    if (path != null) {
      await File(path).writeAsBytes(response.bodyBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Response saved')));
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
            child: _buildDiffText(diffs, ColorSet.dark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffText(List<Diff> diffs, ColorSet colors) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: colors.text,
        ),
        children: diffs.map((diff) {
          final style = switch (diff.operation) {
            DIFF_INSERT => TextStyle(
              backgroundColor: colors.diffInsertBg,
              color: colors.diffInsert,
            ),
            DIFF_DELETE => TextStyle(
              backgroundColor: colors.diffDeleteBg,
              color: colors.diffDelete,
              decoration: TextDecoration.lineThrough,
            ),
            DIFF_EQUAL => TextStyle(color: colors.text),
            _ => TextStyle(color: colors.text),
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
  final ColorSet colors;
  final String bodyText;
  final String contentType;
  final String language;
  final double fontSize;

  const _VirtualBody({
    required this.colors,
    required this.bodyText,
    required this.contentType,
    required this.language,
    required this.fontSize,
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
        child: SelectionArea(
          child: Container(
            color: widget.colors.bg,
            child: HighlightView(
              pretty,
              language: widget.language,
              theme: widget.colors == ColorSet.light
                  ? sootLightSyntaxTheme(widget.colors)
                  : sootSyntaxTheme(widget.colors),
              padding: const EdgeInsets.all(10),
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
              ),
            ),
          ),
        ),
      );
    }

    // Show truncated preview with load-full option.
    final preview = pretty.substring(0, min(pretty.length, previewSize));
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: widget.colors.amber.withAlpha(40),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 14),
              SizedBox(width: 6),
              Text(
                'Large response: ${formatBytes(bytes)} — showing first ${formatBytes(previewSize)}',
                style: TextStyle(fontSize: 11),
              ),
              Spacer(),
              TextButton.icon(
                icon: Icon(Icons.unfold_more, size: 14),
                label: Text('Show full', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _fullContent = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SelectionArea(
              child: Container(
                color: widget.colors.surface,
                child: HighlightView(
                  preview,
                  language: widget.language,
                  theme: widget.colors == ColorSet.light
                      ? sootLightSyntaxTheme(widget.colors)
                      : sootSyntaxTheme(widget.colors),
                  padding: const EdgeInsets.all(10),
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.fontSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
