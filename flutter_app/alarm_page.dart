import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class AlarmSettings {
  final String id;
  final DateTime dateTime;
  final String? message;
  final Map<String, bool> selectedDays;

  AlarmSettings({
    required this.id,
    required this.dateTime,
    this.message,
    required this.selectedDays,
  });

  AlarmSettings copyWith({
    String? id,
    DateTime? dateTime,
    String? message,
    Map<String, bool>? selectedDays,
  }) {
    return AlarmSettings(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      message: message ?? this.message,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  List<AlarmSettings> alarms = [];
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    fetchAlarms();
  }

  Future<void> fetchAlarms() async {
    if (isFetching) {
      return;
    }

    isFetching = true;

    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference().child('App/alarms');

    try {
      DatabaseEvent event = await databaseReference.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? alarmsData =
            snapshot.value as Map<dynamic, dynamic>?;

        if (alarmsData != null) {
          List<AlarmSettings> newAlarms = [];

          alarmsData.forEach((key, value) {
            final alarm = AlarmSettings(
              id: value['id'],
              dateTime: DateFormat('HH:mm').parse(value['dateTime']),
              message: value['message'],
              selectedDays: Map<String, bool>.from(value['selectedDays']),
            );

            newAlarms.add(alarm);
          });

          setState(() {
            alarms = newAlarms;
          });
        }
      }
    } catch (error) {
      print('Error fetching alarms: $error');
    } finally {
      isFetching = false;
    }
  }

  void removeAlarm(AlarmSettings alarm) {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference().child('App/alarms');

    databaseReference.child(alarm.id).remove().then((_) {
      FirebaseDatabase.instance.reference().child('updated').set(1);
    });

    setState(() {
      alarms.remove(alarm);
    });
  }

  Future<void> showAlarmConfigPopup(BuildContext context,
      {AlarmSettings? alarm}) async {
    final editedAlarm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(alarm == null ? 'Add Alarm' : 'Edit Alarm'),
          content: AlarmConfigForm(alarm: alarm),
        );
      },
    );

    if (editedAlarm != null) {
      if (alarm == null) {
        addAlarm(editedAlarm as AlarmSettings);
      } else {
        updateAlarm(editedAlarm as AlarmSettings);
      }
    }
  }

  void addAlarm(AlarmSettings newAlarm) {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference().child('App/alarms');

    final newAlarmRef = databaseReference.push();

    newAlarmRef.set({
      'id': newAlarmRef.key,
      'dateTime': DateFormat('HH:mm').format(newAlarm.dateTime),
      'message': newAlarm.message,
      'selectedDays': newAlarm.selectedDays,
    }).then((_) {
      FirebaseDatabase.instance.reference().child('updated').set(1);
    });

    setState(() {
      alarms.add(newAlarm.copyWith(id: newAlarmRef.key));
    });
  }

  void updateAlarm(AlarmSettings editedAlarm) {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference().child('App/alarms');

    databaseReference.child(editedAlarm.id).update({
      'dateTime': DateFormat('HH:mm').format(editedAlarm.dateTime),
      'message': editedAlarm.message,
      'selectedDays': editedAlarm.selectedDays,
    }).then((_) {
      FirebaseDatabase.instance.reference().child('updated').set(1);
    });

    setState(() {
      final index = alarms.indexWhere((alarm) => alarm.id == editedAlarm.id);
      if (index != -1) {
        alarms[index] = editedAlarm;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarms'),
      ),
      body: alarms.isEmpty
          ? Center(
              child: Text('No available alarms'),
            )
          : ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return GestureDetector(
                  onTap: () => showAlarmConfigPopup(context, alarm: alarm),
                  child: Dismissible(
                    key: Key(alarm.id),
                    onDismissed: (direction) {
                      removeAlarm(alarm);
                    },
                    background: Container(
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                    ),
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Alarm at ${DateFormat('HH:mm').format(alarm.dateTime)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Days: ${getFormattedDays(alarm.selectedDays)}\nMessage: ${alarm.message ?? "No message"}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAlarmConfigPopup(context),
        child: Icon(Icons.add),
      ),
    );
  }

  String getFormattedDays(Map<String, bool>? selectedDays) {
    if (selectedDays == null || selectedDays.isEmpty) {
      return 'No days selected';
    }

    final List<String> days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final List<String> selectedDaysList = [];

    for (int i = 0; i < 7; i++) {
      final day = days[i];
      final bool? isSelected = selectedDays[day];
      if (isSelected != null && isSelected) {
        selectedDaysList.add(day.substring(0, 3)); // Abbreviate the day
      }
    }

    return selectedDaysList.isEmpty ? 'No days selected' : selectedDaysList.join(", ");
  }
}

class AlarmConfigForm extends StatefulWidget {
  final AlarmSettings? alarm;

  const AlarmConfigForm({Key? key, this.alarm}) : super(key: key);

  @override
  _AlarmConfigFormState createState() => _AlarmConfigFormState();
}

class _AlarmConfigFormState extends State<AlarmConfigForm> {
  late DateTime selectedDateTime;
  late List<bool> selectedDays;
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.alarm?.dateTime ?? DateTime.now().add(Duration(minutes: 1));
    selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
    selectedDays = widget.alarm?.selectedDays.values.toList() ?? List.filled(7, false);
    messageController = TextEditingController(text: widget.alarm?.message ?? '');
  }

  Future<void> pickTime() async {
    final res = await showTimePicker(
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      context: context,
    );

    if (res != null) {
      setState(() {
        final DateTime now = DateTime.now();
        selectedDateTime = now.copyWith(
          hour: res.hour,
          minute: res.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(Duration(days: 1));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RawMaterialButton(
          onPressed: pickTime,
          fillColor: Colors.grey[200],
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Text(
              TimeOfDay.fromDateTime(selectedDateTime).format(context),
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Select days for the alarm:',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            7,
            (index) {
              final day = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index];
              final isSelected = selectedDays[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDays[index] = !isSelected;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
        SizedBox(height: 20),
        TextField(
          controller: messageController,
          decoration: InputDecoration(
            labelText: 'Optional Message',
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            final newAlarm = AlarmSettings(
              id: widget.alarm?.id ?? '',
              dateTime: selectedDateTime,
              message: messageController.text.isNotEmpty ? messageController.text : null,
              selectedDays: Map.fromIterables(
                ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
                selectedDays,
              ),
            );

            Navigator.pop(context, newAlarm);
          },
          child: Text('Save Alarm'),
        ),
      ],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AlarmPage(),
    );
  }
}
