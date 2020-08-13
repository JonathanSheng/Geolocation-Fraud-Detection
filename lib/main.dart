import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position _currentPosition;
  bool _purchaseSuccessful;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentPosition != null)
              Text(
                  "LAT: ${_currentPosition.latitude}, LNG: ${_currentPosition.longitude}"),
            FlatButton(
              child: Text("Get location"),
              onPressed: () {
                _getCurrentLocation();
              },
            ),
            Text("NY Merchant ID: 5f35733ff1bac107157e1025"),
            Text("CA Merchant ID: 5f358dd4f1bac107157e1057"),
            Text("IL Merchant ID: 5f3573a8f1bac107157e1026"),
            TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Merchant ID'),
                onSubmitted: (String value) {
                  _determinePurchaseValidity(value);
                }),
            if (_purchaseSuccessful != null)
              Text("PURCHASE SUCCESSFUL: $_purchaseSuccessful")
          ],
        ),
      ),
    );
  }

  _getCurrentLocation() {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      print(e);
    });
  }

  _determinePurchaseValidity(String merchantId) async {
    var url =
        'http://api.reimaginebanking.com/merchants/$merchantId?key=83d89cb5e459db4ed2bbd1c278392962';
    var response = await http.get(url);
    var merchantGeocode = Merchant.fromJson(json.decode(response.body));
    var merchantLatitude = merchantGeocode.geocode.lat;
    var merchantLongitude = merchantGeocode.geocode.lng;
    if (_currentPosition != null) {
      var customerLatitude = _currentPosition.latitude;
      var customerLongitude = _currentPosition.longitude;
      setState(() {
        _purchaseSuccessful =
            (merchantLatitude - customerLatitude).abs() <= 1 &&
                (merchantLongitude - customerLongitude).abs() <= 1;
      });
    } else {
      setState(() {
        _purchaseSuccessful = false;
      });
    }
  }
}

class Address {
  final String streetNumber;
  final String streetName;
  final String city;
  final String state;
  final String zip;

  Address(
      {this.streetNumber, this.streetName, this.city, this.state, this.zip});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
        streetNumber: json['street_number'],
        streetName: json['street_name'],
        city: json['city'],
        state: json['state'],
        zip: json['zip']);
  }
}

class Geocode {
  final double lat;
  final double lng;

  Geocode({this.lat, this.lng});

  factory Geocode.fromJson(Map<String, dynamic> json) {
    return Geocode(lat: json['lat'], lng: json['lng']);
  }
}

class Merchant {
  final String id;
  final String name;
  final String category;
  final Address address;
  final Geocode geocode;
  final String creationDate;

  Merchant(
      {this.id,
      this.name,
      this.category,
      this.address,
      this.geocode,
      this.creationDate});

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        address: Address.fromJson(json['address']),
        geocode: Geocode.fromJson(json['geocode']),
        creationDate: json['creation_date']);
  }
}
