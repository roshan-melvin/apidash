import 'dart:io';

void main() {
  final f = File('bin/apidash_cli.dart');
  String c = f.readAsStringSync();
  
  // The block looks like:
  /*
      print(
        '$cyan\u2554\u2550\u2550...
      );
      print(
        '$cyan\u2551$reset   $bold${green}APIDash CLI  v0.5.0$reset       $cyan\u2551$reset',
      );
      print(
        '$cyan\u255a\u2550\u2550...
      );
  */
  
  final regex = RegExp(r"print\(\s*'\$cyan\\u2554.*?\\u2557\$reset',\s*\);\s*print\(\s*'\$cyan\\u2551\$reset.*?\$cyan\\u2551\$reset',\s*\);\s*print\(\s*'\$cyan\\u255a.*?\\u255d\$reset',\s*\);", dotAll: true);
  
  // Replace each occurrence with printApidashLogo();
  c = c.replaceAll(regex, "printApidashLogo();");
  
  f.writeAsStringSync(c);
  print('Replaced border boxes with printApidashLogo() calls');
}
