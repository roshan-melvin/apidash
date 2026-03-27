import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../request_headers.dart';

class EditWebSocketRequestHeaders extends ConsumerWidget {
  const EditWebSocketRequestHeaders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: kP12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connection Headers',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          kVSpacer8,
          Expanded(
            child: EditRequestHeaders(),
          ),
        ],
      ),
    );
  }
}
