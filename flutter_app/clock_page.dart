import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ClockPage extends StatefulWidget {
  @override
  _ClockPageState createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('online');
  Color _circleColor = Colors.white;
  String _currentTime = '';
  String _currentDate = '';

  late Timer _timer;
  late Timer _colorChangeTimer;
  late Timer _firebaseTimer;

  @override
  void initState() {
    super.initState();
    initializeTimeZones();
    startTimers();
    monitorFirebase();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _resetInteractionTimer();
    });
  }

  void initializeTimeZones() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
  }

  void startTimers() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTime();
    });

    _colorChangeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int lastInteractionTime = DateTime.now().millisecondsSinceEpoch;
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      int difference = (currentTime - lastInteractionTime);
      setState(() {
        _circleColor = difference > 10000 ? Colors.red : Colors.white;
      });
    });
  }

void monitorFirebase() {
  _firebaseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    _databaseReference.once().then((event) {
      var snapshotValue = event.snapshot.value;
      if (snapshotValue != null) {
        int lastLoginTime = snapshotValue as int;
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        int difference = (currentTime - lastLoginTime);
        print("Current Timestamp: $currentTime");
        print("Firebase Value: $lastLoginTime");
        print("Difference: $difference");
        setState(() {
          _circleColor = difference > 10000 ? Colors.red : Colors.green;
        });
      }
    }).catchError((error) {
      print("Error retrieving data: $error");
    });
  });
}









  void _resetInteractionTimer() {
    setState(() {
      _circleColor = Colors.white;
    });
    _colorChangeTimer.cancel();
    _colorChangeTimer = Timer(Duration(minutes: 1), () {
      setState(() {
        _circleColor = Colors.red;
      });
    });
  }

  void _updateTime() {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    setState(() {
      _currentTime = DateFormat.Hm().format(now);
      _currentDate = DateFormat.yMMMMd().format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _colorChangeTimer.cancel();
    _firebaseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clock App'),
      ),
      body: GestureDetector(
        onTap: _resetInteractionTimer,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _circleColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Current Time:',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _currentTime,
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Current Date:',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _currentDate,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Weather in Haifa, Israel:',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Temperature: 25°C',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
