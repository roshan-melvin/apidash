import 'package:apidash/services/hive_services.dart';
import 'package:apidash/main.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await Hive.openBox(kDataBox);
    print("SUCCESS");
  } catch (e, stack) {
    print("HIVE ERROR: $e");
    print(stack);
  }
}
