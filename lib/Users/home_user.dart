import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vifaa_express_driver/Models/reviews.dart';
import 'package:vifaa_express_driver/Models/user.dart';
import 'package:vifaa_express_driver/Users/user_login.dart';
import 'package:vifaa_express_driver/Utility/MyColors.dart';
import 'package:vifaa_express_driver/Utility/Utils.dart';
import 'package:vifaa_express_driver/fragments/driver_home_page.dart';
import 'package:vifaa_express_driver/fragments/help.dart';
import 'package:vifaa_express_driver/fragments/legal.dart';
import 'package:vifaa_express_driver/fragments/payment.dart';
import 'package:vifaa_express_driver/fragments/payment_chart.dart';
import 'package:vifaa_express_driver/fragments/settings.dart';
import 'package:vifaa_express_driver/fragments/trips.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  final drawerItems = [
    new DrawerItem("Home", sidebarIcons(innerIcon: Icons.home), new Text('')),
    new DrawerItem("Your Trips", sidebarIcons(innerIcon: Icons.directions), new Text('')),
    new DrawerItem("Payment", sidebarIcons(innerIcon: Icons.payment), new Text('')),
    new DrawerItem("Help", sidebarIcons(innerIcon: Icons.help), new Text('')),
    //new DrawerItem("Free Rides", Image.asset('free_rides.png'), new Text('')),
    new DrawerItem("Settings", sidebarIcons(innerIcon: Icons.settings), new Text('')),
    new DrawerItem(
        "Legal",
        sidebarIcons(innerIcon: Icons.pages),
        new Text(
          'v1.0',
          style: TextStyle(color: Colors.white),
        ))
  ];

  @override
  State<StatefulWidget> createState() => _UserHomePage();
}

Widget sidebarIcons({IconData innerIcon}) {
  return Container(
    width: 39.0,
    height: 39.0,
    decoration: new BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Color(MyColors().secondary_color), width: 1.0),
    ),
    child: Icon(
      innerIcon,
      color: Colors.white,
      size: 18.0,
    ),
  );
}

class DrawerItem {
  String title;

  //IconData icon;
  Widget icon;
  Widget trailing;

  DrawerItem(this.title, this.icon, this.trailing);
}

class _UserHomePage extends State<UserHomePage> {
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int _selectedDrawerIndex = 0;
  Utils utils = new Utils();
  User user;
  bool isAppBar = false;
  bool isStack = true;
  String _name = '', _email = '', _image = '';
  bool destination_entered = false;
  double total_rating = 0.0;

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new DriverPage();
      case 1:
        //_closeAppBar();
        return new MyTrips();
      case 2:
        //_closeAppBar();
        return new PaymentDetails();
      case 3:
        //_closeAppBar();
        return new HelpPage();
      case 4:
        //_closeAppBar();
        return new Settings();
      case 5:
        //_closeAppBar();
        return new LegalPage();
      default:
        return new DriverPage();
    }
  }

  _closeAppBar() {
    setState(() {
      isStack = false;
      isAppBar = false;
    });
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _checkBlockStatus() async {
    DatabaseReference checkBlock = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/signup');
    checkBlock.onValue.listen((data) {
      bool userBlocked = data.snapshot.value['userBlocked'];
      bool userVerified = data.snapshot.value['userVerified'];
      _prefs.then((p) {
        p.setBool('userVerified', userVerified);
      });
      if (userBlocked) {
        new Utils().neverSatisfied(context, 'User Blocked',
            'Sorry you have been blocked from this account. Please contact support for futher assistance.');
        _prefs.then((pref) {
          pref.clear();
        });
        FirebaseAuth.instance.signOut();
        Route route = MaterialPageRoute(builder: (context) => UserLogin());
        Navigator.pushReplacement(context, route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _name = pref.getString('fullname');
        _email = pref.getString('email');
        _image = pref.getString('image');
      });
    });
    var drawerOptions = <Widget>[];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: d.icon,
        title: new Text(
          d.title,
          style: TextStyle(color: Colors.white, fontSize: 19.0),
        ),
        trailing: d.trailing,
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }
    _checkBlockStatus();
    // TODO: implement build
    return new Scaffold(
      key: _key,
      appBar: new AppBar(
          title: new Text(widget.drawerItems[_selectedDrawerIndex].title)),
      drawer: new Drawer(
          child: new Container(
              color: Color(MyColors().button_text_color),
              child: new ListView(children: <Widget>[
                new Column(
                  children: <Widget>[
                    new UserAccountsDrawerHeader(
                      accountName: new Text((_name == null) ? '' : _name),
                      accountEmail: new Text((_email == null) ? '' : _email),
                      currentAccountPicture: Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              image: new DecorationImage(
                                fit: BoxFit.cover,
                                image: (_image == null)
                                    ? AssetImage('user_dp.png')
                                    : NetworkImage(_image),
                              ))),
                      otherAccountsPictures: <Widget>[
                        Container(
                            margin: EdgeInsets.all(0.0),
                            height: 50.0,
                            width: 50.0,
                            child: new Row(
                              children: <Widget>[
                                new Icon(
                                  Icons.star,
                                  size: 18.0,
                                  color: Color(MyColors().secondary_color),
                                ),
                                new Text(
                                  '$total_rating',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ))
                      ],
                    ),
                    new Column(children: drawerOptions),
                    new Container(
                      margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
                      child: new Divider(
                        color: Color(MyColors().secondary_color),
                        height: 1.0,
                      ),
                    )
                  ],
                ),
              ]))),
      body: _getDrawerItemWidget(_selectedDrawerIndex),
    );
  }

  Future<void> getDriverReviews() async {
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}');
    await driverRef.child('reviews').once().then((snapshot) {
      if (snapshot.value != null) {
        setState(() {
          for (var value in snapshot.value.values) {
            Reviews reviews = new Reviews.fromJson(value);
            double rate_star = double.parse(reviews.rate_star);
            total_rating = total_rating + rate_star;
          }
        });
      }
    });
  }
}
