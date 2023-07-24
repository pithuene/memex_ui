import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_activity_monitor/activity_monitor_logo.dart';
import 'package:flutter_activity_monitor/desktop_entries.dart';
import 'package:flutter_activity_monitor/proc.dart';
import 'package:flutter/material.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:linux_system_info/linux_system_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MemoryOverviewPage();
  }
}

String formatByteAmount(double bytes) {
  const List<String> prefixNames = [
    "",
    "KiB",
    "MiB",
    "GiB",
    "TiB",
    "PiB",
    "EiB",
  ];
  int prefix = 0;
  while (bytes > pow(1024, prefix + 1)) {
    prefix++;
  }
  return '${(bytes / pow(1024, prefix)).toStringAsFixed(2)} ${prefixNames[prefix]}';
}

class MemoryOverviewPage extends StatefulWidget {
  const MemoryOverviewPage({Key? key}) : super(key: key);

  @override
  State<MemoryOverviewPage> createState() => _MemoryOverviewPageState();
}

class _MemoryOverviewPageState extends State<MemoryOverviewPage> {
  ProcessListFilter processListFilter =
      ProcessListFilter(orderBy: ProcessListOrder.memory);
  List<Cpu> processors = [];
  Timer? updateTimer;
  SystemInformation sysInfo = SystemInformation();

  late TableDatasource<ProcessInformation> table;

  Map<String, Image> iconMap = {};

  void updateProcessorData(Timer _) {
    processors = CpuInfo.getProcessors();
  }

  void updateProcessData(Timer _) {
    sysInfo
        .updateProcessList(processListFilter)
        .then((_) => table.dataChanged());
  }

  updateAllData(Timer timer) {
    updateProcessorData(timer);
    updateProcessData(timer);
  }

  orderBy(ProcessListOrder order, ProcessListOrderDirection direction) {
    processListFilter.orderBy = order;
    processListFilter.orderDirection = direction;
    sysInfo.updatePidList(processListFilter);
  }

  filterByUser(bool showMyProcessesOnly) {
    if (showMyProcessesOnly) {
      String username = Process.runSync('whoami', []).stdout.trim();
      setState(() {
        processListFilter.user = username;
        sysInfo.updatePidList(processListFilter);
        table.dataChanged();
      });
    } else {
      setState(() {
        processListFilter.user = null;
        sysInfo.updatePidList(processListFilter);
        table.dataChanged();
      });
    }
  }

  interruptProcess(ProcessInformation process) {
    Process.killPid(process.pid, ProcessSignal.sigint);
    updateAllData(updateTimer!);
  }

  @override
  void initState() {
    super.initState();
    updateTimer =
        Timer.periodic(const Duration(milliseconds: 3000), updateAllData);
    updateAllData(updateTimer!);
    DesktopEntries desktopEntries = DesktopEntries();
    iconMap = desktopEntries.createIconMap();

    table = TableDatasource<ProcessInformation>(
      colDefs: [
        ColumnDefinition(
          label: "Process Name",
          width: const FlexColumnWidth(),
          cellBuilder: (context, process) {
            Widget icon = const SizedBox.shrink();
            if (iconMap.containsKey(process.name)) {
              icon = iconMap[process.name]!;
            }
            return Row(
              children: [
                const SizedBox(width: 10),
                SizedBox(height: 16, width: 16, child: icon),
                const SizedBox(width: 16),
                Text(process.name),
              ],
            );
          },
        ),
        ColumnDefinition(
          label: "PID",
          width: const FixedColumnWidth(100),
          alignment: ColumnAlignment.end,
          cellBuilder: (context, process) => Text(process.pid.toString()),
        ),
        ColumnDefinition(
          label: "CPU Load",
          width: const FixedColumnWidth(150),
          alignment: ColumnAlignment.end,
          cellBuilder: (context, process) => Text(process.cpuLoad != null
              ? '${(process.cpuLoad! * 100.0).toStringAsFixed(2)}%'
              : '-'),
        ),
        ColumnDefinition(
          label: "Memory",
          width: const FixedColumnWidth(120),
          alignment: ColumnAlignment.end,
          cellBuilder: (context, process) =>
              Text(formatByteAmount(process.memSize.toDouble())),
        ),
      ],
      getRowValue: (index) {
        ProcessInformation process = sysInfo.getProcessAtIndex(index);
        return TableValue(key: ValueKey(process.pid), value: process);
      },
      getRowCount: () => sysInfo.getProcessListLength(),
      changeOrder: (tableOrder) {
        ProcessListOrder order;
        switch (tableOrder?.column.label) {
          case "Process Name":
            order = ProcessListOrder.name;
            break;
          case "PID":
            order = ProcessListOrder.pid;
            break;
          case "CPU Load":
            order = ProcessListOrder.cpuLoad;
            break;
          case "Memory":
            order = ProcessListOrder.memory;
            break;
          default:
            return false;
        }
        orderBy(
            order,
            tableOrder?.direction == TableOrderDirection.ascending
                ? ProcessListOrderDirection.ascending
                : ProcessListOrderDirection.descending);
        return true;
      },
    );

    filterByUser(true);
  }

  @override
  void dispose() {
    super.dispose();
    updateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return App(
      appName: "Activity Monitor",
      toolBar: ToolBar(
          title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Activity Monitor"),
                Text(
                  processListFilter.user == null
                      ? "All processes"
                      : "User processes",
                  style: MemexTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: MemexTypography.baseFontSize * 0.85,
                  ),
                )
              ]),
          actions: [
            ToolBarIconButton(
                label: "Stop",
                icon: const MacosIcon(CupertinoIcons.xmark_octagon),
                showLabel: false,
                onPressed: () {
                  final selectedProcesses = table.selectedRows;
                  if (selectedProcesses.isEmpty) return;
                  final selectedProcess = selectedProcesses.first;
                  showMacosAlertDialog(
                      context: context,
                      builder: (context) {
                        return MacosAlertDialog(
                          appIcon: const ActivityMonitorLogo(
                            size: 56,
                          ),
                          title: Text(
                            'Stop process "${selectedProcess.name}"?',
                            style: MemexTypography.heading4,
                          ),
                          message: const Text(
                            'This will send an interrupt signal to the process.',
                            textAlign: TextAlign.center,
                            style: MemexTypography.heading4,
                          ),
                          primaryButton: PushButton(
                            buttonSize: ButtonSize.large,
                            child: const Text('Stop process'),
                            onPressed: () {
                              interruptProcess(selectedProcess);
                              Navigator.of(context).pop();
                            },
                          ),
                          secondaryButton: PushButton(
                            color: CupertinoColors.systemGrey,
                            buttonSize: ButtonSize.large,
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      });
                }),
            ToolBarPullDownButton(
              label: "Actions",
              icon: CupertinoIcons.ellipsis_circle,
              items: [
                MacosPulldownMenuItem(
                  label: "Show all processes",
                  title: const Text("Show all processes"),
                  onTap: () {
                    filterByUser(false);
                  },
                ),
                MacosPulldownMenuItem(
                  label: "Show my processes",
                  title: const Text("Show my processes"),
                  onTap: () {
                    filterByUser(true);
                  },
                ),
              ],
            ),
            /*const ToolBarSpacer(),
                CustomToolbarItem(inToolbarBuilder: (context) {
                  List<String> segments = ["CPU", "Memory", "Network"];
                  return MacosSegmentedControl(
                    backgroundColor: Colors.transparent,
                    segments: segments.asMap().keys.map((index) {
                      String label = segments[index];
                      SegmentedControlPosition position =
                          SegmentedControlPosition.start;
                      if (index > 0) {
                        position = SegmentedControlPosition.middle;
                        if (index == segments.length - 1) {
                          position = SegmentedControlPosition.end;
                        }
                      }
                      return MacosSegmentedControlSegment<int>(
                        widgetBuilder: (context, active) {
                          return ToolbarTab(
                              label: label, position: position, active: active);
                        },
                        value: index,
                      );
                    }).toList(),
                  );
                }),
                const ToolBarSpacer(),
                CustomToolbarItem(inToolbarBuilder: (context) {
                  return const SizedBox(width: 200, child: MacosSearchField());
                }),
                const ToolBarIconButton( // TODO: Doesn't do anything yet
              label: "Search",
              showLabel: false,
              icon: MacosIcon(CupertinoIcons.search),
            ),*/
            /*ToolBarIconButton(
              label: "Add",
              icon: const MacosIcon(
                CupertinoIcons.add_circled,
              ),
              onPressed: () => debugPrint("Add..."),
              showLabel: true,
            ),
            const ToolBarSpacer(),
            ToolBarIconButton(
              label: "Delete",
              icon: const MacosIcon(
                CupertinoIcons.trash,
              ),
              onPressed: () => debugPrint("Delete"),
              showLabel: false,
            ),*/
          ]),
      builder: (context, scrollController) => TableView(
        rowHeight: 30,
        dataSource: table,
        scrollController: scrollController,
      ),
    );
  }
}
