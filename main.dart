import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  List<LatLng> _polylineCoordinates = [];
  Polyline _polyline = Polyline(
    polylineId: PolylineId('tracking_polyline'),
    color: Colors.blue,
    width: 5,
  );

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitialize();
  }

  Future<void> _requestPermissionAndInitialize() async {
    await _requestLocationPermission();
    await _animateToUserLocation();
    _startLocationUpdates();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _animateToUserLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
    _addMarker(_currentLocation!);
    setState(() {});
  }

  void _addMarker(LatLng location) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: location,
        infoWindow: InfoWindow(
          title: 'My current location',
          snippet: '${location.latitude}, ${location.longitude}',
        ),
        draggable: true
      ),
    );
  }

  void _updatePolyline(LatLng newLocation) {
    _polylineCoordinates.add(newLocation);
    setState(() {
      _polyline = _polyline.copyWith(
        pointsParam: _polylineCoordinates,
      );
    });
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _updatePolyline(newLocation);
      _addMarker(newLocation);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps with Geolocator'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(0,0), // Placeholder: San Francisco
          zoom: 15,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: {_polyline},
        myLocationEnabled: true,
      ),
    );
  }
}
