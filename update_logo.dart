import 'dart:io';

void main() async {
  // Generate logo at smaller width
  print('Generating logo...');
  final result = await Process.run('dart', ['scripts/image_to_ascii.dart', '/home/rocroshan/Downloads/Pasted image (2).png', '55']);
  
  if (result.exitCode != 0) {
      print('Error generating: ${result.stderr}');
      return;
  }
  
  String logoText = result.stdout;
  // Clean up
  logoText = logoText.replaceAll(RegExp(r'^(\\n)+|(\\n)+$'), '');
  
  // Clean off trailing spaces just in case
  logoText = logoText.split('\\n').map((l) => l.trimRight()).join('\\n');

  // Prefix every line with a 2-char padding
  logoText = logoText.split('\\n').map((l) => '  \$cyan' + l + '\$reset').join('\\n');

  // Now replace it in bin/apidash_cli.dart
  final f = File('bin/apidash_cli.dart');
  String content = f.readAsStringSync();
  
  final regex = RegExp(r'void printApidashLogo\(\) \{\s*print\(\x27\x27\x27\$bold\$blue.*?\x27\x27\x27\);\s*\}', dotAll: true);
  
  if (regex.hasMatch(content)) {
     String replacement = '''void printApidashLogo() {
  print(\'\'\'
''' + logoText + '''

  \$bold\${green}APIDash CLI v0.5.0\$reset
  \${gray}https://github.com/foss42/apidash\$reset
\'\'\');
}''';
     content = content.replaceFirst(regex, replacement);
     f.writeAsStringSync(content);
     print("Replaced printApidashLogo body with the generated braille ASCII.");
  } else {
     print("Couldn't find the logo method with regex.");
  }
}
