import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/providers/app_state.dart';

/// Pre-request and post-response script editor.
class ScriptsEditor extends ConsumerStatefulWidget {
  final RequestScripts scripts;
  final ValueChanged<RequestScripts> onChanged;

  ScriptsEditor({super.key, required this.scripts, required this.onChanged});

  @override
  ConsumerState<ScriptsEditor> createState() => _ScriptsEditorState();
}

class _ScriptsEditorState extends ConsumerState<ScriptsEditor> {
  late TextEditingController _preController;
  late TextEditingController _postController;

  @override
  void initState() {
    super.initState();
    _preController = TextEditingController(text: widget.scripts.preRequest);
    _postController = TextEditingController(text: widget.scripts.postResponse);
  }

  @override
  void didUpdateWidget(ScriptsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scripts.preRequest != widget.scripts.preRequest) {
      _preController.text = widget.scripts.preRequest;
    }
    if (oldWidget.scripts.postResponse != widget.scripts.postResponse) {
      _postController.text = widget.scripts.postResponse;
    }
  }

  @override
  void dispose() {
    _preController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorSetProvider);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-request Script',
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _preController,
              maxLines: null,
              expands: true,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Dart code run before each request',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.scripts.copyWith(preRequest: v)),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Post-response Script',
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _postController,
              maxLines: null,
              expands: true,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Dart code run after receiving the response',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.scripts.copyWith(postResponse: v)),
            ),
          ),
        ],
      ),
    );
  }
}
