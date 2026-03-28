import re
path = 'lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart'
with open(path, 'r') as f:
    text = f.read()

# Add controllers
old_ctrls = """  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _publishTopicCtrl;
  late final TextEditingController _publishPayloadCtrl;"""
new_ctrls = """  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _publishTopicCtrl;
  late final TextEditingController _publishPayloadCtrl;
  late final TextEditingController _lastWillTopicCtrl;
  late final TextEditingController _lastWillMessageCtrl;"""
text = text.replace(old_ctrls, new_ctrls)

old_init = """    _publishTopicCtrl = TextEditingController(text: m.publishTopic);
    _publishPayloadCtrl = TextEditingController(text: m.publishPayload);
  }"""
new_init = """    _publishTopicCtrl = TextEditingController(text: m.publishTopic);
    _publishPayloadCtrl = TextEditingController(text: m.publishPayload);
    _lastWillTopicCtrl = TextEditingController(text: m.lastWillTopic);
    _lastWillMessageCtrl = TextEditingController(text: m.lastWillMessage);
  }"""
text = text.replace(old_init, new_init)

old_disp = """      _passCtrl,
      _publishTopicCtrl,
      _publishPayloadCtrl,
    ]) {"""
new_disp = """      _passCtrl,
      _publishTopicCtrl,
      _publishPayloadCtrl,
      _lastWillTopicCtrl,
      _lastWillMessageCtrl,
    ]) {"""
text = text.replace(old_disp, new_disp)

# Update Last Will Topic TextField
old_will_topic = """                      TextFormField(
                        enabled: !isConnected,
                        decoration: fieldDeco.copyWith(
                          hintText: 'e.g. client/disconnected',
                        ),
                      ),"""
new_will_topic = """                      TextFormField(
                        controller: _lastWillTopicCtrl,
                        enabled: !isConnected,
                        decoration: fieldDeco.copyWith(
                          hintText: 'e.g. client/disconnected',
                        ),
                        onChanged: (v) => _update((m) => m.copyWith(lastWillTopic: v)),
                      ),"""
text = text.replace(old_will_topic, new_will_topic)

old_will_msg = """                      TextFormField(
                        enabled: !isConnected,
                        maxLines: 4,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Offline payload...',
                        ),
                      ),"""
new_will_msg = """                      TextFormField(
                        controller: _lastWillMessageCtrl,
                        enabled: !isConnected,
                        maxLines: 4,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Offline payload...',
                        ),
                        onChanged: (v) => _update((m) => m.copyWith(lastWillMessage: v)),
                      ),"""
text = text.replace(old_will_msg, new_will_msg)

old_will_qos = """                          ADDropdownButton<int>(
                            value: 0,
                            values: const [(0, '0'), (1, '1'), (2, '2')],
                            onChanged: !isConnected ? (v) {} : null,
                          ),"""
new_will_qos = """                          ADDropdownButton<int>(
                            value: model.lastWillQos,
                            values: const [(0, '0'), (1, '1'), (2, '2')],
                            onChanged: !isConnected ? (v) {
                              if (v != null) _update((m) => m.copyWith(lastWillQos: v));
                            } : null,
                          ),"""
text = text.replace(old_will_qos, new_will_qos)

old_will_retain = """                          Switch(
                            value: false,
                            onChanged: !isConnected ? (v) {} : null,"""
new_will_retain = """                          Switch(
                            value: model.lastWillRetain,
                            onChanged: !isConnected ? (v) => _update((m) => m.copyWith(lastWillRetain: v)) : null,"""
text = text.replace(old_will_retain, new_will_retain)

with open(path, 'w') as f:
    f.write(text)
