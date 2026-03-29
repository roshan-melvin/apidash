import 'package:flutter/material.dart';
import 'package:apidash_design_system/apidash_design_system.dart';

class MqttTopicAutocomplete extends StatelessWidget {
  final String keyId;
  final String? initialValue;
  final String? hintText;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  const MqttTopicAutocomplete({
    super.key,
    required this.keyId,
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      initialValue: TextEditingValue(
        text: initialValue ?? '',
        selection: TextSelection.collapsed(offset: initialValue?.length ?? 0),
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        if (text.isEmpty ||
            text.endsWith('/') ||
            text.endsWith('#') ||
            text.endsWith('+')) {
          return const Iterable<String>.empty();
        }
        return ['$text/#', '$text/+'];
      },
      onSelected: (String selection) {
        // focus loss happens if we don't handle it, but RawAutocomplete handles focus if configured
        onChanged?.call(selection);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            final decoration = InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              suffixIcon: suffixIcon,
            );

            return TextFormField(
              key: Key(keyId),
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: decoration,
              onChanged: (val) {
                onChanged?.call(val);
              },
            );
          },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 350,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      final bool isHash = option.endsWith('#');
                      final hint = isHash
                          ? '# matches everything at this level and below'
                          : '+ matches exactly one level';
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                hint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}
