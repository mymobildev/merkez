import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:merkez/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
// test macos
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Stateful Clicker Counter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  GoogleMapController? _gcontroller;
  TextEditingController _addressController = TextEditingController();
  LatLng? _coordinates;
  static const CameraPosition _kGooglePlex = CameraPosition(
    bearing: 0,
    target: LatLng(41.0082, 28.9784),
    tilt: 0,
    zoom: 12,
  );

  static const CameraPosition _kKabe = CameraPosition(
    bearing: 0,
    target: LatLng(21.42264313924608, 39.82618906073263),
    tilt: 0,
    zoom: 19,
  );

  static const CameraPosition _kNebevi = CameraPosition(
    bearing: 0,
    target: LatLng(24.46762345655713, 39.61139385026656),
    tilt: 0,
    zoom: 19,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merkez Harita Uygulaması'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Konum Girin',
                suffixIcon: IconButton(
                  onPressed: () {
                    _findAddressOnMap();
                  },
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAddressToFirestore();
            },
            child: Text('Adresi Kaydet'),
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _gcontroller = controller;
              },
              markers: _coordinates != null ? _createMarkers() : {},
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              _goToTheKabe();
            },
            label: const Text('To the Mekke!'),
            icon: const Icon(Icons.flag),
          ),
          FloatingActionButton.extended(
            onPressed: () {
              _goToTheNebevi();
            },
            label: const Text('To the Mescidi Nebevi!'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
    );
  }

  Future<void> _goToTheKabe() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kKabe));
  }

  Future<void> _goToTheIstanbul() async {
    final GoogleMapController controller = await _controller.future;
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
  }

  Future<void> _goToTheNebevi() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kNebevi));
  }

  Future<void> _findAddressOnMap() async {
    String address = _addressController.text;
    print('Address: ${address}');
    try {
      List<Location> locations = await locationFromAddress(address);
      Location location = locations.first;
      print('Location: ${location}');
      print('Latitude: ${location.latitude}, Longitude: ${location.longitude}');
      setState(() {
        _coordinates = LatLng(location.latitude, location.longitude);
        if (_gcontroller != null) {
          _gcontroller!.animateCamera(CameraUpdate.newLatLng(_coordinates!));
        }
      });
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> _saveAddressToFirestore() async {
    String address = _addressController.text;
    if (address.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('addresses').add({
          'address': address,
          'latitude': _coordinates?.latitude,
          'longitude': _coordinates?.longitude,
        });
        // Başarıyla kaydedildiğine dair bir geri bildirim gösterebilirsiniz
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adres başarıyla kaydedildi!')),
        );
      } catch (e) {
        print('Firestore kaydetme hatası: $e');
        // Hata durumunda bir geri bildirim gösterebilirsiniz
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adres kaydedilirken bir hata oluştu!')),
        );
      }
    } else {
      // Boş adres için bir uyarı gösterebilirsiniz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adres boş olamaz!')),
      );
    }
  }

  Set<Marker> _createMarkers() {
    return {
      Marker(
        markerId: MarkerId('address_marker'),
        position: _coordinates!,
      ),
    };
  }
}
