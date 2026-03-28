import re

with open('lib/services/websocket_service.dart', 'r') as f:
    content = f.read()

old_uri = """      final rec = getValidRequestUri(request.url, enabledParams);
      final uri = rec.$1;"""

new_uri = """      var uri = Uri.parse(request.url);
      if (enabledParams.isNotEmpty) {
        final queryParams = {...uri.queryParameters};
        for (final p in enabledParams) {
          if (p.name.isNotEmpty) {
            queryParams[p.name] = p.value;
          }
        }
        uri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      }"""

content = content.replace(old_uri, new_uri)

with open('lib/services/websocket_service.dart', 'w') as f:
    f.write(content)
