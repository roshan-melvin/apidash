import re

with open('packages/apidash_design_system/lib/widgets/decoration_input_textfield.dart', 'r') as f:
    content = f.read()

content = content.replace(
    '''    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: focussedBorderColor ?? clrScheme.outline,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: enabledBorderColor ?? clrScheme.surfaceContainerHighest,
      ),
    ),''',
    '''    focusedBorder: OutlineInputBorder(
      borderRadius: kBorderRadius8,
      borderSide: BorderSide(
        color: focussedBorderColor ?? clrScheme.outline,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: kBorderRadius8,
      borderSide: BorderSide(
        color: enabledBorderColor ?? clrScheme.surfaceContainerHighest,
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: kBorderRadius8,
      borderSide: BorderSide(
        color: enabledBorderColor ?? clrScheme.surfaceContainerHighest,
      ),
    ),'''
)

with open('packages/apidash_design_system/lib/widgets/decoration_input_textfield.dart', 'w') as f:
    f.write(content)

