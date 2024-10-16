import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences
import 'package:telephony/telephony.dart'; // Importa la libreria telephony
import 'package:contacts_service/contacts_service.dart'; // Importa la libreria contacts_service
import 'dart:async';

import 'package:url_launcher/url_launcher.dart'; // Importa dart:async per Timer

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
  String? lastPhoneNumber;
  String? lastContactName; // Memorizza il nome del contatto
  bool _isLoadingContacts = false;
  bool _isLocationAvailable = false; // Variabile per controllare lo stato della posizione

  @override
  void initState() {
    super.initState();
    _loadLastContactInfo(); // Carica il nome e numero dell'ultimo contatto all'avvio
    _requestLocationPermission();
  }

  Future<void> _loadLastContactInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lastPhoneNumber = prefs.getString('phone_number');
      lastContactName = prefs.getString('contact_name'); // Carica il nome del contatto
    });
  }

  Future<void> _saveLastContactInfo(String phoneNumber, String contactName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber);
    await prefs.setString('contact_name', contactName); // Salva il nome del contatto
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() {
        _locationMessage = "Permesso GPS non concesso";
        _isLocationAvailable = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationMessage = "Posizione rilevata";
        _isLocationAvailable = true; // La posizione è disponibile, abilita il pulsante
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Errore nel rilevamento della posizione";
        _isLocationAvailable = false;
      });
    }
  }

  Future<void> _sendSms() async {
    if (lastPhoneNumber != null) {
      final Telephony telephony = Telephony.instance;

      // Richiede i permessi per inviare SMS
      bool? permissionsGranted = await telephony.requestSmsPermissions;

      if (permissionsGranted ?? false) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          String message = "Ciao. La mia posizione è questa: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

          // Invia l'SMS
          await telephony.sendSms(
            to: lastPhoneNumber!,
            message: message,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SMS inviato a $lastContactName')), // Mostra il nome del contatto
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'invio dell\'SMS')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permessi SMS non concessi')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nessun contatto salvato')),
      );
    }
  }

  Future<void> _selectContact() async {
    // Mostra il logo di caricamento
    setState(() {
      _isLoadingContacts = true;
    });

    // Richiedi permesso per accedere ai contatti
    var status = await Permission.contacts.request();

    if (status.isGranted) {
      // Apri la lista dei contatti
      Iterable<Contact> contacts = await ContactsService.getContacts();
      Contact? selectedContact = await showDialog<Contact>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Seleziona un contatto'),
            content: SingleChildScrollView(
              child: ListBody(
                children: contacts.map((Contact contact) {
                  return ListTile(
                    title: Text(contact.displayName ?? ''),
                    onTap: () {
                      Navigator.of(context).pop(contact);
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );

      // Usa il contatto selezionato
      if (selectedContact != null && selectedContact.phones != null && selectedContact.phones!.isNotEmpty) {
        String phoneNumber = selectedContact.phones!.first.value!;
        String contactName = selectedContact.displayName ?? "Sconosciuto"; // Nome del contatto
        setState(() {
          lastPhoneNumber = phoneNumber;
          lastContactName = contactName;
          _locationMessage = "Posizione rilevata. Il messaggio verrà inviato a $contactName";
        });

        // Salva il nome e il numero del contatto selezionato
        _saveLastContactInfo(phoneNumber, contactName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permessi contatti non concessi')),
      );
    }

    // Nascondi il logo di caricamento
    setState(() {
      _isLoadingContacts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Io sono qui'),
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
              title: Text('Credenziali'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CredentialsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _selectContact,
                child: Text('Scegli destinatario'),
              ),
              SizedBox(height: 20),
              _isLoadingContacts
                  ? CircularProgressIndicator() // Mostra il logo di caricamento se sta caricando i contatti
                  : ElevatedButton(
                onPressed: _isLocationAvailable ? _sendSms : null, // Disabilita il pulsante se la posizione non è disponibile
                child: Text('Invia posizione via SMS'),
              ),
              SizedBox(height: 20),
              Text(_locationMessage),
            ],
          ),
        ),
      ),
    );
  }
}

class CredentialsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credenziali'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Io sono qui:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Applicazione per inviare la propria posizione a qualsiasi numero in rubrica usando un SMS.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            Text(
              'Versione: 1.0.0', // Specifica qui la versione
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                launch('https://github.com/scaryalberto/i_am_here'); // Inserisci il link al tuo progetto GitHub
              },
              child: Text(
                'Progetto GitHub',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                launch('https://www.linkedin.com/in/alberto-aniello-scaringi-755b4a120/'); // Inserisci il link alla tua pagina LinkedIn
              },
              child: Text(
                'LinkedIn - Autore',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
