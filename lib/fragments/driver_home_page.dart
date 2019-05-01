import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:path_provider/path_provider.dart';

//import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vifaa_express_driver/Models/fares.dart';
import 'package:vifaa_express_driver/Models/favorite_places.dart';
import 'package:vifaa_express_driver/Models/general_promotion.dart';
import 'package:vifaa_express_driver/Models/payment_method.dart';
import 'package:vifaa_express_driver/Models/route.dart';
import 'package:vifaa_express_driver/Users/trip_ended_review.dart';
import 'package:vifaa_express_driver/Utility/MyColors.dart';
import 'package:vifaa_express_driver/Utility/Utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:map_view/map_view.dart';

class DriverPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DriverPage();
}

enum DialogType { request, driving }

const kGoogleApiKey = "AIzaSyCPSnicnVW3upwwp5Q_MgOkh7FhP3-ab1I";
const api_key = 'AIzaSyCPSnicnVW3upwwp5Q_MgOkh7FhP3-ab1I';
places.GoogleMapsPlaces _places =
    places.GoogleMapsPlaces(apiKey: kGoogleApiKey);

class _DriverPage extends State<DriverPage> {
  String _email = '', _number = '', _name = '', _msg = '', _vehicle_type = '';
  DatabaseReference locationRef;

  DialogType dialogType = DialogType.request;
  LatLng drivers_location;

  //loc.Location _location = new loc.Location();

  var _startLocation;
  loc.LocationData _currentLocation;

  StreamSubscription<loc.LocationData> _locationSubscription;

  var _location;
  var mLocation = new loc.Location();

  bool _permission = false;
  String error;
  final dateFormat = DateFormat("EEEE, MMMM d, yyyy 'at' h:mma");
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isGeneralTripsLoaded = false;

//  PaymentMethods _method = null;
//  GeneralPromotions _general_promotion = null;
//  Prediction getPrediction = null;
//
//  FavoritePlaces current_location = null;
//  FavoritePlaces destination_location = null;
//
  GoogleMapController mapController;
  int _polylineCount = 0;
  //Polyline _selectedPolyline;
  AudioPlayer audioPlugin = new AudioPlayer();

  //Completer<GoogleMapController> _controller = Completer();
  //var _mapView = new MapView();
  String current_trip_id;
  String _currency = '', _currencyCode = '', _country = '';
  Utils mUtils = new Utils();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;
  int _markerIdCounter = 1;

//  CurrentTrip currentTrip;
//  DriverDetails driverDetails;
//
//  bool isCarAvail = false;
//  bool isBikeAvail = false;
//  bool isCash = false,
//      isRefreshing = true,
//      isBottomSheet = false,
  bool _inAsyncCall = false, isDriverVerified = false;
  List<dynamic> _snapshots = new List();
  DataSnapshot currentTripSnapshot;
  bool driver_has_accepted = false,
      driver_going_to_pickup = false,
      driver_delivery_item = false;
  String button_title = 'Go to pickup';
  int button_index = 0;

//  String payment_type = '';
//  String promotion_type = '';
//  double request_progress = null;
  String trip_distance = '0 km', trip_duration = '0 min';
  String total_amount_earned = '0.00'; //₦
  bool getTripDetailsIsCalled = false;

  DataSnapshot requestSnapshot;
  bool hasRequest = false;

  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};
  int _polylineIdCounter = 1;
  PolylineId selectedPolyline;
  String phone_to_call = '';

//  int trip_calculation;
//  Fares car_fares = null;
//  Fares bike_fare = null;
//  bool isLoaded = false, isScheduled = false, isAlreadyBooked = false;
//  bool isButtonDisabled = false;
//  String errorLoaded = '';
//
//  String ride_option_type_id = '', _date_scheduled = '';
//  bool ride_option_selected_car = false;
//  bool ride_option_selected_bike = false;
//
//  String appBarTitle = 'Rider arrives in ';

  Future<void> _onMapCreated(GoogleMapController controller) async {
    setState(() {
      mapController = controller;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Screen.keepOn(true);
    //listenForDestinationEntered();
    initPlatformState();
    _locationSubscription =
        mLocation.onLocationChanged().listen((loc.LocationData result) {
      double lat = result.latitude;
      double lng = result.longitude;
      //print('lat = $lat\nlng = $lng');
      setState(() {
        if (mapController != null) {
          updateMapCamera(lat, lng);
        }
        _currentLocation = result;
      });
    });
  }

  void updateMapCamera(double lat, double lng) {
    //mapController.clearMarkers();
    markers.clear();
    if (dialogType == DialogType.request) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 20.0,
        ),
      ));
      final MarkerId markerId = MarkerId('request');
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: 'Your location', snippet: ''),
          icon: BitmapDescriptor.defaultMarker,
          alpha: 1.0,
          draggable: false);
      markers[markerId] = marker;
      //Timer timer = new Timer(Duration(seconds: 10), () {
      getMapLocation(lat, lng);
      //});
    }
    if (dialogType == DialogType.driving) {
      Map<dynamic, dynamic> cts = currentTripSnapshot.value['trip_details'];
      FavoritePlaces destination = FavoritePlaces.fromJson(cts['destination']);
      FavoritePlaces current_location =
          FavoritePlaces.fromJson(cts['current_location']);
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 13.0,
        ),
      ));
      final MarkerId markerId = MarkerId('driving');
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
              title: 'Your location',
              snippet: ''),
          icon: (cts['vehicle_type'].toString().toLowerCase() == 'car')
              ? BitmapDescriptor.fromAsset('assets/vecar.png')
              : BitmapDescriptor.fromAsset('assets/vebike.png'),
          alpha: 1.0,
          draggable: false);
      markers[markerId] = marker;
      if (button_index > 1) {
        final MarkerId markerId = MarkerId('driving1');
        final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(double.parse(destination.latitude),
                double.parse(destination.longitude)),
            infoWindow: InfoWindow(title: '${destination.loc_name}', snippet: ''),
            icon: BitmapDescriptor.defaultMarker,
            alpha: 1.0,
            draggable: false);
        markers[markerId] = marker;
      }
      if (button_index == 1) {
        final MarkerId markerId = MarkerId('driving2');
        final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(double.parse(current_location.latitude),
                double.parse(current_location.longitude)),
            infoWindow: InfoWindow(title: '${current_location.loc_name}', snippet: ''),
            icon: BitmapDescriptor.defaultMarker,
            alpha: 1.0,
            draggable: false);
        markers[markerId] = marker;
      }
      locationRef = FirebaseDatabase.instance
          .reference()
          .child('drivers/${_email.replaceAll('.', ',')}/location');
      locationRef.set({
        'location_name': 'not set',
        'location_address': 'not set',
        'latitude': '$lat',
        'longitude': '$lng'
      });
      if (button_index > 1) {
        Timer timer = new Timer(Duration(seconds: 5), () {
          getDistanceDirection(
              lat, lng, destination.latitude, destination.longitude);
        });
      }
      if (button_index == 1) {
        new Timer(Duration(seconds: 5), () {
          getDistanceDirection(
              lat, lng, current_location.latitude, current_location.longitude);
        });
      }
    }
  }

  Future<void> getDistanceDirection(
      double lat, double lng, String dest_lat, String dest_lng) async {
    try {
      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$lat,$lng&destinations=$dest_lat,$dest_lng&key=$api_key';
      http.get(url).then((res) {
        Map<String, dynamic> resp = json.decode(res.body);
        String status = resp['status'];
        if (status != null && status == 'OK') {
          Map<String, dynamic> result = resp['rows'][0];
          Map<String, dynamic> element = result['elements'][0];
          Map<String, dynamic> distance = element['distance'];
          Map<String, dynamic> duration = element['duration'];
          setState(() {
            trip_distance = distance['text'];
            trip_duration = duration['text'];
          });
        }
      });
    } catch (e) {
      print('${e.toString()}');
    }
  }

  void getMapLocation(double lat, double lng) {
    locationRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/location');
    locationRef.set({
      'location_name': 'not set',
      'location_address': 'not set',
      'latitude': '$lat',
      'longitude': '$lng'
    });
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$api_key';
    http.get(url).then((res) async {
      //new Utils().neverSatisfied(context, 'msg', res.body);
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['results'][0];
        String place_id = result['place_id'];
        places.PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(place_id);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String _lat = detail.result.geometry.location.lat.toString();
        String _lng = detail.result.geometry.location.lng.toString();

        locationRef.update({
          'location_name': loc_name,
          'location_address': loc_address,
          'latitude': _lat,
          'longitude': _lng
        });
      }
    });
  }

  initPlatformState() async {
    Map<String, double> location;
    try {
      _permission = await _location.hasPermission();
      location = await _location.getLocation();
      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }
      location = null;
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //if (!mounted) return;
    setState(() {
      _startLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _msg = pref.getString('msgId');
        _country = pref.getString('country');
        _vehicle_type = pref.getString('vehicle_type');
        isDriverVerified = pref.getBool('userVerified');
      });
    });
    mUtils.initializeRemoteConfig(_country).whenComplete(() {
      setState(() {
        _currency = mUtils.fetchCurrency();
        _currencyCode = mUtils.fetchCurrencyCode();
      });
    });
    _checkIncomingRequest(false);
    getGeneralTrips();
    getDriverTotalEarned();
    if (!getTripDetailsIsCalled) {
      getCurrentTripDetails();
    }
    // TODO: implement build
    return Scaffold(
        body: ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            color: Color(MyColors().button_text_color),
            child: new Container(
                child: new Stack(
                    overflow: Overflow.clip,
                    fit: StackFit.passthrough,
                    children: <Widget>[
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: LatLng(0.0, 0.0)),
                    onMapCreated: _onMapCreated,
                    compassEnabled: false,
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: Set<Marker>.of(markers.values),
                    polylines: Set<Polyline>.of(polylines.values),
                  ),
                  new Container(
                      margin:
                          EdgeInsets.only(top: 20.0, left: 13.0, right: 13.0),
                      child: new Column(
                        children: <Widget>[
                          (!driver_has_accepted) ? buildEarned() : Text(''),
                          (!driver_has_accepted)
                              ? (_snapshots.length > 0)
                                  ? buildSliderForTrips()
                                  : new Text('')
                              : new Text(''),
                        ],
                      )),
                  _incomingRequestBody(),
                  (currentTripSnapshot != null)
                      ? driverHasAcceptedATrip()
                      : new Text(''),
                ]))));
  }

  Widget _incomingRequestBody(){
    if(hasRequest && requestSnapshot.value != null) {
      return Opacity(opacity: 0.7, child: Container(
        child:  Stack(
      children: <Widget>[
        Positioned.fill(
            child: new Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[

                ],
              ),
              alignment: Alignment.topCenter,
            )
        ),
        new Center(
            child: new Container(
          child: Column(
            children: <Widget>[
              new Container(
                height: 100.0,
                width: 100.0,
                child: CircularProgressIndicator(
                  value: null,

                ),
              ),
              Text('You have 10seconds to accept this request.')
            ],
          ),
          alignment: Alignment.center,
        )),
        new Container(
          child: new Container(
            margin: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Padding(
              padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
              child: new RaisedButton(
                child: new Text('ACCEPT TRIP',
                    style: new TextStyle(
                        fontSize: 18.0,
                        color: Color(MyColors().button_text_color))),
                color: Color(MyColors().secondary_color),
                disabledColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                ),
                onPressed: (){
                  setState(() {
                    _inAsyncCall = true;
                    hasRequest = false;
                  });
                  _tripAcceptedByDriver(requestSnapshot.value);
                  _checkIncomingRequest(true);
                },
                //buttonDisabled
                padding: EdgeInsets.all(15.0),
              ),
            ),
          ),
          alignment: Alignment.bottomCenter,
        ),
      ],
    ),
      ),);
    }else{
      return Text('');
    }
  }

  void _checkIncomingRequest(bool removeRequest) {
    DatabaseReference reqRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/request');
    if(removeRequest){
      reqRef.remove();
      return;
    }
    reqRef.onValue.listen((req){
      if(req.snapshot.value != null){
        setState(() {
          hasRequest = true;
          requestSnapshot = req.snapshot;
        });
        playNotification();
      }else{
        setState(() {
          hasRequest = false;
          requestSnapshot = null;
        });
      }
    });

  }

  Widget buildEarned() {
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(bottom: 10.0),
        child: Center(
            child: Container(
          height: 50.0,
          width: 200.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Color(MyColors().primary_color),
              border: Border(
                  top: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  left: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  right: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  bottom: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0)),
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          child: Center(
            child: Text(
              total_amount_earned,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )));
  }

  Widget buildSliderForTrips() {
    return new Container(
        height: 220.0,
        child: new Swiper(
          itemCount: _snapshots.length,
          autoplay: false,
          loop: false,
          itemBuilder: (BuildContext context, int index) {
            //return new Column(children: carouselChildren());
            return new Wrap(
              runSpacing: 6.0,
              children: _snapshots.map((snap) {
                return _carouselChildren1(snap);
              }).toList(),
            );
          },
          scrollDirection: Axis.horizontal,
          viewportFraction: 0.8,
          scale: 0.9,
          pagination: new SwiperPagination(),
          control: new SwiperControl(),
        )

//        CarouselSlider(
//          height: 220.0,
//          autoPlay: false,
//          enlargeCenterPage: true,
//          items: carouselChildren(),
//        )
        );
  }

  Widget driverHasAcceptedATrip() {
    Map<dynamic, dynamic> cts = currentTripSnapshot.value['trip_details'];
    FavoritePlaces fp = FavoritePlaces.fromJson(cts['current_location']);
    FavoritePlaces fp2 = FavoritePlaces.fromJson(cts['destination']);
    return Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.bottomCenter,
        height: 370.0,
        margin:
            EdgeInsets.only(top: (MediaQuery.of(context).size.height - 370.0)),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new ListTile(
                leading: CircleAvatar(
                  radius: 30.0,
                  child: Image.asset(
                    'user_dp.png',
                    height: 60.0,
                    width: 60.0,
                  ),
                ),
                title: Row(
                  children: <Widget>[
                    Flexible(
                        child: Text(
                      (button_index == 0 || button_index == 1)
                          ? fp.loc_name
                          : fp2.loc_name,
                      style: TextStyle(
                        color: Color(MyColors().primary_color),
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    )),
                    IconButton(
                      icon: Icon(Icons.navigation),
                      onPressed: () {
                        if (button_index == 1) {
                          String nav_url =
                              "https://www.google.com/maps/dir/?api=1&origin=${drivers_location.latitude},${drivers_location.longitude}&destination=${fp.latitude},${fp.longitude}&travelmode=driving&dir_action=navigate";
                          _launchURL(nav_url);
                        } else {
                          String nav_url =
                              "https://www.google.com/maps/dir/?api=1&origin=${drivers_location.latitude},${drivers_location.longitude}&destination=${fp2.latitude},${fp2.longitude}&travelmode=driving&dir_action=navigate";
                          _launchURL(nav_url);
                        }
                      },
                      color: Color(MyColors().secondary_color),
                      tooltip: 'Navigate using google map',
                      iconSize: 24.0,
                    )
                  ],
                ),
                subtitle: Text(
                  cts['rider_name'].toString(),
                  style: TextStyle(
                      color: Color(MyColors().primary_color),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400),
                ),
                trailing: (cts['card_trip']
                    ? Icon(
                        Icons.credit_card,
                        color: Color(MyColors().secondary_color),
                      )
                    : Icon(
                        Icons.monetization_on,
                        color: Color(MyColors().secondary_color),
                      )),
              ),
              Container(
                height: 10.0,
              ),
              Divider(
                color: Color(MyColors().primary_color),
                height: 1.0,
              ),
              ListTile(
                leading: Icon(
                  Icons.call,
                  color: Color(MyColors().primary_color),
                ),
                title: Text(
                  'Call ${cts['rider_name'].toString()}',
                  style: TextStyle(
                      color: Color(MyColors().primary_color),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(MyColors().primary_color),
                ),
                onTap: (){
                  Map<dynamic, dynamic> cts = currentTripSnapshot.value['trip_details'];
                  setState(() {
                    phone_to_call = (button_index > 1) ? '${cts['receiver_number'].toString()}' : '${cts['rider_number'].toString()}';
                  });
                  _callUser();
                },
              ),
              (dialogType == DialogType.driving)
                  ? Divider(
                      color: Color(MyColors().primary_color),
                      height: 1.0,
                    )
                  : new Text(''),
              Container(
                margin: EdgeInsets.only(left: 13.0, right: 13.0, top: 5.0),
                child: (dialogType == DialogType.driving)
                    ? Text(
                        '$trip_duration',
                        style: TextStyle(
                            color: Color(MyColors().primary_color),
                            fontSize: 30.0,
                            fontWeight: FontWeight.w500),
                      )
                    : new Text(''),
              ),
              Divider(
                color: Color(MyColors().primary_color),
                height: 1.0,
              ),
              new Container(
                margin: EdgeInsets.only(
                    left: 13.0, right: 13.0, top: 10.0, bottom: 10.0),
                child: Padding(
                  padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
                  child: new RaisedButton(
                    child: new Text(button_title.toUpperCase(),
                        style: new TextStyle(
                            fontSize: 15.0,
                            color: (button_index == 3)
                                ? Colors.white
                                : Color(MyColors().button_text_color),
                            fontWeight: FontWeight.w500)),
                    color: (button_index == 3)
                        ? Colors.red
                        : Color(MyColors().secondary_color),
                    disabledColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    ),
                    onPressed: () {
                      _performButtonOperation(button_index);
                    },
                    //buttonDisabled
                    padding: EdgeInsets.all(15.0),
                  ),
                ),
              ),
              Container(
                child: Center(
                  child: new FlatButton(
                    onPressed: () {
                      _confirmCancelTrip();
                    },
                    child: new Text('Cancel Trip',
                        style: new TextStyle(
                            fontSize: 14.0,
                            color: Color(MyColors().button_text_color))),
                  ),
                ),
              ),
            ]));
  }

  void _confirmCancelTrip() {
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to cancel this trip'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                'Continue',
                style: TextStyle(color: Color(MyColors().primary_color)),
              ),
              onPressed: () {
                setState(() {
                  dialogType = DialogType.request;
                  driver_has_accepted = false;
                  driver_delivery_item = false;
                  driver_going_to_pickup = false;
                  _inAsyncCall = true;
                });
                cancelTripForDriver();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void cancelTripForDriver() {
    Map<dynamic, dynamic> ride_details =
        currentTripSnapshot.value['trip_details'];
    FavoritePlaces fp =
        FavoritePlaces.fromJson(ride_details['current_location']);
    FavoritePlaces fp2 = FavoritePlaces.fromJson(ride_details['destination']);
    PaymentMethods pm = (ride_details['card_trip'])
        ? PaymentMethods.fromJson(ride_details['payment_method'])
        : null;
    GeneralPromotions gp = (ride_details['promo_used'])
        ? GeneralPromotions.fromJson(ride_details['promotions'])
        : null;
    Fares fares = Fares.fromJson(ride_details['fare']);
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}');
    driverRef.child('accepted_trip').remove().then((comp) {
      DateTime dt = DateTime.now();
      String key = '${dt.day},${(dt.month)},${dt.year}';
      driverRef.child('trips/$key').push().set({
        'id': '${ride_details['id'].toString()}',
        'status': '${currentTripSnapshot.value['status'].toString()}',
        'current_index':
            '${currentTripSnapshot.value['current_index'].toString()}',
        'current_location_reached':
            '${currentTripSnapshot.value['current_location_reached'].toString()}',
        'ride_started':
            '${currentTripSnapshot.value['ride_started'].toString()}',
        'ride_ended': '${currentTripSnapshot.value['ride_ended'].toString()}',
        'scheduled_reached':
            '${currentTripSnapshot.value['scheduled_reached']}',
        'trip_details': {
          'id': ride_details['id'].toString(),
          'currency': ride_details['currency'].toString(),
          'country': ride_details['country'].toString(),
          'dimensions': ride_details['dimensions'].toString(),
          'item_type': ride_details['item_type'].toString(),
          'receiver_number': ride_details['receiver_number'].toString(),
          'payment_by': ride_details['payment_by'].toString(),
          'current_location': fp.toJSON(),
          'destination': fp2.toJSON(),
          'trip_distance': ride_details['trip_distance'],
          'trip_duration': ride_details['trip_duration'],
          'payment_method': (ride_details['card_trip']) ? pm.toJSON() : 'cash',
          'vehicle_type': ride_details['vehicle_type'],
          'promotion': (gp != null) ? gp.toJSON() : 'no_promo',
          'card_trip': (ride_details['card_trip']) ? true : false,
          'promo_used': (gp != null) ? true : false,
          'scheduled_date': ride_details['scheduled_date'].toString(),
          'status': '0',
          'created_date': ride_details['created_date'].toString(),
          'price_range': ride_details['price_range'].toString(),
          'trip_total_price': '$_currency 0.00',
          'fare': fares.toJSON(),
          'assigned_driver': _email,
          'rider_email': ride_details['rider_email'].toString(),
          'rider_name': ride_details['rider_name'].toString(),
          'rider_number': ride_details['rider_number'].toString(),
          'rider_msgId': ride_details['rider_msgId'].toString()
        }
      }).then((comp) {}); //debit and if promo and total earn
    });
  }

  void _callUser() {
    String url = 'tel:$phone_to_call';
    _launchURL(url);
  }

  Future<Null> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _performButtonOperation(int index) {
    Map<dynamic, dynamic> cts = currentTripSnapshot.value['trip_details'];
    FavoritePlaces currentLoc =
        FavoritePlaces.fromJson(cts['current_location']);
    FavoritePlaces destinationLoc = FavoritePlaces.fromJson(cts['destination']);
    DatabaseReference ctRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/accepted_trip');
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
        'users/${cts['rider_email'].toString().replaceAll('.', ',')}/trips');
    if (index == 0) {
      userRef.child('status') //${cts['id'].toString()}
          .update({'current_ride_status': 'driver assigned'}).then((comp) {
        new Utils().sendNotification(
            'VifaaExpress Driver',
            'Your driver is coming to your pickup location.\nOpen the app for more details.\n\nYour track id is ${cts['id'].toString()}',
            cts['rider_msgId'].toString(),
            cts['rider_number'].toString(),'');
        setState(() {
          dialogType = DialogType.driving;
          button_title = 'I have arrived pickup location';
          button_index = 1;
        });
        ctRef.update({'status': 'pickup driving', 'current_index': '1'});
        addPolyLineToMap(
            drivers_location,
            LatLng(double.parse(currentLoc.latitude),
                double.parse(currentLoc.longitude)));
      });
    }
    if (index == 1) {
      setState(() {
        dialogType = DialogType.driving;
        button_title = 'Start driving to drop-off';
        button_index = 2;
      });
      ctRef.update({
        'current_location_reached': DateTime.now().toString(),
        'status': 'pickup arrived',
        'current_index': '2'
      }).then((comp) {
        userRef.child('status').update({'current_ride_status': 'en-route'});
      });
      addPolyLineToMap(
          drivers_location,
          LatLng(double.parse(destinationLoc.latitude),
              double.parse(destinationLoc.longitude)));
      String price_range = cts['price_range'].toString();
      String item_type = cts['item_type'].toString();
      String payment_by = cts['payment_by'].toString();
      bool isCard = cts['card_trip'];
      String pbm = (payment_by == 'merchant')
          ? (isCard)
              ? ''
              : 'Collect cash payment of $price_range from merchant upon item collection.'
          : 'Collect payment from receiver upon delivery.';
      mUtils.neverSatisfied(context, 'VifaaExpress Message',
          'Type of item to be picked: $item_type.\n$pbm');
    }
    if (index == 2) {
      setState(() {
        dialogType = DialogType.driving;
        button_title = 'End Trip';
        button_index = 3;
      });
      ctRef.update({
        'ride_started': DateTime.now().toString(),
        'status': 'pickup arrived',
        'current_index': '3'
      });
    }
    if (index == 3) {
      setState(() {
        dialogType = DialogType.driving;
        //button_title = 'End Trip';
        //button_index = 4;
      });
      ctRef.update({
        'ride_ended': DateTime.now().toString(),
        'status': 'ride ended',
        'current_index': '4'
      });
      new Utils().sendNotification(
          'VifaaExpress Driver',
          'You item has been delivered successfully. Thank you for choosing VifaaExpress.',
          cts['rider_msgId'].toString(),
          cts['rider_number'].toString(), cts['receiver_number'].toString());
    }
    if (index == 4) {
      //open a new activity
      Route route = MaterialPageRoute(
          builder: (context) => TripEndedReview(currentTripSnapshot));
      Navigator.pushReplacement(context, route);
    }
  }

  Future<void> getCurrentTripDetails() async {
    DatabaseReference ctRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/accepted_trip');
    ctRef.onValue.listen((data) {
      if (data.snapshot.value != null) {
        setState(() {
          currentTripSnapshot = data.snapshot;
          Map<dynamic, dynamic> cts = currentTripSnapshot.value['trip_details'];
          FavoritePlaces currentLoc =
              FavoritePlaces.fromJson(cts['current_location']);
          FavoritePlaces destinationLoc =
              FavoritePlaces.fromJson(cts['destination']);
          button_index =
              int.parse(data.snapshot.value['current_index'].toString());
          if (button_index == 0) {
            driver_has_accepted = true;
            button_title = 'Go to pickup';
          }
          if (button_index == 1) {
            driver_has_accepted = true;
            dialogType = DialogType.driving;
            button_title = 'I have arrived pickup location';
            addPolyLineToMap(
                drivers_location,
                LatLng(double.parse(currentLoc.latitude),
                    double.parse(currentLoc.longitude)));
            String price_range = cts['price_range'].toString();
            String item_type = cts['item_type'].toString();
            String payment_by = cts['payment_by'].toString();
            bool isCard = cts['card_trip'];
            String pbm = (payment_by == 'merchant')
                ? (isCard)
                    ? ''
                    : 'Collect cash payment of $price_range from merchant upon item collection.'
                : 'Collect payment from receiver upon delivery.';
            mUtils.neverSatisfied(context, 'VifaaExpress Message',
                'Type of item to be picked: $item_type.\n$pbm');
          }
          if (button_index == 2) {
            driver_has_accepted = true;
            dialogType = DialogType.driving;
            driver_going_to_pickup = true;
            button_title = 'Start driving to drop-off';
            addPolyLineToMap(
                drivers_location,
                LatLng(double.parse(destinationLoc.latitude),
                    double.parse(destinationLoc.longitude)));
          }
          if (button_index == 3) {
            driver_has_accepted = true;
            dialogType = DialogType.driving;
            driver_delivery_item = true;
            button_title = 'End Trip';
          }
          if (button_index == 4) {
            dialogType = DialogType.request;
            //open activity to charge user
            Route route = MaterialPageRoute(
                builder: (context) => TripEndedReview(currentTripSnapshot));
            Navigator.pushReplacement(context, route);
          }
          getTripDetailsIsCalled = true;
        });
      }
    });
  }

  void addPolyLineToMap(LatLng start, LatLng end) {
    try {
      List<MyRoute> mRoutes = new List();
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$api_key';
      //print('addPolyLineToMap url = $url');
      http.get(url).then((res) {
        Map<String, dynamic> resp = json.decode(res.body);
        //Map<dynamic, dynamic> routes = resp['routes'];
        MyRoute route = new MyRoute();
        Map<dynamic, dynamic> jsonRoute = resp['routes'][0];
        Map<dynamic, dynamic> overview_polylineJson =
            jsonRoute['overview_polyline'];
        route.points =
            decodePolyLine(overview_polylineJson['points'].toString());
        mRoutes.add(route);
        for (MyRoute myR in mRoutes) {
          final PolylineId polylineId = PolylineId('routes');
          final Polyline polyline = Polyline(
            polylineId: polylineId,
            color: 0xFF12161E,
            width: 20,
            points: myR.points, visible: true
          );
          setState(() {
            polylines[polylineId] = polyline;
          });
//          PolylineOptions polylineOptions = new PolylineOptions(
//              geodesic: true,
//              color: 0xFF12161E,
//              width: 20.0,
//              visible: true,
//              points: myR.points);
//          mapController.addPolyline(polylineOptions);
        }
      });
    } catch (e) {
      //print('addPolyLineToMap exception = ${e.toString()}');
    }
  }

  List<LatLng> decodePolyLine(final String poly) {
    int len = poly.length;
    int index = 0;
    List<LatLng> decoded = new List<LatLng>();
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      decoded.add(new LatLng(
          (lat / double.parse('100000')), (lng / double.parse('100000'))));
    }
    //print('decodePolyLine: length = ${decoded.length} and LatLng = ${decoded[0].latitude},${decoded[0].longitude}');

    return decoded;
  }

  Widget _carouselChildren1(dynamic snap) {
    FavoritePlaces fp = FavoritePlaces.fromJson(snap['current_location']);
    DateTime scheduled_date =
        DateTime.parse(snap['scheduled_date'].toString()); //
    var months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sept",
      "Oct",
      "Nov",
      "Dec"
    ];
    return Container(
      color: Color(MyColors().primary_color),
      height: 220.0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new ListTile(
            title: new Text(
              'Pickup location',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
            subtitle: new Text(
              fp.loc_name,
              style: TextStyle(color: Colors.white, fontSize: 14.0),
            ),
            leading: Icon(
              Icons.my_location,
              color: Colors.green,
            ),
          ),
          new ListTile(
            title: new Text(
              'Scheduled for',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
            subtitle: new Text(
              '${months[(scheduled_date.month - 1)]}.${scheduled_date.day}.${scheduled_date.year} ${scheduled_date.hour}:${scheduled_date.minute}',
              style: TextStyle(color: Colors.white, fontSize: 14.0),
            ),
            leading: Icon(
              Icons.date_range,
              color: Colors.white,
            ),
          ),
          new Container(
            margin: EdgeInsets.only(left: 13.0, right: 13.0, bottom: 10.0),
            child: Padding(
              padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
              child: new RaisedButton(
                child: new Text('Accept Trip',
                    style: new TextStyle(
                        fontSize: 18.0,
                        color: Color(MyColors().button_text_color))),
                color: Color(MyColors().secondary_color),
                disabledColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                ),
                onPressed: () {
                  _acceptTrip(snap);
                },
                //buttonDisabled
                padding: EdgeInsets.all(15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> carouselChildren() {
    List<Widget> mWidgets = new List();
    _snapshots.forEach((snap) {
      FavoritePlaces fp = FavoritePlaces.fromJson(snap['current_location']);
      DateTime scheduled_date =
          DateTime.parse(snap['scheduled_date'].toString());
      var months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sept",
        "Oct",
        "Nov",
        "Dec"
      ];
      mWidgets.add(Container(
        color: Color(MyColors().primary_color),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new ListTile(
              title: new Text(
                'Pickup location',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              subtitle: new Text(
                fp.loc_name,
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              leading: Icon(
                Icons.my_location,
                color: Colors.green,
              ),
            ),
            new ListTile(
              title: new Text(
                'Scheduled for',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              subtitle: new Text(
                '${months[(scheduled_date.month - 1)]}.${scheduled_date.day}.${scheduled_date.year}',
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              leading: Icon(
                Icons.date_range,
                color: Colors.white,
              ),
            ),
            new Container(
              margin: EdgeInsets.only(left: 13.0, right: 13.0, bottom: 10.0),
              child: Padding(
                padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
                child: new RaisedButton(
                  child: new Text('Accept Trip',
                      style: new TextStyle(
                          fontSize: 18.0,
                          color: Color(MyColors().button_text_color))),
                  color: Color(MyColors().secondary_color),
                  disabledColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  ),
                  onPressed: () {
                    _acceptTrip(snap);
                  },
                  //buttonDisabled
                  padding: EdgeInsets.all(15.0),
                ),
              ),
            ),
          ],
        ),
      ));
    });
    return mWidgets;
  }

  void _acceptTrip(dynamic values) {
    if (!isDriverVerified) {
      new Utils().neverSatisfied(context, 'Error',
          'Sorry your account has not yet been verified. Contact support for more details.');
      return;
    }
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to accept this trip'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                'Continue',
                style: TextStyle(color: Color(MyColors().primary_color)),
              ),
              onPressed: () {
                setState(() {
                  _inAsyncCall = true;
                });
                _tripAcceptedByDriver(values);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _tripAcceptedByDriver(dynamic values) {
    FavoritePlaces fp = FavoritePlaces.fromJson(values['current_location']);
    FavoritePlaces fp2 = FavoritePlaces.fromJson(values['destination']);
    PaymentMethods pm = (values['card_trip'])
        ? PaymentMethods.fromJson(values['payment_method'])
        : null;
    GeneralPromotions gp = (values['promo_used'])
        ? GeneralPromotions.fromJson(values['promotions'])
        : null;
    Fares fares = Fares.fromJson(values['fare']);

    DatabaseReference genRef = FirebaseDatabase.instance
        .reference()
        .child('general_trips/${values['id'].toString()}');
    genRef.update({'assigned_driver': _email}).then((comp) {
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
          'users/${values['rider_email'].toString().replaceAll('.', ',')}/trips');
      userRef
          .child('incoming/${values['id'].toString()}')
          .update({'assigned_driver': _email}).then((comp) {
        userRef
            .child('status')
            .update({'current_ride_status': 'driver accepted'}).then((comp) {
          DatabaseReference driverRef = FirebaseDatabase.instance
              .reference()
              .child('drivers/${_email.replaceAll('.', ',')}/accepted_trip');
          driverRef.set({
            'id': '${values['id'].toString()}',
            'status': 'awaiting pickup',
            'current_index': '0',
            'current_location_reached': '',
            'ride_started': '',
            'ride_ended': '',
            'scheduled_reached': false,
            'trip_details': {
              'id': values['id'].toString(),
              'currency': values['currency'].toString(),
              'country': values['country'].toString(),
              'dimensions': values['dimensions'].toString(),
              'item_type': values['item_type'].toString(),
              'payment_by': values['payment_by'].toString(),
              'receiver_number': values['receiver_number'].toString(),
              'current_location': fp.toJSON(),
              'destination': fp2.toJSON(),
              'trip_distance': values['trip_distance'],
              'trip_duration': values['trip_duration'],
              'payment_method': (values['card_trip']) ? pm.toJSON() : 'cash',
              'vehicle_type': values['vehicle_type'],
              'promotion': (gp != null) ? gp.toJSON() : 'no_promo',
              'card_trip': (values['card_trip']) ? true : false,
              'promo_used': (gp != null) ? true : false,
              'scheduled_date': values['scheduled_date'].toString(),
              'status': 'incoming',
              'created_date': values['created_date'].toString(),
              'price_range': values['price_range'].toString(),
              'trip_total_price': values['trip_total_price'].toString(),
              'fare': fares.toJSON(),
              'assigned_driver': _email,
              'rider_email': values['rider_email'].toString(),
              'rider_name': values['rider_name'].toString(),
              'rider_number': values['rider_number'].toString(),
              'rider_msgId': values['rider_msgId'].toString()
            }
          }).then((comp) async {
            //send notification to user saying a driver has accepted your trip
            //also schedule the time
            new Utils().sendNotification(
                'VifaaExpress Booking Status',
                'Your trip has been accepted by one of our driver. Your ride will be attended to in due time.',
                values['rider_msgId'].toString(),
                values['rider_number'].toString(),'');
            DateTime future_date =
                DateTime.parse(values['scheduled_date'].toString());
            DateTime now_date = DateTime.now();
            int diff = future_date.difference(now_date).inSeconds;
            int helloAlarmID = 0;
            await AndroidAlarmManager.oneShot(
                Duration(seconds: diff), helloAlarmID, alertDriver);
            setState(() {
              driver_has_accepted = true;
              _inAsyncCall = false;
            });
            _prefs.then((pref) {
              pref.setString('accepted_trip_id', values['id'].toString());
            });
          });
        });
      });
    });
  }

  Future<void> alertDriver() async {
    String dEmail, id;
    Future<SharedPreferences> _bgPrefs = SharedPreferences.getInstance();
    _bgPrefs.then((pref) {
      dEmail = pref.getString('email');
      id = pref.getString('accepted_trip_id');
    });
    DatabaseReference updateDriverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${dEmail.replaceAll('.', ',')}/accepted_trip');
    await updateDriverRef.update({'scheduled_reached': true});
  }

  Future<void> getGeneralTrips() async {
    DatabaseReference genRef =
        FirebaseDatabase.instance.reference().child('general_trips');
    genRef.onValue.listen((ls) {
      _snapshots.clear();
      //new Utils().neverSatisfied(context, 'msg', 'snapshot length = ${ls.asMap()[0].value['id'].toString()}');
      if (ls.snapshot.value != null) {
        Map<dynamic, dynamic> values = ls.snapshot.value;
        values.forEach((key, vals) {
          if (vals['vehicle_type'].toString().toLowerCase() ==
                  _vehicle_type.toLowerCase() &&
              vals['assigned_driver'].toString() == 'none') {
            setState(() {
              _snapshots.add(vals);
            });
          }
        });
        //playNotification();
      }
//      setState(() {
//        //isGeneralTripsLoaded = true;
//      });
    });
  }

  void getDriverTotalEarned() {
    DatabaseReference driverEarnRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/total_earned');
    driverEarnRef.onValue.listen((ev) {
      if (ev.snapshot.value != null) {
        setState(() {
          total_amount_earned = '$_currency${ev.snapshot.value.toString()}.00';
        });
      }
    });
  }

  Future<ByteData> loadAsset() async {
    return await rootBundle.load('assets/audio/rush.mp3');
  }

  Future<void> playNotification() async {
    final file = new File('${(await getTemporaryDirectory()).path}/rush.mp3');
    await file.writeAsBytes((await loadAsset()).buffer.asUint8List());
    await audioPlugin.play(file.path, isLocal: true).catchError((error) {
      print('Audio error: ${error.toString()}');
    });
  }
}
