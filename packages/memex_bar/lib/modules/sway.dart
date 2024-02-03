import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

enum MessageType {
  RUN_COMMAND,
  GET_WORKSPACES,
  SUBSCRIBE,
  GET_OUTPUTS,
  GET_TREE,
  GET_MARKS,
  GET_BAR_CONFIG,
  GET_VERSION,
  GET_BINDING_MODES,
  GET_CONFIG,
  SEND_TICK,
  SYNC,
  GET_BINDING_STATE,
  GET_INPUTS,
  GET_SEATS,
}

class Rect {
  final int x;
  final int y;
  final int width;
  final int height;

  Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  static Rect fromJson(Map<String, dynamic> json) {
    return Rect(
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
    );
  }
}

class Workspace {
  final int id;
  final String type;
  final String orientation;
  final int? percent;
  final bool urgent;
  final List<String> marks;
  final String layout;
  final String border;
  final int currentBorderWidth;
  final Rect rect;
  final Rect decoRect;
  final Rect windowRect;
  final Rect geometry;
  final String name;
  final int? window;
  final List<int> nodes;
  final List<int> floatingNodes;
  final List<int> focus;
  final int fullscreenMode;
  final bool sticky;
  final int num;
  final String output;
  final String representation;
  final bool focused;
  final bool visible;

  Workspace({
    required this.id,
    required this.type,
    required this.orientation,
    required this.percent,
    required this.urgent,
    required this.marks,
    required this.layout,
    required this.border,
    required this.currentBorderWidth,
    required this.rect,
    required this.decoRect,
    required this.windowRect,
    required this.geometry,
    required this.name,
    required this.window,
    required this.nodes,
    required this.floatingNodes,
    required this.focus,
    required this.fullscreenMode,
    required this.sticky,
    required this.num,
    required this.output,
    required this.representation,
    required this.focused,
    required this.visible,
  });

  static Workspace fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'],
      type: json['type'],
      orientation: json['orientation'],
      percent: json['percent'],
      urgent: json['urgent'],
      marks: List<String>.from(json['marks']),
      layout: json['layout'],
      border: json['border'],
      currentBorderWidth: json['current_border_width'],
      rect: Rect.fromJson(json['rect']),
      decoRect: Rect.fromJson(json['deco_rect']),
      windowRect: Rect.fromJson(json['window_rect']),
      geometry: Rect.fromJson(json['geometry']),
      name: json['name'],
      window: json['window'],
      nodes: List<int>.from(json['nodes']),
      floatingNodes: List<int>.from(json['floating_nodes']),
      focus: List<int>.from(json['focus']),
      fullscreenMode: json['fullscreen_mode'],
      sticky: json['sticky'],
      num: json['num'],
      output: json['output'],
      representation: json['representation'],
      focused: json['focused'],
      visible: json['visible'],
    );
  }
}

// Map MessageType to int
extension MessageTypeExtension on MessageType {
  int get value {
    switch (this) {
      case MessageType.RUN_COMMAND:
        return 0;
      case MessageType.GET_WORKSPACES:
        return 1;
      case MessageType.SUBSCRIBE:
        return 2;
      case MessageType.GET_OUTPUTS:
        return 3;
      case MessageType.GET_TREE:
        return 4;
      case MessageType.GET_MARKS:
        return 5;
      case MessageType.GET_BAR_CONFIG:
        return 6;
      case MessageType.GET_VERSION:
        return 7;
      case MessageType.GET_BINDING_MODES:
        return 8;
      case MessageType.GET_CONFIG:
        return 9;
      case MessageType.SEND_TICK:
        return 10;
      case MessageType.SYNC:
        return 11;
      case MessageType.GET_BINDING_STATE:
        return 12;
      case MessageType.GET_INPUTS:
        return 100;
      case MessageType.GET_SEATS:
        return 101;
    }
  }
}

class SwayIPCConnection {
  // [sway-ipc](https://man.archlinux.org/man/sway-ipc.7.en)
  Socket? socket;

  SwayIPCConnection();

  Future<void> open() async {
    final host = InternetAddress(
      Platform.environment['SWAYSOCK']!,
      type: InternetAddressType.unix,
    );
    socket = await Socket.connect(host, 0);
  }

  Future<(MessageType type, dynamic payload)> send(
      MessageType type, String payload) async {
    List<int> header = [];
    header.addAll(utf8.encode("i3-ipc")); // IPC Magic
    header.addAll(
      Uint32List.fromList([payload.length, type.value]).buffer.asUint8List(),
    );
    header.addAll(utf8.encode(payload));
    socket!.add(header);

    return await receive();
  }

  Future<(MessageType type, dynamic payload)> receive() async {
    Uint8List raw = (await socket!.take(1).toList()).first;

    String magic = utf8.decode(raw.sublist(0, 6));
    if (magic != "i3-ipc") {
      throw Exception("Invalid magic");
    }
    Uint32List headerView = Uint32List.view(raw.sublist(6, 14).buffer);
    int length = headerView[0];
    int type = headerView[1];

    final payload = raw.sublist(14);
    assert(payload.length == length);

    // Parse JSON payload
    final json = jsonDecode(utf8.decode(payload));

    return (MessageType.values[type], json);
  }

  void close() {
    socket?.close();
  }

  Future<List<Workspace>> getWorkspaces() async {
    final (type, List<dynamic> workspaces) =
        await send(MessageType.GET_WORKSPACES, "");
    assert(type == MessageType.GET_WORKSPACES);
    return workspaces
        .map((workspace) => Workspace.fromJson(workspace))
        .toList();
  }
}

class SwayModule extends StatefulWidget {
  const SwayModule({super.key});

  @override
  SwayModuleState createState() => SwayModuleState();
}

class SwayModuleState extends State<SwayModule> {
  SwayIPCConnection connection = SwayIPCConnection();
  Prop<List<Workspace>> workspaces = Prop(<Workspace>[]);

  Future<void> initConnection() async {
    await connection.open();
    workspaces.value = await connection.getWorkspaces();
  }

  @override
  void initState() {
    super.initState();
    initConnection();
  }

  @override
  void dispose() {
    connection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      () => [
        Text(
          "Window Title",
          style: MemexTypography.body.copyWith(fontWeight: FontWeight.bold),
        ),
        ...workspaces.value.map((workspace) => Text(workspace.name)
            .padding(all: 4)
            .highlight(visible: workspace.focused)),
      ].toRow(),
    );
  }
}
