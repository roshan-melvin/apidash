import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) async {
  final imagePath = args.isNotEmpty ? args.first : '/home/rocroshan/Downloads/Pasted image (2).png';
  int tWidth = args.length > 1 ? int.parse(args[1]) * 2 : 90;
  final bytes = await File(imagePath).readAsBytes();
  var image = img.decodeImage(bytes);
  if (image == null) return;
  
  image = img.copyResize(image, width: tWidth, height: (image.height * tWidth / image.width).round());
  
  String result = "";
  for (int y = 0; y < image.height; y += 4) {
    String line = '  ';
    for (int x = 0; x < image.width; x += 2) {
      int braille = 0;
      int tr = 0, tg = 0, tb = 0, count = 0;
      final dots = [
        [0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [0, 3], [1, 3]
      ];
      for (int i = 0; i < 8; i++) {
        int dx = x + dots[i][0];
        int dy = y + dots[i][1];
        if (dx < image!.width && dy < image.height) {
          final p = image.getPixel(dx, dy);
          
          // Filter out near-white background noise and low alpha
          if (p.a > 220 && p.r < 190 && p.g < 210) {
            braille |= (1 << i);
            tr += p.r.toInt();
            tg += p.g.toInt();
            tb += p.b.toInt();
            count++;
          }
        }
      }
      if (braille == 0) {
        line += ' ';
      } else {
        int r = tr ~/ count;
        int g = tg ~/ count;
        int b = tb ~/ count;
        line += '\x1B[38;2;$r;$g;${b}m' + String.fromCharCode(0x2800 + braille) + '\x1B[0m';
      }
    }
    result += line.trimRight() + '\n';
  }
  result = result.replaceAll(RegExp(r'\n+$'), '');
  result = result.replaceFirst(RegExp(r'^(\s*\n)+'), '');
  result += '\n                        \x1B[90mhttps://github.com/foss42/apidash\x1B[0m';
  print(result);
}
