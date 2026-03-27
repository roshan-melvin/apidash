import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/screens/common_widgets/common_widgets.dart';
import 'dart:math';

class EditWebSocketRequestHeaders extends ConsumerStatefulWidget {
  const EditWebSocketRequestHeaders({super.key});

  @override
  ConsumerState<EditWebSocketRequestHeaders> createState() =>
      _EditWebSocketRequestHeadersState();
}

class _EditWebSocketRequestHeadersState
    extends ConsumerState<EditWebSocketRequestHeaders> {
  late int seed;
  final random = Random.secure();
  late List<NameValueModel> headerRows;
  late List<bool> isRowEnabledList;
  bool isAddingRow = false;

  @override
  void initState() {
    super.initState();
    seed = random.nextInt(kRandMax);
  }

  void _onFieldChange() {
    ref.read(collectionStateNotifierProvider.notifier).updateWebSocketModel(
          requestHeaders: headerRows.sublist(0, headerRows.length - 1),
          isHeaderEnabledList: isRowEnabledList.sublist(0, headerRows.length - 1),
        );
  }

  @override
  Widget build(BuildContext context) {
    dataTableShowLogs = false;
    final selectedId = ref.watch(selectedIdStateProvider);
    
    // Watch specifically for WebSocket headers
    ref.watch(selectedRequestModelProvider.select(
        (value) => value?.websocketRequestModel?.requestHeaders?.length));
        
    var rH = ref.read(selectedRequestModelProvider)?.websocketRequestModel?.requestHeaders;
    bool isHeadersEmpty = rH == null || rH.isEmpty;
    
    headerRows = isHeadersEmpty
        ? [kNameValueEmptyModel]
        : rH + [kNameValueEmptyModel];
        
    var isEnabledList = ref.read(selectedRequestModelProvider)?.websocketRequestModel?.isHeaderEnabledList;
    if (isEnabledList == null || isEnabledList.length != rH?.length) {
      isRowEnabledList = List.filled(headerRows.length, true, growable: true);
    } else {
      isRowEnabledList = isEnabledList + [false];
    }
    isRowEnabledList[isRowEnabledList.length - 1] = false;
    isAddingRow = false;

    List<DataColumn> columns = const [
      DataColumn2(
        label: Text(kNameCheckbox),
        fixedWidth: 30,
      ),
      DataColumn2(
        label: Text(kNameHeader),
      ),
      DataColumn2(
        label: Text('='),
        fixedWidth: 30,
      ),
      DataColumn2(
        label: Text(kNameValue),
      ),
      DataColumn2(
        label: Text(''),
        fixedWidth: 32,
      ),
    ];

    List<DataRow> dataRows = List<DataRow>.generate(
      headerRows.length,
      (index) {
        bool isLast = index + 1 == headerRows.length;
        return DataRow(
          key: ValueKey("$selectedId-$index-ws-headers-row-$seed"),
          cells: <DataCell>[
            DataCell(
              ADCheckBox(
                keyId: "$selectedId-$index-ws-headers-c-$seed",
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
                keyId: "$selectedId-$index-ws-headers-k-$seed",
                initialValue: headerRows[index].name,
                hintText: kHintAddName,
                onChanged: (value) {
                  headerRows[index] = headerRows[index].copyWith(name: value);
                  if (isLast && !isAddingRow) {
                    isAddingRow = true;
                    isRowEnabledList[index] = true;
                    headerRows.add(kNameValueEmptyModel);
                    isRowEnabledList.add(false);
                  }
                  _onFieldChange();
                },
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            DataCell(
              Center(
                child: Text(
                  "=",
                  style: kCodeStyle,
                ),
              ),
            ),
            DataCell(
              EnvCellField(
                keyId: "$selectedId-$index-ws-headers-v-$seed",
                initialValue: headerRows[index].value,
                hintText: kHintAddValue,
                onChanged: (value) {
                  headerRows[index] = headerRows[index].copyWith(value: value);
                  if (isLast && !isAddingRow) {
                    isAddingRow = true;
                    isRowEnabledList[index] = true;
                    headerRows.add(kNameValueEmptyModel);
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
                        if (headerRows.length == 2) {
                          setState(() {
                            headerRows = [kNameValueEmptyModel];
                            isRowEnabledList = [false];
                          });
                        } else {
                          headerRows.removeAt(index);
                          isRowEnabledList.removeAt(index);
                        }
                        _onFieldChange();
                      },
                child: Theme.of(context).brightness == Brightness.dark
                    ? kIconRemoveDark
                    : kIconRemoveLight,
              ),
            ),
          ],
        );
      },
    );

    return Padding(
      padding: kP12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Connection Headers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              kHSpacer8,
              const Icon(Icons.info_outline, size: 16),
              kHSpacer4,
              const Text('Headers are sent during the initial handshake',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: kPh10t10,
                  child: Column(
                    children: [
                      Expanded(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(scrollbarTheme: kDataTableScrollbarTheme),
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
                      if (!kIsMobile) kVSpacer40,
                    ],
                  ),
                ),
                if (!kIsMobile)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: kPb15,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          headerRows.add(kNameValueEmptyModel);
                          isRowEnabledList.add(false);
                          _onFieldChange();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          kLabelAddHeader,
                          style: kTextStyleButton,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
