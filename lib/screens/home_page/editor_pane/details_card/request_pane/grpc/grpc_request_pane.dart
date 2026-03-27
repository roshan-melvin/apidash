import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/models/models.dart';

import 'grpc_metadata.dart';
import 'grpc_body.dart';

class EditGrpcRequestPane extends ConsumerStatefulWidget {
  const EditGrpcRequestPane({super.key});

  @override
  ConsumerState<EditGrpcRequestPane> createState() => _EditGrpcRequestPaneState();
}

class _EditGrpcRequestPaneState extends ConsumerState<EditGrpcRequestPane> {
  final TextEditingController _serviceCtrl = TextEditingController();
  final TextEditingController _methodCtrl = TextEditingController();

  String? _lastId;

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _methodCtrl.dispose();
    super.dispose();
  }

  void _updateControllers(String selectedId, GrpcRequestModel model) {
    if (_lastId != selectedId) {
      _serviceCtrl.text = model.serviceName;
      _methodCtrl.text = model.methodName;
      _lastId = selectedId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider)?[selectedId];
    
    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }

    _updateControllers(selectedId!, requestModel.grpcRequestModel!);

    final currentIndex = requestModel.grpcRequestModel!.requestTabIndex;

    return DefaultTabController(
      length: 2,
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
            Tab(text: "Body"),
            Tab(text: "Metadata (Headers)"),
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
            ],
          ),
        ),
        kVSpacer10,
        Padding(
          padding: kPh20,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: Key("serviceName-$selectedId"),
                  controller: _serviceCtrl,
                  decoration: const InputDecoration(
                    labelText: "Service Name",
                    hintText: "helloworld.Greeter",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref.read(collectionStateNotifierProvider.notifier).updateGrpcModel(
                      id: selectedId,
                      serviceName: val,
                    );
                  },
                ),
              ),
              kHSpacer10,
              Expanded(
                child: TextFormField(
                  key: Key("methodName-$selectedId"),
                  controller: _methodCtrl,
                  decoration: const InputDecoration(
                    labelText: "Method Name",
                    hintText: "SayHello",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref.read(collectionStateNotifierProvider.notifier).updateGrpcModel(
                      id: selectedId,
                      methodName: val,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        kVSpacer10,
      ],
    ));
  }
}
