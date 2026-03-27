import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';

class GrpcBody extends ConsumerStatefulWidget {
  const GrpcBody({super.key});

  @override
  ConsumerState<GrpcBody> createState() => _GrpcBodyState();
}

class _GrpcBodyState extends ConsumerState<GrpcBody> {
  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider.select((value) => value?[selectedId]?.grpcRequestModel));
    final darkMode = ref.watch(settingsProvider.select((value) => value.isDark));
    
    if (requestModel == null) {
      return const SizedBox.shrink();
    }

    final grpcState = ref.watch(grpcStateProvider);
    final isActiveUrlConnected = (grpcState.value?.isConnected ?? false) && (grpcState.value?.connectedUrl == requestModel.url);

    return Padding(
      padding: kPt5o10,
      child: Column(
        children: [
          Expanded(
            child: JsonTextFieldEditor(
              key: Key("grpc_body_$selectedId"),
              fieldKey: "grpc_body_$selectedId-editor-$darkMode",
              isDark: darkMode,
              initialValue: requestModel.requestJson,
              onChanged: (String value) {
                ref.read(collectionStateNotifierProvider.notifier).updateGrpcModel(
                  id: selectedId,
                  requestJson: value,
                );
              },
              hintText: "Enter JSON body for gRPC payload...",
            ),
          ),
          kVSpacer8,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isActiveUrlConnected
                  ? () async {
                      final message = requestModel.requestJson;
                      if (message.isNotEmpty) {
                        await ref.read(grpcServiceProvider).send(message: message, requestModel: requestModel);
                      } else {
                        await ref.read(grpcServiceProvider).send(message: "{}", requestModel: requestModel);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              ),
              icon: const Icon(Icons.send),
              label: const Text("Send"),
            ),
          ),
        ],
      ),
    );
  }
}
