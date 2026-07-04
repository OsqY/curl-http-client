import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/widgets/sidebar_row.dart';

/// Request body editor supporting none, form-data, url-encoded, raw, and binary modes.
class BodyEditor extends ConsumerStatefulWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  BodyEditor({super.key, required this.body, required this.onChanged});

  @override
  ConsumerState<BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends ConsumerState<BodyEditor> {
  late TextEditingController _rawController;
  late TextEditingController _urlEncodedKeyController;
  late TextEditingController _urlEncodedValueController;

  @override
  void initState() {
    super.initState();
    _rawController = TextEditingController(text: widget.body.rawContent);
    _urlEncodedKeyController = TextEditingController();
    _urlEncodedValueController = TextEditingController();
  }

  @override
  void dispose() {
    _rawController.dispose();
    _urlEncodedKeyController.dispose();
    _urlEncodedValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorSetProvider);
    final body = widget.body;
    return Column(
      children: [
        DropdownButtonFormField<BodyMode>(
          initialValue: body.mode,
          key: ValueKey(body.mode),
          items: BodyMode.values
              .map(
                (m) => DropdownMenuItem(value: m, child: Text(m.displayName)),
              )
              .toList(),
          onChanged: (m) {
            if (m != null) widget.onChanged(body.copyWith(mode: m));
          },
        ),
        if (body.mode == BodyMode.raw) ...[
          DropdownButtonFormField<RawContentType>(
            initialValue: body.rawContentType,
            key: ValueKey(body.rawContentType),
            items: RawContentType.values
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
                )
                .toList(),
            onChanged: (t) {
              if (t != null) {
                widget.onChanged(body.copyWith(rawContentType: t));
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _rawController,
                maxLines: null,
                expands: true,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Body content',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    widget.onChanged(body.copyWith(rawContent: v)),
              ),
            ),
          ),
        ] else if (body.mode == BodyMode.formData ||
            body.mode == BodyMode.urlEncoded) ...[
          SidebarRow(
            leading: Icon(Icons.add, size: 16),
            title: Text('Add field', style: TextStyle(fontSize: 12)),
            onTap: () => widget.onChanged(
              body.copyWith(
                formData: [
                  ...body.formData,
                  KeyValuePair(key: '', value: ''),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: body.formData.length,
              itemBuilder: (context, index) {
                final field = body.formData[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: field.enabled,
                        onChanged: (v) {
                          final updated = [...body.formData];
                          updated[index] = field.copyWith(enabled: v ?? true);
                          widget.onChanged(body.copyWith(formData: updated));
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Key',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                          controller: TextEditingController(text: field.key),
                          onChanged: (v) {
                            final updated = [...body.formData];
                            updated[index] = field.copyWith(key: v);
                            widget.onChanged(body.copyWith(formData: updated));
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Value',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                          controller: TextEditingController(text: field.value),
                          onChanged: (v) {
                            final updated = [...body.formData];
                            updated[index] = field.copyWith(value: v);
                            widget.onChanged(body.copyWith(formData: updated));
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 14),
                        onPressed: () {
                          final updated = [...body.formData];
                          updated.removeAt(index);
                          widget.onChanged(body.copyWith(formData: updated));
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else if (body.mode == BodyMode.binary) ...[
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Binary body not yet supported',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Text(
                'No body',
                style: TextStyle(color: colors.textMuted),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
