import 'package:flutter/material.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';

/// Pre-request and post-response script editor.
class ScriptsEditor extends StatefulWidget {
  final RequestScripts scripts;
  final ValueChanged<RequestScripts> onChanged;

  const ScriptsEditor({
    super.key,
    required this.scripts,
    required this.onChanged,
  });

  @override
  State<ScriptsEditor> createState() => _ScriptsEditorState();
}

class _ScriptsEditorState extends State<ScriptsEditor> {
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pre-request Script',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _preController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Dart code run before each request',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.scripts.copyWith(preRequest: v)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Post-response Script',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _postController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
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
