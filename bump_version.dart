import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  final content = file.readAsStringSync();

  final versionRegex = RegExp(r'version:\s(\d+)\.(\d+)\.(\d+)');
  final match = versionRegex.firstMatch(content);

  if (match != null) {
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);

    final newVersion = '$major.$minor.${patch + 1}';
    final newContent = content.replaceFirst(versionRegex, 'version: $newVersion');
    file.writeAsStringSync(newContent);

    print('✅ Version bumped to $newVersion');
  } else {
    print('❌ Version line not found.');
  }
}
