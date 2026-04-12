import 'dart:io';
import 'package:hive_ce/hive.dart';

void main() async {
  final hivePath = '${Platform.environment['HOME']}/Desktop/GSOC/apidashcache';
  Hive.init(hivePath);
  final box = await Hive.openBox('apidash-data');
  List ids = box.get('ids', defaultValue: []) as List;
  
  Map<String, dynamic> newReq = {
    'id': 'test-cli-uuid-9999',
    'name': 'My Super CLI Test',
    'httpRequestModel': {
      'method': 'POST',
      'url': 'https://httpbin.org/post'
    }
  };
  
  await box.put('test-cli-uuid-9999', newReq);
  if (!ids.contains('test-cli-uuid-9999')) {
    ids.add('test-cli-uuid-9999');
    await box.put('ids', ids);
  }
  
  final envBox = await Hive.openBox('apidash-environments');
  List envIds = envBox.get('environmentIds', defaultValue: []) as List;
  Map<String, dynamic> newEnv = {
    'id': 'env-prod-999',
    'name': 'Production',
    'values': [
      {'key': 'API_KEY', 'value': '12345'},
      {'key': 'BASE_URL', 'value': 'https://api.myapp.com'}
    ]
  };
  await envBox.put('env-prod-999', newEnv);
  if (!envIds.contains('env-prod-999')) {
    envIds.add('env-prod-999');
    await envBox.put('environmentIds', envIds);
  }
  
  print('Successfully injected named mock data for testing!');
  exit(0);
}
