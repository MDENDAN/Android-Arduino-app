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
        Duration(seconds: 11),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              " Welcome To",
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.085,
                  fontWeight: FontWeight.w600),
            ),
            Container(
                color: Colors.white,
                child: Image.asset("assets/images/logo.gif")),
          ],
        ),
      ),
    );
  }
}
