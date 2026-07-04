import 'package:flutter/material.dart';
import 'package:http_client/models/models.dart';

/// Auth configuration editor for Bearer, Basic, API Key, and OAuth2.
class AuthEditor extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const AuthEditor({super.key, required this.auth, required this.onChanged});

  @override
  State<AuthEditor> createState() => _AuthEditorState();
}

class _AuthEditorState extends State<AuthEditor> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controller(String field, String value) {
    final key = '${widget.auth.hashCode}:$field';
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value);
    } else if (_controllers[key]!.text != value) {
      _controllers[key]!.text = value;
    }
    return _controllers[key]!;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: auth.type,
          key: ValueKey(auth.type),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('None')),
            DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
            DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
            DropdownMenuItem(value: 'apiKey', child: Text('API Key')),
            DropdownMenuItem(value: 'oauth2', child: Text('OAuth2')),
          ],
          onChanged: (type) {
            widget.onChanged(switch (type) {
              'bearer' => BearerAuth(token: ''),
              'basic' => BasicAuth(username: '', password: ''),
              'apiKey' => ApiKeyAuth(key: '', value: ''),
              'oauth2' => OAuth2Auth(
                tokenUrl: '',
                clientId: '',
                clientSecret: '',
              ),
              _ => const NoAuth(),
            });
          },
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
        switch (auth) {
          NoAuth() => const SizedBox.shrink(),
          BearerAuth a => Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(labelText: 'Token'),
              controller: _controller('bearer.token', a.token),
              onChanged: (v) => widget.onChanged(a.copyWith(token: v)),
            ),
          ),
          BasicAuth a => Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Username'),
                  controller: _controller('basic.user', a.username),
                  onChanged: (v) => widget.onChanged(a.copyWith(username: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  controller: _controller('basic.pass', a.password),
                  onChanged: (v) => widget.onChanged(a.copyWith(password: v)),
                ),
              ],
            ),
          ),
          ApiKeyAuth a => Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Key'),
                  controller: _controller('apiKey.key', a.key),
                  onChanged: (v) => widget.onChanged(a.copyWith(key: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Value'),
                  controller: _controller('apiKey.value', a.value),
                  onChanged: (v) => widget.onChanged(a.copyWith(value: v)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ApiKeyLocation>(
                  initialValue: a.location,
                  key: ValueKey(a.location),
                  items: ApiKeyLocation.values
                      .map(
                        (l) => DropdownMenuItem(value: l, child: Text(l.name)),
                      )
                      .toList(),
                  onChanged: (l) {
                    if (l != null) {
                      widget.onChanged(a.copyWith(location: l));
                    }
                  },
                ),
              ],
            ),
          ),
          OAuth2Auth a => Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Token URL'),
                  controller: _controller('oauth2.tokenUrl', a.tokenUrl),
                  onChanged: (v) => widget.onChanged(a.copyWith(tokenUrl: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Client ID'),
                  controller: _controller('oauth2.clientId', a.clientId),
                  onChanged: (v) => widget.onChanged(a.copyWith(clientId: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Client Secret'),
                  obscureText: true,
                  controller: _controller(
                    'oauth2.clientSecret',
                    a.clientSecret,
                  ),
                  onChanged: (v) =>
                      widget.onChanged(a.copyWith(clientSecret: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Scope'),
                  controller: _controller('oauth2.scope', a.scope),
                  onChanged: (v) => widget.onChanged(a.copyWith(scope: v)),
                ),
              ],
            ),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}
