import 'dart:io';

void main() async {
  final result = await Process.run('dart', ['scripts/image_to_ascii.dart']);
  final ascii = result.stdout.toString();

  final file = File('bin/apidash_cli.dart');
  var content = await file.readAsString();

  final startMarker = "void printApidashLogo() {\n  print('''";
  final endMarker = "''');\n}";

  final startIndex = content.indexOf(startMarker);
  final endIndex = content.indexOf(endMarker, startIndex);

  if (startIndex != -1 && endIndex != -1) {
    final newContent = content.substring(0, startIndex) +
        startMarker + '\n' +
        ascii.replaceAll(r'$', r'\$').replaceAll(r'\', r'\\') + '\n' +
        endMarker + 
        content.substring(endIndex + endMarker.length);
    await file.writeAsString(newContent);
    print("Success! Braille logo injected into apidash_cli.dart.");
  } else {
    print("Failed to find logo block.");
  }
}
