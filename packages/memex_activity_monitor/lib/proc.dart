import 'dart:io';
import 'package:collection/collection.dart';

// How many clock ticks are there per second.
// Initialized using `getconf CLK_TCK` when ProcessInformation is instantiated.
int clockTicksPerSecond = 100;

class ProcessCpuReading {
  // Time spent in user mode
  late int utime;
  // Time spent in kernel mode
  late int stime;
  // When the reading was taken
  late DateTime readTime;

  ProcessCpuReading({
    required this.utime,
    required this.stime,
    required this.readTime,
  });

  ProcessCpuReading.read(int pid) {
    List<String> statWords =
        File('/proc/$pid/stat').readAsStringSync().split(" ");
    utime = int.parse(statWords[14]);
    stime = int.parse(statWords[15]);
    readTime = DateTime.now();
  }

  // Calculate the CPU usage percentage since a given older reading
  double usageSince(ProcessCpuReading lastReading) {
    final int cpuTimeSinceTicks =
        utime - lastReading.utime + stime - lastReading.stime;
    final double secondsSince =
        readTime.difference(lastReading.readTime).inMilliseconds.toDouble() /
            1000;
    final double ticksSince = secondsSince * clockTicksPerSecond.toDouble();
    return cpuTimeSinceTicks / ticksSince;
  }
}

class ProcessInformation {
  int pid;
  int uid;
  String name;
  int memSize;
  int memResident;
  int memShared;

  double? cpuLoad;
  ProcessCpuReading latestCpuReading;

  ProcessInformation({
    required this.pid,
    required this.uid,
    required this.name,
    required this.memSize,
    required this.memResident,
    required this.memShared,
    required this.latestCpuReading,
    this.cpuLoad,
  }) {
    // Update CLOCK_TICKS_PER_SECOND
    clockTicksPerSecond =
        int.parse(Process.runSync('getconf', ['CLK_TCK']).stdout.trim());
  }
}

enum ProcessListOrder { cpuLoad, memory, name, pid }

enum ProcessListOrderDirection { ascending, descending }

class ProcessListFilter {
  // Only show processes of this user
  String? _user;
  String? get user {
    return _user;
  }

  ProcessListOrder? orderBy;
  ProcessListOrderDirection orderDirection;

  set user(String? user) {
    _user = user;
    if (_uid == null && user != null) {
      _uid = int.parse(Process.runSync('id', ['-u', user]).stdout.trim());
    }
    if (user == null) {
      _uid = null;
    }
  }

  int? _uid;

  ProcessListFilter({
    String? user,
    this.orderBy,
    this.orderDirection = ProcessListOrderDirection.descending,
  }) {
    this.user = user;
  }

  // If user is set, get the id of the given user
  int? getUid() {
    return _uid;
  }
}

class SystemInformation {
  // A map from PID to ProcessInformation
  Map<int, ProcessInformation> processes = {};

  // A list of pids which provides an efficient linear ordering of
  // the process entries.
  // This is also where filtering and sorting take place, the process map
  // contains all processes, but only the visible ones are listed in here.
  List<int> pidList = [];

  static List<FileSystemEntity> _getProcessDirectories() {
    Directory proc = Directory("/proc");
    List<FileSystemEntity> procEntries = proc.listSync();
    procEntries.removeWhere((element) {
      // Only keep numeric names (processes)
      return int.tryParse(element.path.split("/").last) == null;
    });
    return procEntries;
  }

  Future<void> updateProcessList(ProcessListFilter? filter) async {
    List<FileSystemEntity> processDirectories = _getProcessDirectories();
    // A list of the PIDs which are currently active.
    // Used to clear out old process data.
    List<int> currentPIDs = [];
    for (FileSystemEntity processDirectory in processDirectories) {
      List<String> statLines = [];
      List<String> statmWords = [];
      int uid = -1;

      try {
        statLines = File('${processDirectory.path}/status').readAsLinesSync();
        uid = int.parse(statLines[8]
            .replaceFirst(r"Uid:", "")
            .trim()
            .split(RegExp(r'\s+'))[0]);
        statmWords = File('${processDirectory.path}/statm')
            .readAsStringSync()
            .split(" ");
      } catch (e) {
        // Process has ended
        continue;
      }

      String name = statLines[0].split(":")[1].trim();
      try {
        // If possible, read the name from the `exe` links basename, as this is not truncated.
        name =
            Link('${processDirectory.path}/exe').targetSync().split("/").last;
      } catch (_) {}

      int pid = int.parse(processDirectory.path.split("/").last);
      currentPIDs.add(pid);

      if (processes.containsKey(pid)) {
        ProcessInformation oldInfo = processes[pid]!;
        ProcessCpuReading currentCpuReading = ProcessCpuReading.read(pid);
        double cpuLoad = currentCpuReading.usageSince(oldInfo.latestCpuReading);
        processes[pid]!
          ..pid = pid
          ..uid = uid
          ..name = name
          ..memSize = int.parse(statmWords[0])
          ..memResident = int.parse(statmWords[1])
          ..memShared = int.parse(statmWords[2])
          ..latestCpuReading = currentCpuReading
          ..cpuLoad = cpuLoad;
      } else {
        processes[pid] = ProcessInformation(
          pid: pid,
          uid: uid,
          name: name,
          memSize: int.parse(statmWords[0]),
          memResident: int.parse(statmWords[1]),
          memShared: int.parse(statmWords[2]),
          latestCpuReading: ProcessCpuReading.read(pid),
        );
      }
    }

    // Filter out old entries.
    currentPIDs.sort();
    List<int> processKeys = processes.keys.toList();
    for (int pid in processKeys) {
      bool processIsStillActive = binarySearch(currentPIDs, pid) != -1;
      if (!processIsStillActive) {
        processes.remove(pid);
      }
    }

    updatePidList(filter);
  }

  // This is where filtering and ordering are implemented
  void updatePidList(ProcessListFilter? filter) {
    Iterable<MapEntry<int, ProcessInformation>> listEntries = processes.entries;

    if (filter?.getUid() != null) {
      listEntries =
          listEntries.where((entry) => entry.value.uid == filter!.getUid());
    }

    if (filter?.orderBy != null) {
      // Create a list to sort
      List<MapEntry<int, ProcessInformation>> listEntriesList =
          listEntries.toList();

      int Function(MapEntry<int, ProcessInformation>,
          MapEntry<int, ProcessInformation>)? sortFunction;

      switch (filter!.orderBy!) {
        case ProcessListOrder.cpuLoad:
          sortFunction =
              (a, b) => (a.value.cpuLoad ?? 0).compareTo(b.value.cpuLoad ?? 0);
          break;
        case ProcessListOrder.memory:
          sortFunction = (a, b) => a.value.memSize - b.value.memSize;
          break;
        case ProcessListOrder.pid:
          sortFunction = (a, b) => a.key - b.key;
          break;
        case ProcessListOrder.name:
          sortFunction = (a, b) => a.value.name.compareTo(b.value.name);
          break;
      }

      listEntriesList.sort((a, b) {
        if (filter.orderDirection == ProcessListOrderDirection.ascending) {
          return sortFunction!(a, b);
        } else {
          return sortFunction!(b, a);
        }
      });

      pidList = listEntriesList.map((entry) => entry.key).toList();
    } else {
      pidList = listEntries.map((entry) => entry.key).toList(growable: false);
    }
  }

  int getProcessListLength() {
    return pidList.length;
  }

  // Get the process at a given index in the list
  ProcessInformation getProcessAtIndex(int index) {
    return processes[pidList[index]]!;
  }
}
