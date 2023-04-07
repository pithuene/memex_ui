import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

final searchbarSocketAddress = InternetAddress.fromRawAddress(
  Uint8List.fromList(utf8.encode("/tmp/memex_searchbar.sock")),
  type: InternetAddressType.unix,
);

class SearchbarEntry {
  String title;
  String description;
  var data;

  SearchbarEntry({
    required this.title,
    this.description = "",
    this.data,
  });

  SearchbarEntry.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        data = json['data'];

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "data": data.toJson(),
    };
  }
}

StreamChannel<String> socketToStreamChannel(Socket socket) {
  var channelSink = StreamController<String>();
  socket.addStream(channelSink.stream.map((event) => utf8.encode(event)));
  return StreamChannel(
    socket.map((msg) => utf8.decode(msg)),
    channelSink.sink,
  );
}

Future<SearchbarEntry> openSearchbar(List<SearchbarEntry> entries) async {
  final clientSocket = await Socket.connect(searchbarSocketAddress, 0);
  Client client = Client(socketToStreamChannel(clientSocket));
  var clientConnection = client.listen();
  var result = await client.sendRequest("openSearchbar", entries);
  client.close();
  await clientConnection;
  return result;
}
