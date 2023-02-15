import 'package:flutter/painting.dart';

class LinkSpan extends TextSpan {
  final String target;
  const LinkSpan({
    required this.target,
    super.text,
    super.style,
  });
}
