// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';

// For using PlatformException
import 'package:demo_arduino/bluetooth.dart';
import 'package:demo_arduino/splash_screen.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: splashscreen(),
    );
  }
}
