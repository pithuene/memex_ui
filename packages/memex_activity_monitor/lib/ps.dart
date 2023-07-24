import 'dart:io';
import 'dart:convert';

class ProcessInformation {
  String COMM;
  double PERCENT_MEM;
  double PERCENT_CPU;

  ProcessInformation(
    this.COMM,
    this.PERCENT_MEM,
    this.PERCENT_CPU,
  );
}

class PsOutputProperty{
  // The offset at which the property value starts
  int start;
  // The offset at which the property value ends
  int end;
  // The name of the format option (e.g. COMM, %MEM, ...)
  String formatOption;
  PsOutputProperty(this.formatOption)
    : start = 0, end = 0;
}

class PsReader {
  List<PsOutputProperty> properties = [];

  PsReader() {
    List<String> formatOptions = ["COMM", "%MEM", "%CPU"];
    for (String formatOption in formatOptions) {
      properties.add(PsOutputProperty(formatOption));
    }
  }

  Future<List<ProcessInformation>> run() async {
    List<String> psArgs = [
      '-M',
      '-U', 'pit'
    ];
    for (PsOutputProperty prop in properties) {
      psArgs.addAll(['-o', prop.formatOption]);
    }

    ProcessResult result = await Process.run('ps', psArgs);
    LineSplitter ls = const LineSplitter();
    List<String> lines = ls.convert(result.stdout);

    calculatePropertyOffsets(lines[0]);

    List<ProcessInformation> processes = lines.getRange(1, lines.length).map((line) {
      return ProcessInformation(
        line.substring(properties[0].start, properties[0].end).trim(),
        double.parse(line.substring(properties[1].start, properties[1].end).trim()),
        double.parse(line.substring(properties[2].start, properties[2].end).trim())
      );
    }).toList();
    processes.sort((a, b) {
      double diff = b.PERCENT_CPU - a.PERCENT_CPU;
      if (diff < 0) {
        return -1;
      } else if (diff > 0) {
        return 1;
      } else {
        return 0;
      }
    });
    return processes;
  }

  // Read out the offsets at which properties start and end from the header line.
  void calculatePropertyOffsets(String headerLine) {
      bool isOverSpace = true;
      int propertyIndex = -1;
      for (int i = 0; i < headerLine.length; i++) {
        if (headerLine.codeUnitAt(i) != " ".codeUnitAt(0)) {
          if (isOverSpace) {
            // First character of new word
            propertyIndex++;
            properties[propertyIndex].start = i;
          }
          isOverSpace = false;
        } else {
          isOverSpace = true;
        }
      }

      properties.last.end = headerLine.length;
      for (int i = properties.length - 2; i >= 0; i--) {
        properties[i].end = properties[i + 1].start - 1;
      }
  }
}
