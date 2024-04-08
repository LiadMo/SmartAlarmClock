import 'package:flutter/material.dart';

class NameSelection extends StatefulWidget {
  final String selectedName;
  final Function(String) onNameChange;

  NameSelection({
    required this.selectedName,
    required this.onNameChange,
  });

  @override
  _NameSelectionState createState() => _NameSelectionState();
}

class _NameSelectionState extends State<NameSelection> {
  late String selectedName;

  @override
  void initState() {
    super.initState();
    selectedName = widget.selectedName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Alarm name',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.topLeft,
          child: NameContainer(
            selectedName: selectedName,
            onNameChange: widget.onNameChange,
          ),
        ),
      ],
    );
  }
}

class NameContainer extends StatefulWidget {
  final String selectedName;
  final Function(String) onNameChange;

  NameContainer({
    required this.selectedName,
    required this.onNameChange,
  });

  @override
  _NameContainerState createState() => _NameContainerState();
}

class _NameContainerState extends State<NameContainer> {
  late String name;

  @override
  void initState() {
    super.initState();
    name = widget.selectedName;
  }

  Future<void> _openDialog() async {
    final enteredName = await showDialog<String>(
      context: context,
      builder: (context) => NameInputDialog(selectedName: name),
    );

    if (enteredName != null) {
      setState(() {
        name = enteredName;
        widget.onNameChange(name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDialog,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 20,
            color: Colors.grey[300],
            child: Text(
              name.isNotEmpty ? name : 'Enter Name',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NameInputDialog extends StatefulWidget {
  final String selectedName;

  NameInputDialog({
    required this.selectedName,
  });

  @override
  _NameInputDialogState createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late String? name;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    name = widget.selectedName;
    _textEditingController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[300],
      title: const Text('Enter Name', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: TextField(
          controller: _textEditingController,
          style: const TextStyle(color: Colors.black),
          enableInteractiveSelection: true, 
          decoration: const InputDecoration(
            hintText: 'Alarm name',
            hintStyle: TextStyle(color: Colors.black),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog without saving the name
          },
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor: MaterialStateProperty.all<Color>(Colors.grey[300]!),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF008B8f), fontSize: 20),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final enteredName = _textEditingController.text;
            Navigator.pop(context, enteredName); // Pass the entered name back to the caller
          },
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor: MaterialStateProperty.all<Color>(Colors.grey[300]!),
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: Color(0xFF008B8f), fontSize: 20),
          ),
        ),
      ],
    );
  }
}
