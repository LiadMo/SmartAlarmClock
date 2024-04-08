import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class TimePickerWidget extends StatefulWidget {
  final TimeOfDay selectedTime;
  final Function(TimeOfDay) onTimeChanged;

  TimePickerWidget({
    required this.selectedTime,
    required this.onTimeChanged,
  });

  @override
  _TimePickerWidgetState createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        NumberPicker(
          minValue: 0,
          maxValue: 23,
          value: selectedTime.hour,
          zeroPad: true,
          infiniteLoop: true,
          itemWidth: 80,
          itemHeight: 70,
          onChanged: (value) {
            setState(() {
              selectedTime = selectedTime.replacing(hour: value);
              widget.onTimeChanged(selectedTime); // Invoke the callback function
            });
          },
          textStyle: const TextStyle(color: Colors.grey, fontSize: 25),
          selectedTextStyle:
          const TextStyle(color: Color(0xFF008B8f), fontSize: 40),
        ),
        const Text(':', style: TextStyle(color: Color(0xFF008B8f), fontSize: 45)),
        NumberPicker(
          minValue: 0,
          maxValue: 59,
          value: selectedTime.minute,
          zeroPad: true,
          infiniteLoop: true,
          itemWidth: 80,
          itemHeight: 70,
          onChanged: (value) {
            setState(() {
              selectedTime = selectedTime.replacing(minute: value);
              widget.onTimeChanged(selectedTime); // Invoke the callback function
            });
          },
          textStyle: const TextStyle(color: Colors.grey, fontSize: 25),
          selectedTextStyle:
          const TextStyle(color: Color(0xFF008B8f), fontSize: 40),
        ),
      ],
    );
  }
}
