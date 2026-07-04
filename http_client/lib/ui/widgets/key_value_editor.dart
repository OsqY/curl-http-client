import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/widgets/sidebar_row.dart';

/// Editable list of key-value pairs for headers and query parameters.
class KeyValueEditor extends ConsumerStatefulWidget {
  final List<KeyValuePair> items;
  final ValueChanged<List<KeyValuePair>> onChanged;

  KeyValueEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  ConsumerState<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends ConsumerState<KeyValueEditor> {
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, TextEditingController> _valueControllers = {};

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getKeyController(int index, String text) {
    if (!_keyControllers.containsKey(index)) {
      _keyControllers[index] = TextEditingController(text: text);
    }
    return _keyControllers[index]!;
  }

  TextEditingController _getValueController(int index, String text) {
    if (!_valueControllers.containsKey(index)) {
      _valueControllers[index] = TextEditingController(text: text);
    }
    return _valueControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorSetProvider);
    final rows = widget.items.toList();
    return Column(
      children: [
        SidebarRow(
          leading: Icon(Icons.add, size: 16),
          title: Text('Add', style: TextStyle(fontSize: 12)),
          onTap: () => widget.onChanged([
            ...rows,
            KeyValuePair(key: '', value: ''),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.enabled,
                      onChanged: (v) {
                        rows[index] = item.copyWith(enabled: v ?? true);
                        widget.onChanged(rows);
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
                        controller: _getKeyController(index, item.key),
                        onChanged: (v) => rows[index] = item.copyWith(key: v),
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
                        controller: _getValueController(index, item.value),
                        onChanged: (v) => rows[index] = item.copyWith(value: v),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 14),
                      onPressed: () {
                        _keyControllers.remove(index)?.dispose();
                        _valueControllers.remove(index)?.dispose();
                        rows.removeAt(index);
                        widget.onChanged(rows);
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
      ],
    );
  }
}
