import re

with open('lib/widgets/websocket/websocket_response_pane.dart', 'r') as f:
    text = f.read()

# Add controllers instead of using initialValue
new_state_vars = """  String _filterString = '';
  String _filterEventString = '';
  late final TextEditingController _msgFilterCtrl;
  late final TextEditingController _eventFilterCtrl;"""

text = re.sub(r"  String _filterString = '';\s*String _filterEventString = '';", new_state_vars, text, count=1)

init_state = """  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _msgFilterCtrl = TextEditingController(text: _filterString);
    _eventFilterCtrl = TextEditingController(text: _filterEventString);
  }"""

text = re.sub(r"  void initState\(\) \{\s*super\.initState\(\);\s*_tabCtrl = TabController\(length: 2, vsync: this\);\s*\}", init_state, text, count=1)

dispose = """  void dispose() {
    _tabCtrl.dispose();
    _msgFilterCtrl.dispose();
    _eventFilterCtrl.dispose();
    super.dispose();
  }"""

text = re.sub(r"  void dispose\(\) \{\s*_tabCtrl\.dispose\(\);\s*super\.dispose\(\);\s*\}", dispose, text, count=1)

old_tf = """                    child: TextFormField(
                      key: ValueKey('ws_filter_${_tabCtrl.index}'),
                      initialValue: isChat ? _filterString : _filterEventString,"""

new_tf = """                    child: TextFormField(
                      key: ValueKey('ws_filter_${_tabCtrl.index}'),
                      controller: isChat ? _msgFilterCtrl : _eventFilterCtrl,"""

text = text.replace(old_tf, new_tf)

with open('lib/widgets/websocket/websocket_response_pane.dart', 'w') as f:
    f.write(text)
