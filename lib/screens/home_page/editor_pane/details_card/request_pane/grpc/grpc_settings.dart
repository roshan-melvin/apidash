import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/models/models.dart';

class GrpcSettings extends ConsumerWidget {
  const GrpcSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider)?[selectedId];
    
    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }

    final grpcModel = requestModel.grpcRequestModel!;

    return Padding(
      padding: kPh20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Use TLS", style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    grpcModel.useTls
                        ? "Connection is encrypted"
                        : "Connection is plaintext (insecure)",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Switch(
                value: grpcModel.useTls,
                onChanged: (val) {
                  ref.read(collectionStateNotifierProvider.notifier).updateGrpcModel(
                        id: selectedId,
                        useTls: val,
                      );
                },
              ),
            ],
          ),
          kVSpacer10,
          const Divider(),
          kVSpacer10,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Use Server Reflection", style: Theme.of(context).textTheme.titleMedium),
                   Text(
                    "Discover services via gRPC server reflection",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Switch(
                value: grpcModel.descriptorSource == GrpcDescriptorSource.reflection,
                onChanged: (val) {
                  ref.read(collectionStateNotifierProvider.notifier).updateGrpcModel(
                        id: selectedId,
                        descriptorSource: val ? GrpcDescriptorSource.reflection : GrpcDescriptorSource.protoUpload,
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
