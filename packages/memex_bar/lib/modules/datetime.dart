import 'dart:async';
import 'package:intl/intl.dart';

import 'package:memex_ui/memex_ui.dart';

class DateTimeModule extends ReactiveWidget {
  final Prop<DateTime> _dateTime = Prop(DateTime.now());

  DateTimeModule({super.key}) {
    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _dateTime.value = DateTime.now();
      },
    );
  }

  final DateFormat dateFormatter = DateFormat('E MMM dd');
  final DateFormat timeFormatter = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    DateTime now = _dateTime.value;
    String date = dateFormatter.format(now);
    String time = timeFormatter.format(now);

    return Text(
      "$date $time",
      style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
