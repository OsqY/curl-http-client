import 'dart:convert';

String prettyJson(dynamic json, {String indent = '  '}) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

String prettyXml(String xml, {String indent = '  '}) {
  // Minimal pretty printer: add newlines after closing and opening tags.
  final buffer = StringBuffer();
  var depth = 0;
  final regex = RegExp(r'(<[^>]+>)|([^<]+)');
  for (final match in regex.allMatches(xml)) {
    final tag = match.group(1);
    final text = match.group(2);
    if (tag != null) {
      final isClosing = tag.startsWith('</');
      final isSelfClosing = tag.endsWith('/>') || _isVoidTag(tag);
      if (isClosing) depth--;
      buffer.writeln('${indent * depth}$tag');
      if (!isClosing && !isSelfClosing) depth++;
    } else if (text != null && text.trim().isNotEmpty) {
      buffer.writeln('${indent * depth}${text.trim()}');
    }
  }
  return buffer.toString().trim();
}

bool _isVoidTag(String tag) {
  final voidTags = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };
  final name = RegExp(r'\w+').firstMatch(tag)?.group(0)?.toLowerCase() ?? '';
  return voidTags.contains(name);
}
