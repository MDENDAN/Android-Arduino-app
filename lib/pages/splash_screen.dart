import 'dart:async';

import 'package:demo_arduino/pages/bluetooth.dart';
import 'package:flutter/material.dart';

class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _splashscreenState();
}

class _splashscreenState extends State<splashscreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(
        Duration(seconds: 5),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BluetoothApp())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AiUTOMATION"),
      ),
      body: Center(
        child: Container(
            color: Colors.white, child: Image.asset("assets/images/logo.jpg")),
      ),
    );
  }
}
