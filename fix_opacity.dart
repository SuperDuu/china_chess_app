import 'dart:io';

void main() {
  final dir = Directory('lib');
  final exp = RegExp(r'\.withValues\(alpha:\s*([0-9.]+)\)');
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('.withValues')) {
        final newContent = content.replaceAllMapped(exp, (m) => '.withOpacity(${m.group(1)})');
        entity.writeAsStringSync(newContent);
        print('Fixed ${entity.path}');
      }
    }
  }
}
