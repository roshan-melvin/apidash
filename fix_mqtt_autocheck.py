with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r') as f:
    text = f.read()

old_code = """      if (index >= list.length) {
        list.add(updated);
        return m.copyWith(topics: list);
      }"""

new_code = """      if (index >= list.length) {
        final newTopic = updated.copyWith(subscribe: true);
        list.add(newTopic);
        // also call subscribe since we toggle to true
        if (newTopic.topic.isNotEmpty) {
          ref.read(mqttServiceProvider).subscribe(newTopic.topic, newTopic.qos);
        }
        return m.copyWith(topics: list);
      }"""

text = text.replace(old_code, new_code)
with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'w') as f:
    f.write(text)

