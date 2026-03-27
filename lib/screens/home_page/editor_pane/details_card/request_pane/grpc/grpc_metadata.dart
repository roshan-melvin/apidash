import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/screens/common_widgets/common_widgets.dart';
import 'dart:math';

class GrpcMetadata extends ConsumerStatefulWidget {
  const GrpcMetadata({super.key});

  @override
  ConsumerState<GrpcMetadata> createState() => _GrpcMetadataState();
}

class _GrpcMetadataState extends ConsumerState<GrpcMetadata> {
  late int seed;
  final random = Random.secure();
  late List<NameValueModel> rows;
  late List<bool> isRowEnabledList;
  bool isAddingRow = false;

  @override
  void initState() {
    super.initState();
    seed = random.nextInt(kRandMax);
  }

  void _onFieldChange() {
    ref
        .read(collectionStateNotifierProvider.notifier)
        .updateGrpcModel(
          metadata: rows.sublist(0, rows.length - 1),
          isMetadataEnabledList: isRowEnabledList.sublist(0, rows.length - 1),
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(
      collectionStateNotifierProvider.select(
        (value) => value?[selectedId]?.grpcRequestModel,
      ),
    );

    if (requestModel == null) {
      return const SizedBox.shrink();
    }

    bool isMetadataEmpty = requestModel.metadata.isEmpty;
    rows = isMetadataEmpty
        ? [kNameValueEmptyModel]
        : requestModel.metadata.toList() + [kNameValueEmptyModel];

    isRowEnabledList = [
      ...(requestModel.isMetadataEnabledList.isNotEmpty
          ? requestModel.isMetadataEnabledList
          : List.filled(requestModel.metadata.length, true, growable: true)),
    ];

    if (isRowEnabledList.length < rows.length) {
      int diff = rows.length - isRowEnabledList.length;
      isRowEnabledList.addAll(List.filled(diff, true));
    }

    isRowEnabledList[isRowEnabledList.length - 1] = false;
    isAddingRow = false;

    List<DataColumn> columns = const [
      DataColumn2(label: Text(kNameCheckbox), fixedWidth: 30),
      DataColumn2(label: Text(kNameHeader)),
      DataColumn2(label: Text('='), fixedWidth: 30),
      DataColumn2(label: Text(kNameValue)),
      DataColumn2(label: Text(''), fixedWidth: 32),
    ];

    List<DataRow> dataRows = List<DataRow>.generate(rows.length, (index) {
      bool isLast = index + 1 == rows.length;
      return DataRow(
        key: ValueKey("$selectedId-$index-grpc-meta-row-$seed"),
        cells: <DataCell>[
          DataCell(
            ADCheckBox(
              keyId: "$selectedId-$index-grpc-meta-c-$seed",
              value: isRowEnabledList[index],
              onChanged: isLast
                  ? null
                  : (value) {
                      setState(() {
                        isRowEnabledList[index] = value!;
                      });
                      _onFieldChange();
                    },
              colorScheme: Theme.of(context).colorScheme,
            ),
          ),
          DataCell(
            EnvHeaderField(
              keyId: "$selectedId-$index-grpc-meta-k-$seed",
              initialValue: rows[index].name,
              hintText: kHintAddName,
              onChanged: (value) {
                rows[index] = rows[index].copyWith(name: value);
                if (isLast && !isAddingRow) {
                  isAddingRow = true;
                  isRowEnabledList[index] = true;
                  rows.add(kNameValueEmptyModel);
                  isRowEnabledList.add(false);
                }
                _onFieldChange();
              },
              colorScheme: Theme.of(context).colorScheme,
            ),
          ),
          DataCell(Center(child: Text("=", style: kCodeStyle))),
          DataCell(
            EnvHeaderField(
              keyId: "$selectedId-$index-grpc-meta-v-$seed",
              initialValue: rows[index].value.toString(),
              hintText: kHintAddValue,
              onChanged: (value) {
                rows[index] = rows[index].copyWith(value: value);
                if (isLast && !isAddingRow) {
                  isAddingRow = true;
                  isRowEnabledList[index] = true;
                  rows.add(kNameValueEmptyModel);
                  isRowEnabledList.add(false);
                }
                _onFieldChange();
              },
              colorScheme: Theme.of(context).colorScheme,
            ),
          ),
          DataCell(
            InkWell(
              onTap: isLast
                  ? null
                  : () {
                      seed = random.nextInt(kRandMax);
                      if (rows.length == 2) {
                        setState(() {
                          rows = [kNameValueEmptyModel];
                          isRowEnabledList = [false];
                        });
                      } else {
                        rows.removeAt(index);
                        isRowEnabledList.removeAt(index);
                      }
                      _onFieldChange();
                    },
              child: Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: kColorTransparent,
                  splashColor: kColorTransparent,
                  highlightColor: kColorTransparent,
                ),
                child: Icon(
                  Icons.remove_circle,
                  size: 16,
                  color: isLast
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      );
    });

    return Padding(
      padding: kPh20,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: kBorderRadius12,
            ),
            margin: kP5,
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: Theme.of(context).iconTheme.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: DataTable2(
                columnSpacing: 12,
                dividerThickness: 0,
                horizontalMargin: 0,
                headingRowHeight: 0,
                dataRowHeight: kDataTableRowHeight,
                bottomMargin: kDataTableBottomPadding,
                isVerticalScrollBarVisible: true,
                columns: columns,
                rows: dataRows,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: kPb15,
              child: ElevatedButton.icon(
                onPressed: () {
                  rows.add(kNameValueEmptyModel);
                  isRowEnabledList.add(false);
                  _onFieldChange();
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Metadata", style: kTextStyleButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
