import 'package:flutter/material.dart';

class DayPage extends StatefulWidget {
  final TimeOfDay selectedTime;
  final String selectedDay;
  final Function(String) onDayChanged;

  @override
  DayPage({
    super.key,
    required this.selectedTime,
    required this.selectedDay,
    required this.onDayChanged,
  });

  _DayPageState createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  late int selectedDays;
  DateTime today = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  late String selectedDay;
  List<String> daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  List<String> Week = ['Sun', 'Mon', 'Tue', 'Wed', 'Thurs', 'Fri', 'Sat'];
  List<bool> tappedStatus = List.generate(7, (_) => false);

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDay;
    selectedDays = 7 - (selectedDay.split('N').length - 1);
    tappedStatus = List.generate(7, (index) => selectedDay[index] != 'N');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
                selectedDays == 0
                    ? widget.selectedTime.hour < time.hour ||
                            (widget.selectedTime.hour == time.hour &&
                                widget.selectedTime.minute < time.minute)
                        ? 'Tomorrow  ${Week[(today.add(Duration(days: 1)).weekday)%7]}, ${today.add(Duration(days: 1)).day}/${today.add(Duration(days: 1)).month}'
                        : 'Today ${Week[(today.weekday)%7]}, ${today.day}/${today.month}'
                    : selectedDays == 7
                        ? ' Everyday'
                        : ' Every',
                style: const TextStyle(color: Colors.black, fontSize: 17)),
            for (var i = 0; i < 7; i++)
              Text(tappedStatus[i] && selectedDays != 7 ? ' ${Week[i]},' : '',
                  style: const TextStyle(color: Colors.black, fontSize: 17)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < 7; i++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    tappedStatus[i] = !tappedStatus[i];
                    if (tappedStatus[i]) {
                      selectedDays++;
                      selectedDay =
                          selectedDay.replaceRange(i, i + 1, '$i');
                      widget.onDayChanged(selectedDay);
                    } else {
                      selectedDays--;
                      selectedDay = selectedDay.replaceRange(i, i + 1, 'N');
                      widget.onDayChanged(selectedDay);
                    }
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedDay.contains(i.toString())
                        ? Color(0xFF008B8f)
                        : Colors.grey[300],
                    border: Border.all(
                      color: selectedDay.contains(i.toString())
                          ? Color(0xFF008B8f)
                          : Colors.black,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      daysOfWeek[i],
                      style: TextStyle(
                        color: selectedDay.contains(i.toString())
                            ? Colors.white
                            : Colors.grey[700],
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
