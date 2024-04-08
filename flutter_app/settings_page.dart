import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _brightness;
  late double _volume;
  late String _selectedLanguage;
  late String _selectedRingtone; // New variable for selected ringtone
  late bool _initialValuesLoaded;

  @override
  void initState() {
    super.initState();
    _brightness = 5.0;
    _volume = 5.0;
    _selectedLanguage = 'english';
    _selectedRingtone = 'ringtone1'; // Default ringtone
    _initialValuesLoaded = false;
    _fetchInitialValues();
  }

  Future<void> _fetchInitialValues() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DatabaseEvent event = await ref.child('App/settings').once();

      Map<String, dynamic>? settings =
          (event.snapshot.value as Map<dynamic, dynamic>?)?.cast<String, dynamic>();
      if (settings != null) {
        setState(() {
          _brightness = (settings['brightness'] ?? 5).toDouble();
          _volume = (settings['volume'] ?? 5).toDouble();
          _selectedLanguage = settings['language'] ?? 'english';
          _selectedRingtone = settings['ringtone'] ?? 'ringtone1'; // Load selected ringtone
          _initialValuesLoaded = true;
        });
      }
    } catch (error) {
      print('Error fetching initial values: $error');
      // Handle the error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _initialValuesLoaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brightness',
                    style: TextStyle(fontSize: 18),
                  ),
                  Slider(
                    value: _brightness,
                    onChanged: (value) {
                      setState(() {
                        _brightness = value;
                      });
                    },
                    onChangeEnd: (_) {
                      _updateFirebaseDatabase();
                    },
                    min: 0.0,
                    max: 10.0,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Volume',
                    style: TextStyle(fontSize: 18),
                  ),
                  Slider(
                    value: _volume,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                    },
                    onChangeEnd: (_) {
                      _updateFirebaseDatabase();
                    },
                    min: 0.0,
                    max: 15.0,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Language',
                    style: TextStyle(fontSize: 18),
                  ),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue!;
                      });
                      _updateFirebaseDatabase();
                    },
                    items: <String>['hebrew', 'english', 'arabic']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ringtone',
                    style: TextStyle(fontSize: 18),
                  ),
                  DropdownButton<String>(
                    value: _selectedRingtone,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRingtone = newValue!;
                      });
                      _updateFirebaseDatabase(); // Update Firebase with selected ringtone
                    },
                    items: <String>['ringtone1', 'ringtone2', 'ringtone3'] // Add your ringtone options here
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  void _updateFirebaseDatabase() {
    // Ensure values are within the range of 0 to 10
    double normalizedBrightness = _brightness.clamp(0.0, 10.0);
    double normalizedVolume = _volume.clamp(0.0, 10.0);

    // Round the normalized values
    int roundedBrightness = normalizedBrightness.round();
    int roundedVolume = normalizedVolume.round();

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    ref.child('App/settings').set({
      'brightness': roundedBrightness,
      'volume': roundedVolume,
      'language': _selectedLanguage,
      'ringtone': _selectedRingtone, // Update Firebase with selected ringtone
    });

    // Update the "updated" field to 1
    ref.child('updated').set(1);
  }
}
