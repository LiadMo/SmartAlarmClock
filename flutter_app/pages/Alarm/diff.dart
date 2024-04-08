import 'package:flutter/material.dart';

class DifficultySelection extends StatefulWidget {
  final int selectedDifficulty;
  final Function(int) onDifficultyChanged;

  @override
  DifficultySelection({
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  _DifficultySelectionState createState() => _DifficultySelectionState();
}

class _DifficultySelectionState extends State<DifficultySelection> {
  late int selectedDifficulty;

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Difficulty level',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ),
        Row(
          children: [
            DropdownButtonExample(
              selectedDifficulty: selectedDifficulty,
              onDifficultyChanged: widget.onDifficultyChanged,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF008B8f), size: 30),
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class DropdownButtonExample extends StatefulWidget {
  final int selectedDifficulty;
  final Function(int) onDifficultyChanged;

  @override
  DropdownButtonExample({
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  _DropdownButtonExampleState createState() => _DropdownButtonExampleState();
}

class _DropdownButtonExampleState extends State<DropdownButtonExample> {
  late String selectedValue = 'Level ${widget.selectedDifficulty}';
  late int selectedDifficulty;

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      dropdownColor: Colors.grey[200],
      value: selectedValue,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 25,),
      onChanged: (String? newValue) {
        setState(() {
          selectedValue = newValue!;
          selectedDifficulty = int.parse(selectedValue.substring(6, 7));
          widget.onDifficultyChanged(selectedDifficulty);
        });
      },
      style: const TextStyle(fontSize: 17, color: Colors.black),
      items: const [
        DropdownMenuItem<String>(
          value: "Level 1",
          child: Text("Level 1"),
        ),
        DropdownMenuItem<String>(
          value: "Level 2",
          child: Text("Level 2"),
        ),
        DropdownMenuItem<String>(
          value: "Level 3",
          child: Text("Level 3"),
        ),
      ],
    );
  }
}

class NewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Alarm difficulty levels', style: TextStyle(color: Color(0xFF008B8f))),
        backgroundColor: Colors.grey[300],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Color(0xFF008B8f), // Set the back button icon color to blue
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'You can choose how to wake in morning: \n\n'
              '1) normal press - you simply press the alarm button to turn off the alarm\n\n'
              '2) long press - you need to press for 10 seconds to turn off the alarm, maybe that will help you get off your bed\n\n'
              '3) Playing a game - if you are like many people, constantly snoozing the alarm to sleep that extra few minutes,'
              ' you can choose to turn off the alarm by playing a snake game and reaching 5 points to ultimately turn off the alarm to '
              'feel awake enough to not get back to sleep!',
          style: TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}