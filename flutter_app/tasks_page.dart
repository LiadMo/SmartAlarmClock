import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/services.dart'; // For text input formatter

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DatabaseReference _tasksReference =
      FirebaseDatabase.instance.reference().child('App/Tasks');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController _taskController = TextEditingController();

  void _addTask() {
    // Check if selected date is in the future
    DateTime selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (selectedDateTime.isBefore(DateTime.now())) {
      // If selected date is in the past, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a future date and time."),
        ),
      );
      return;
    }

    String formattedDate = DateFormat('ddMMyy').format(_selectedDate);
    String taskId = _tasksReference.push().key!;
    String formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    _tasksReference.child(taskId).set({
      'id': taskId,
      'date': formattedDate,
      'time': formattedTime,
      'msg': _taskController.text,
    });
    _taskController.clear();
  }

  void _deleteTask(String taskId) {
    _tasksReference.child(taskId).remove();
  }

  String formatFirebaseDate(String firebaseDate) {
    if (firebaseDate.length == 6) {
      String formattedDate =
          '${firebaseDate.substring(0, 2)}/${firebaseDate.substring(2, 4)}/${firebaseDate.substring(4)}';
      return formattedDate;
    } else {
      return firebaseDate; // Return as is if not in the expected format
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Manager',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    'Choose Date',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Select Time',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time),
                        SizedBox(width: 8),
                        Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Text(
                    'Choose Time',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _taskController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')), // Allow English letters, numbers, and whitespaces
                LengthLimitingTextInputFormatter(20), // Limit input to 20 characters
              ],
              decoration: InputDecoration(
                hintText: 'Enter task (1-20 characters)',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {}); // Update UI on text change
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _taskController.text.isNotEmpty &&
                      _taskController.text.length >= 1 &&
                      _taskController.text.length <= 20
                  ? _addTask
                  : null,
              child: Text('Add Task'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DataSnapshot>(
                stream: _tasksReference.onValue.map((event) => event.snapshot),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.value != null &&
                      (snapshot.data!.value as Map).isNotEmpty) {
                    Map<dynamic, dynamic> tasks =
                        Map<dynamic, dynamic>.from(snapshot.data!.value as Map);
                    
                    // Convert tasks map to list for sorting
List<Map<dynamic, dynamic>> sortedTasks = tasks.values.map<Map<dynamic, dynamic>>((task) => task as Map<dynamic, dynamic>).toList();

// Sort tasks by date and time
sortedTasks.sort((a, b) {
  // Compare dates
  int dateComparison = a['date'].compareTo(b['date']);
  if (dateComparison != 0) {
    return dateComparison;
  }
  
  // If dates are same, compare times
  return a['time'].compareTo(b['time']);
});


                    return ListView.builder(
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        var task = sortedTasks[index];
                        return ListTile(
                          title: Text(task['msg']),
                          subtitle: Text('${formatFirebaseDate(task['date'])} ${task['time']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteTask(task['id']);
                            },
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text(
                        'No upcoming tasks',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
