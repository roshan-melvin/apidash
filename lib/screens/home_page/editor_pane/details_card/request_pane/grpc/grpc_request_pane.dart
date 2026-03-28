import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';

import 'grpc_metadata.dart';
import 'grpc_body.dart';
import 'grpc_service_def.dart';
import 'grpc_settings.dart';

class EditGrpcRequestPane extends ConsumerStatefulWidget {
  const EditGrpcRequestPane({super.key});

  @override
  ConsumerState<EditGrpcRequestPane> createState() => _EditGrpcRequestPaneState();
}

class _EditGrpcRequestPaneState extends ConsumerState<EditGrpcRequestPane> {

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider)?[selectedId];
    
    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }



    final currentIndex = requestModel.grpcRequestModel!.requestTabIndex;

    return DefaultTabController(
      length: 4,
      initialIndex: currentIndex,
      child: Column(
      children: [
        kVSpacer10,
        TabBar(
          padding: kPh20,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          dividerHeight: 0,
          tabs: const [
            Tab(text: "Message"),
            Tab(text: "Metadata"),
            Tab(text: "Server Ref"),
            Tab(text: "Settings"),
          ],
          onTap: (index) {
            ref
                .read(collectionStateNotifierProvider.notifier)
                .updateGrpcModel(requestTabIndex: index);
          },
        ),
        kVSpacer10,
        Expanded(
          child: IndexedStack(
            index: currentIndex,
            children: const [
              GrpcBody(),
              GrpcMetadata(),
              GrpcServiceDef(),
              GrpcSettings(),
            ],
          ),
        ),
      ],
    ));
  }
}
