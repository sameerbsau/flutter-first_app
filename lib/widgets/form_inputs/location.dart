import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:location/location.dart' as geoloc;

import '../../models/location_data.dart';
import '../../models/product.dart';
import '../../shared/global_config.dart';

class LocationInput extends StatefulWidget {
  final Function locationData;
  final Product product;
  LocationInput(this.locationData, this.product);
  @override
  State<StatefulWidget> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  final FocusNode _addressInputFocusNode = FocusNode();
  LocationData _locationData;
  final TextEditingController _addressInputController = TextEditingController();
  Uri _staticMapUri;

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.product != null) {
      getStaticMap(widget.product.locationData.address, geocode: false);
    }
    super.initState();
  }

  void getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      widget.locationData(null);
      setState(() {
        _staticMapUri = null;
      });
      return;
    }
    if (geocode) {
      Uri uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {'address': address, 'key': apiey},
      );

      http.Response response;
      try {
        response = await http.get(uri);
      } catch (e) {
        print('there is an error');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _locationData = LocationData(
            address: 'test', longitude: 17.448294, lattitude: 78.391487);
      } else {
        final decodedResponse = json.decode(response.body);

        final formattedAddress =
            decodedResponse['results'][0]['formatted_address'];
        final coords = decodedResponse['results'][0]['geometry']['location'];
        _locationData = LocationData(
            lattitude: coords['lat'],
            longitude: coords['lng'],
            address: formattedAddress);
      }
    } else if (lat == null && lng == null) {
      _locationData = widget.product.locationData;
    } else {
      _locationData =
          LocationData(address: address, lattitude: lat, longitude: lng);
    }
    if (mounted) {
      final StaticMapProvider staticMapProvider =
          StaticMapProvider(apiey);
      final Uri staticMapUri = staticMapProvider.getStaticUriWithMarkers([
        Marker('position', 'Position', _locationData.lattitude,
            _locationData.longitude)
      ],
          center: Location(_locationData.lattitude, _locationData.longitude),
          width: 500,
          height: 300,
          maptype: StaticMapViewType.roadmap);

      widget.locationData(_locationData);
      setState(() {
        _addressInputController.text = _locationData.address;
        _staticMapUri = staticMapUri;
      });
    }
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      getStaticMap(_addressInputController.text);
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '${lat.toString()},${lng.toString()}',
        'key': apiey
      },
    );
    http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];
    return formattedAddress;
  }

  void _getUserLocation() async {
    final location = geoloc.Location();
    try {
      final currentLocation = await location.getLocation();
      final address = await _getAddress(
          currentLocation['latitude'], currentLocation['longitude']);
      getStaticMap(address,
          geocode: false,
          lat: currentLocation['latitude'],
          lng: currentLocation['longitude']);
    } catch (e) {
      print(e);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text('Could not fetch location'),
                content: Text('PLease add address manually'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Ok'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ]);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: _addressInputFocusNode,
          controller: _addressInputController,
          validator: (String value) {
            if (value.isEmpty) {
              return 'Entered address is not valid';
            }
          },
          decoration: InputDecoration(labelText: 'Addesss'),
        ),
        SizedBox(
          height: 10.0,
        ),
        FlatButton(
          child: Text('Locate User'),
          onPressed: _getUserLocation,
        ),
        SizedBox(
          height: 10.0,
        ),
        _staticMapUri == null ? Container() : Container()
        // : Image.network(_staticMapUri.toString())
      ],
    );
  }
}
