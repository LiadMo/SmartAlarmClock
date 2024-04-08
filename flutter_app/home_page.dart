import 'package:flutter/material.dart';
import 'alarm_page.dart';
import 'settings_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'clock_page.dart';
import 'tasks_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ClockPage(),
    AlarmPage(),
    TasksPage(),
    SettingsPage(),
  ];

  // Reference to the Firebase Realtime Database
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  // Function to push the current time to the RTDB
  void _pushCurrentTimeToDatabase() {
    _databaseReference.child('timestamp').set(ServerValue.timestamp);
  }

  @override
  Widget build(BuildContext context) {
    // Push the current time to RTDB when entering the HomePage
    _pushCurrentTimeToDatabase();

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome to the Home Page!'),
    );
  }
}
