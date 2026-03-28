import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

# Add controllers instead of using initialValue
new_state_vars = """  String _filterTopic = '';
  String _filterEvent = '';
  late final TextEditingController _topicFilterCtrl;
  late final TextEditingController _eventFilterCtrl;"""

text = re.sub(r"  String _filterTopic = '';\s*String _filterEvent = '';", new_state_vars, text, count=1)

init_state = """  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _topicFilterCtrl = TextEditingController(text: _filterTopic);
    _eventFilterCtrl = TextEditingController(text: _filterEvent);
  }"""

text = re.sub(r"  void initState\(\) \{\s*super\.initState\(\);\s*_tabCtrl = TabController\(length: 2, vsync: this\);\s*\}", init_state, text, count=1)

dispose = """  void dispose() {
    _tabCtrl.dispose();
    _topicFilterCtrl.dispose();
    _eventFilterCtrl.dispose();
    super.dispose();
  }"""

text = re.sub(r"  void dispose\(\) \{\s*_tabCtrl\.dispose\(\);\s*super\.dispose\(\);\s*\}", dispose, text, count=1)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
