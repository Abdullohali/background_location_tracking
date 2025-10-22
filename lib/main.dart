import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LocationTrackerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LocationTrackerScreen extends StatefulWidget {
  @override
  _LocationTrackerScreenState createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen>
    with WidgetsBindingObserver {
  GoogleMapController? mapController;
  Position? currentLocation;
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  StreamSubscription<Position>? locationSubscription;
  bool isTracking = false;
  bool isLoading = true;
  Timer? backgroundTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    locationSubscription?.cancel();
    backgroundTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (isTracking) {
        startLocationUpdates();
      }
    } else if (state == AppLifecycleState.paused) {
      // App backgroundga ketganda ham location tracking davom etsin
      if (isTracking) {
        startBackgroundTracking();
      }
    }
  }

  Future<void> initializeApp() async {
    await requestPermissions();
    // await signInAnonymously();
    await getCurrentLocation();
    // listenToOtherUsers();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> requestPermissions() async {
    // Location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Background location permission (Android)
    await Permission.locationAlways.request();
  }

  // Future<void> signInAnonymously() async {
  //   try {
  //     UserCredential userCredential =
  //         await FirebaseAuth.instance.signInAnonymously();
  //     currentUser = userCredential.user;
  //     print('Signed in with User ID: ${currentUser?.uid}');
  //   } catch (e) {
  //     print('Anonymous sign in failed: $e');
  //   }
  // }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = position;
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void startLocationUpdates() {
    locationSubscription?.cancel();

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        currentLocation = position;
      });

      // updateLocationInFirestore(position);

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    });
  }

  void startBackgroundTracking() {
    // Background'da har 15 sekundda location update
    backgroundTimer?.cancel();
    backgroundTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // await updateLocationInFirestore(position);
        print(
            'Background location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Background location error: $e');
      }
    });
  }

  void stopLocationUpdates() {
    locationSubscription?.cancel();
    backgroundTimer?.cancel();
  }

  // Future<void> updateLocationInFirestore(Position position) async {
  //   if (currentUser != null) {
  //     try {
  //       await FirebaseFirestore.instance
  //           .collection('locations')
  //           .doc(currentUser!.uid)
  //           .set({
  //         'latitude': position.latitude,
  //         'longitude': position.longitude,
  //         'timestamp': FieldValue.serverTimestamp(),
  //         'userId': currentUser!.uid,
  //         'accuracy': position.accuracy,
  //       });
  //     } catch (e) {
  //       print('Error updating location: $e');
  //     }
  //   }
  // }

  // void listenToOtherUsers() {
  //   firestoreSubscription = FirebaseFirestore.instance
  //       .collection('locations')
  //       .snapshots()
  //       .listen((QuerySnapshot snapshot) {
  //     Set<Marker> newMarkers = {};
  //     Set<Circle> newCircles = {};

  //     for (QueryDocumentSnapshot doc in snapshot.docs) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  //       if (doc.id != currentUser?.uid &&
  //           data['latitude'] != null &&
  //           data['longitude'] != null) {
  //         LatLng position = LatLng(data['latitude'], data['longitude']);

  //         newMarkers.add(
  //           Marker(
  //             markerId: MarkerId(doc.id),
  //             position: position,
  //             infoWindow: InfoWindow(
  //               title: 'User ${doc.id.substring(0, 8)}',
  //               snippet: 'Online user',
  //             ),
  //             icon: BitmapDescriptor.defaultMarkerWithHue(
  //                 BitmapDescriptor.hueRed),
  //           ),
  //         );

  //         newCircles.add(
  //           Circle(
  //             circleId: CircleId(doc.id),
  //             center: position,
  //             radius: 100,
  //             fillColor: Colors.red.withOpacity(0.1),
  //             strokeColor: Colors.red,
  //             strokeWidth: 1,
  //           ),
  //         );
  //       }
  //     }

  //     if (currentLocation != null) {
  //       newMarkers.add(
  //         Marker(
  //           markerId: MarkerId('current_user'),
  //           position:
  //               LatLng(currentLocation!.latitude, currentLocation!.longitude),
  //           infoWindow: InfoWindow(
  //             title: 'Siz',
  //             snippet: 'Sizning joylashuvingiz',
  //           ),
  //           icon: BitmapDescriptor.defaultMarkerWithHue(
  //               BitmapDescriptor.hueGreen),
  //         ),
  //       );

  //       newCircles.add(
  //         Circle(
  //           circleId: CircleId('current_user'),
  //           center:
  //               LatLng(currentLocation!.latitude, currentLocation!.longitude),
  //           radius: 100,
  //           fillColor: Colors.green.withOpacity(0.1),
  //           strokeColor: Colors.green,
  //           strokeWidth: 2,
  //         ),
  //       );
  //     }

  //     setState(() {
  //       markers = newMarkers;
  //       circles = newCircles;
  //     });
  //   });
  // }

  void toggleTracking() {
    setState(() {
      isTracking = !isTracking;
    });

    if (isTracking) {
      startLocationUpdates();
      startBackgroundTracking();
    } else {
      stopLocationUpdates();
      // if (currentUser != null) {
      //   FirebaseFirestore.instance
      //       .collection('locations')
      //       .doc(currentUser!.uid)
      //       .delete();
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Yuklanmoqda...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Location Tracker'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: getCurrentLocation,
            tooltip: 'Joylashuvni yangilash',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isTracking ? 'Aktiv' : 'Nofaol',
                          style: TextStyle(
                            color: isTracking ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isTracking,
                      onChanged: (value) => toggleTracking(),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                if (currentLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Lat: ${currentLocation!.latitude.toStringAsFixed(6)}, '
                      'Lon: ${currentLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: currentLocation == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Joylashuv aniqlanmoqda...'),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation!.latitude,
                        currentLocation!.longitude,
                      ),
                      zoom: 15.0,
                    ),
                    markers: markers,
                    circles: circles,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    compassEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Online: ${markers.length > 0 ? markers.length - 1 : 0}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTracking ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isTracking ? 'Aktiv' : 'Nofaol',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
