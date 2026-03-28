import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_body.dart', 'r') as f:
    text = f.read()

# Let's restore the original padding and styling for Dropdown to make it identical to the user's screenshot
text = text.replace(
'''              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Service",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        isDense: true,
                      ),''',
'''              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Service",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(''')

text = text.replace(
'''              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Method",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        isDense: true,
                      ),''',
'''              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Method",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(''')

text = text.replace(
'''                      ),
                    ),
                  ),
                ),
              ),
              kHSpacer10,
              Expanded(
                child: InputDecorator(''',
'''                    ),
                  ),
                ),
              ),
              kHSpacer10,
              Expanded(
                child: InputDecorator(''')

text = text.replace(
'''                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          kVSpacer10,''',
'''                    ),
                  ),
                ),
              ),
            ],
          ),
          kVSpacer10,''')

# Re-enable the kPt5o10 layout
text = text.replace("padding: kP20,", "padding: kPt5o10.copyWith(bottom: 10, left: 20, right: 20),")

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_body.dart', 'w') as f:
    f.write(text)
