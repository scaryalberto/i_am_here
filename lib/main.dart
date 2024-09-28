import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences
import 'dart:async'; // Importa dart:async per Timer

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Permission App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Imposta lo SplashScreen come home
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer di 2 secondi per passare alla home page
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Colore di sfondo dello splash screen
      body: Center(
        child: Text(
          'Benvenuto!',
          style: TextStyle(
            fontSize: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _locationMessage = "Nessuna posizione disponibile";

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() {
        _locationMessage = "Permesso GPS non concesso";
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationMessage = "Ultima posizione: ${position.latitude}, ${position.longitude}";
    });
  }

  void _printMessage() {
    print(_locationMessage);
  }

  void _navigateToSecondPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecondPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Permission App'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Second Page'),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer prima di navigare
                _navigateToSecondPage(); // Naviga alla seconda pagina
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _printMessage,
              child: Text('Premi qui per stampare la posizione!'),
            ),
            SizedBox(height: 20),
            Text(_locationMessage),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final TextEditingController _phoneController = TextEditingController();

  // Funzione per salvare il numero
  Future<void> _savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Numero di telefono salvato: $phoneNumber')),
    );
  }

  // Funzione per stampare il numero di telefono
  Future<void> _printPhoneNumber() async {
    String phoneNumber = _phoneController.text;
    _savePhoneNumber(phoneNumber);
    print('Numero di telefono inserito: $phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Inserisci il tuo numero di telefono',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printPhoneNumber,
              child: Text('Stampa numero'),
            ),
          ],
        ),
      ),
    );
  }
}
