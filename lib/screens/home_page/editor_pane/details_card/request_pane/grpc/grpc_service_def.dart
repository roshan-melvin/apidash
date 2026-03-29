import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/generated/google/protobuf/descriptor.pb.dart'
    as $descriptor;

class GrpcServiceDef extends ConsumerWidget {
  const GrpcServiceDef({super.key});

  String _getMethodType($descriptor.MethodDescriptorProto method) {
    final clientStream = method.clientStreaming;
    final serverStream = method.serverStreaming;
    if (clientStream && serverStream) return "Bidirectional";
    if (clientStream) return "Client Streaming";
    if (serverStream) return "Server Streaming";
    return "Unary";
  }

  IconData _getMethodIcon(String methodType) {
    switch (methodType) {
      case "Bidirectional":
        return Icons.swap_vert;
      case "Client Streaming":
        return Icons.arrow_upward;
      case "Server Streaming":
        return Icons.arrow_downward;
      case "Unary":
      default:
        return Icons.arrow_forward;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(
      collectionStateNotifierProvider,
    )?[selectedId];

    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }

    final connectionStateAsync = ref.watch(grpcStateProvider);
    final connectionState = connectionStateAsync.value;

    if (connectionState == null ||
        connectionState.descriptors == null ||
        connectionState.descriptors!.isEmpty) {
      return Center(
        child: Padding(
          padding: kPh20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              kVSpacer10,
              Text(
                "No Services Discovered",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              kVSpacer10,
              Text(
                "Connect to a gRPC server with Server Reflection enabled to view available services.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Process descriptors
    final descriptors = connectionState.descriptors!.values.toList();

    final services = <Map<String, dynamic>>[];

    for (final fd in descriptors) {
      final pkg = fd.package;
      for (final sd in fd.service) {
        final fullServiceName = pkg.isNotEmpty ? '$pkg.${sd.name}' : sd.name;
        final methods = <Map<String, dynamic>>[];
        for (final md in sd.method) {
          methods.add({
            'name': md.name,
            'inputType': md.inputType,
            'outputType': md.outputType,
            'type': _getMethodType(md),
            'methodOriginal': md,
          });
        }
        services.add({
          'name': fullServiceName,
          'methods': methods,
          'serviceOriginal': sd,
        });
      }
    }

    // Sort services by name alphabetically
    services.sort((a, b) => a['name'].compareTo(b['name']));

    return SingleChildScrollView(
      padding: kPh20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: services.map((service) {
          final methods = service['methods'] as List<Map<String, dynamic>>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                collapsedBackgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  service['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                subtitle: Text(
                  "${methods.length} methods",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: methods.map((method) {
                  final mName = method['name'];
                  final mType = method['type'];
                  final mInput = method['inputType'];
                  final mOutput = method['outputType'];
                  final mPath = '/${service['name']}/$mName';

                  return InkWell(
                    onTap: () {
                      // Apply this method to the current request model
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateGrpcModel(
                            id: selectedId,
                            serviceName: service['name'],
                            methodName: mName,
                            requestTabIndex: 0,
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to $mName — ready to send'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _getMethodIcon(mType),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  children: [
                                    Text(
                                      "$mType • ",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      mInput,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      " → ",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      mOutput,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              mPath,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
