import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For date formatting

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  DatabaseReference _tasksReference =
      FirebaseDatabase.instance.reference().child('Tasks');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController _taskController = TextEditingController();

  void _addTask() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Manager',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
ElevatedButton(
  onPressed: () async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (pickedTime != null && pickedTime != _selectedTime) {
                      setState(() {
                        _selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Text('Choose Time'),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Enter Task',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Add Task'),
            ),
            SizedBox(height: 16),
            Expanded(
                                child: StreamBuilder<DataSnapshot>(
                    stream: _tasksReference.onValue.map((event) => event.snapshot),
                    builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData || snapshot.data!.value == null) {
                        return Center(child: Text('No tasks for this date'));
                      } else {
                        Map<dynamic, dynamic> tasks = snapshot.data!.value as Map<dynamic, dynamic>;
                        List<Widget> taskWidgets = [];
                        tasks.forEach((key, value) {
                          if (value['date'] == DateFormat('ddMMyy').format(_selectedDate)) {
                            taskWidgets.add(
                              ListTile(
                                title: Text(
                                  value['msg'],
                                  style: TextStyle(fontSize: 18),
                                ),
                                subtitle: Text(
                                  'Time: ${value['time']}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteTask(key),
                                ),
                              ),
                            );
                          }
                        });
                        return ListView(
                          children: taskWidgets,
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
