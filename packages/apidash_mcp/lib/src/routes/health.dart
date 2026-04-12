import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final healthRouter = Router()
  ..get('/health', (Request req) {
    return Response.ok('OK');
  });
