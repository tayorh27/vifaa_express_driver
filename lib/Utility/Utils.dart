import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vifaa_express_driver/Models/fares.dart';
import 'package:vifaa_express_driver/Models/user.dart';
import 'package:vifaa_express_driver/Utility/MyColors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  DatabaseReference configRef;
  String currency = '', code = '';

  Future<void> initializeRemoteConfig(String country) async {
    configRef =
        FirebaseDatabase.instance.reference().child('settings/configuration');
    configRef.child(country).child('currency').once().then((val) {
      currency = (val == null) ? 'USD' : val.value.toString();
    });
    configRef.child(country).child('code').once().then((val) {
      code = (val == null) ? 'USD' : val.value.toString();
    });
  }

  String fetchCurrency() {
    return currency;
  }

  String fetchCurrencyCode() {
    return code;
  }

  String sms_USERNAME = "vifaaexpress";

  String sms_PASSWORD = "vifaa1234";

  String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImQwNjEzMjQzOGUzZmYxMmY0MTlhOWU1Y2I1NTY4ZDE0Mzg3ZTZhNDg0ZTQ0ZDE4YzkyMTI5MTM1MjZjMmUzODJhNDE0NDhiOTU1NGU2YjdiIn0.eyJhdWQiOiIxIiwianRpIjoiZDA2MTMyNDM4ZTNmZjEyZjQxOWE5ZTVjYjU1NjhkMTQzODdlNmE0ODRlNDRkMThjOTIxMjkxMzUyNmMyZTM4MmE0MTQ0OGI5NTU0ZTZiN2IiLCJpYXQiOjE1NTUzNDc4NDYsIm5iZiI6MTU1NTM0Nzg0NiwiZXhwIjoxNTg2OTcwMjQ2LCJzdWIiOiIyODQxOCIsInNjb3BlcyI6W119.ekd79q__LDX8UMEZdDmrkP9pgRY9IHAs16F6999FipasLDtjjlW1-FYOSqu0bnNAYdzWeyLuUKBvmIO7trEUZdbOJ3O8OyeTQv4sZt9JpXtF43yzrnbNUYWIrqUtSdXF-Km85uaOLB3sCLx8iBz6YcZniz-0eqfCVT26L0I92lsUZ_BJ1723SuUZX22RcI4E_B8OTEnQXl5s90EoLyac0tdwdLe3BbK4Cw11CZU3F-5oUCPhF7RYWO4fZwlD2bEO9IdGD496RFv0zG7GSqWZCsU4bgselWOPcm2tkvEF2nYOM-JtNVxq9eFNRDuyuOgHY9uFeLB7K5a155qKOvAWweqCK8YCzIIsHZxy3txBZj2CcflZUYyPPLVAR1Hbaw-bT8r93iIRxzo8C62uNlvle11Zz9y7wLI1CmvK6KyQW6cFN8TQKHDQy8SPNh34owWJLHmQf3K_1FmBtibO2lx4oF2D-9EMo-PvbzOw_LZddyBerdrOmGyIha3R8ZDxMTvbgpqxpYmo2zdbl6bbS1Vl8iX6gR2vJ9diEmGucBwifL330p6OFZFWta56sJ80JrQiGH8pBBQTlM6qc0aV5j8qnMgSdTgJ6H8GvTp92G_VvOOGEC5ap7JW3WW2SkqpH3s7ALrNAtznkyUnujDd2qrrvZYwiP40uSmYmAYEKshxkVk';
  Future<bool> sendNotification(
      String title, String body, String msgId, String mobile, String receiver) async {
    String sms_URL =
        'https://api.loftysms.com/simple/sendsms?username=$sms_USERNAME&password=$sms_PASSWORD&sender=Vifaa&sms_type=1&corporate=1&recipient=$mobile${(receiver.isNotEmpty) ? ',$receiver' : ''}&message=$body'; //https://jusibe.com/smsapi/send_sms
    final response = await http.get(sms_URL, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      // on success do sth
      return true;
    } else {
      // on failure do sth
      return false;
    }

//    final postUrl = 'https://fcm.googleapis.com/fcm/send';
//
//    final data = {
//      "notification": {"body": "$body", "title": "$title"},
//      "priority": "high",
////      "data": {
////        "click_action": "FLUTTER_NOTIFICATION_CLICK",
////        "id": "1",
////        "status": "done"
////      },
//      "to": "$msgId"
//    };
//
//    final headers = {
//      'content-type': 'application/json',
//      'Authorization':
//          'key=AAAAb5Awy-A:APA91bFJ__L2edL1qeuLLZIcZivz72i_5IMfbCK7t2c8MuEdc0DJVoLVTQdBnjAkXXUAmMZagoXoFAGJJn92R6B_2_y0gSxmIVBgitVHARqeJfQW8gNFWVmNfFb1niNEEShzQvIru1On'
//    };
//
//    final response = await http.post(postUrl,
//        body: json.encode(data),
//        encoding: Encoding.getByName('utf-8'),
//        headers: headers);
//
//    print('SendNotification: ${response.body}');
  }

  Future<Null> neverSatisfied(
      BuildContext context, String _title, String _body) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(_body),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Null> displayFareInformation(
      BuildContext context, String _title, Fares snapshot) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new ListTile(
                  leading: new Text(
                    'Start fare',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.start_fare}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Wait time fee',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.wait_time_fee}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per distance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.per_distance}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per duration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.per_duration}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showToast(String text, bool isLong) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: isLong ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(MyColors().secondary_color),
        textColor: Color(MyColors()
            .button_text_color)); // backgroundColor: '#FFCA40', textColor: '#12161E');
  }

  Future<bool> sendPushNotification(String to, String title, String msg) async {
    final postUrl = 'https://fcm.googleapis.com/fcm/send';

    final data = {
      "notification": {"body": "$msg", "title": "$title"},
//      "priority": "high",
//      "data": {
//        "click_action": "FLUTTER_NOTIFICATION_CLICK",
//        "id": "1",
//        "status": "done"
//      },
      "to": "$to"
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization':
      'AAAAk7MijUo:APA91bHlIA6Yn1fddxhEZYJyxBBdHAS1sGJI_CHhjtL6a-FNxggUHDeT0GgCQMmiZmY2lje4X5RoGcqZap5ckSYqCmAc200feOADWt3QpyV9iigndvbmD69qVASw0jgoO39UKeUvJRCq'
    };

    final response = await http.post(postUrl,
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    print('SendNotification: ${response.body}');
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }

  }

  void saveUserInfo(User user) {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((pref) {
      pref.setString('id', user.id);
      pref.setString('fullname', user.fullname);
      pref.setString('email', user.email);
      pref.setString('number', user.number);
      pref.setString('msgId', user.msgId);
      pref.setString('uid', user.uid);
      pref.setString('device_info', user.device_info);
      pref.setString('referralCode', user.referralCode);
      pref.setString('vehicle_type', user.vehicle_type);
      pref.setString('vehicle_model', user.vehicle_model);
      pref.setString('vehicle_plate_number', user.vehicle_plate_number);
      pref.setString('rating', user.rating);
      pref.setString('image', user.image);
      pref.setString('status', user.status);
      pref.setString('country', user.country);
      pref.setBool('userBlocked', user.userBlocked);
      pref.setBool('userVerified', user.userVerified);
    });
  }

  User getUser() {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    //User users;
    _prefs.then((pref) {
      return new User(
          pref.getString('id'),
          pref.getString('fullname'),
          pref.getString('email'),
          pref.getString('number'),
          pref.getString('msgId'),
          pref.getString('uid'),
          pref.getString('device_info'),
          pref.getString('referralCode'),
          pref.getString('vehicle_type'),
          pref.getString('vehicle_model'),
          pref.getString('vehicle_plate_number'),
          pref.getString('rating'),
          pref.getString('image'),
          pref.getString('status'),
          pref.getString('country'),
          pref.getBool('userBlocked'),
          pref.getBool('userVerified'));
    });
    return null;
  }
}
