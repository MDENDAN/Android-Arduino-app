import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:demo_arduino/api/sppech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  final FlutterTts flutterTts = FlutterTts();
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Get the instance of the Bluetooth
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection? connection;

  List _deviceState = [0, 0, 0, 0];
  List variables = ["a", "c", "e", "g", "b", "d", "f", "h"];
  List roomAppliance = ['Bedroom', 'Kitchen', 'Room', 'Bathroom'];
  bool isDisconnecting = false;

  String text = 'Press the button and give command';
  bool isListening = false;

  Map<String, Color?> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[400],
    'offTextColor': Colors.red[400],
    'neutralTextColor': Colors.blue,
    'disableColor': Colors.blue[100]
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection!.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    // _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = '' as BluetoothConnection;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<bool> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    } catch (e) {
      print(e);
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: new Image.asset(
          "assets/images/icon.jpg",
          fit: BoxFit.cover,
        ),
        title: Text(
          "HOMIFY",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: MediaQuery.of(context).size.height * 0.05),
        ),
        backgroundColor: colors["neutralTextColor"],
        actions: <Widget>[
          TextButton.icon(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            label: Text(
              "Refresh",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              // So, that when new devices are paired
              // while the app is running, user can refresh
              // the paired devices list.
              await getPairedDevices().then((_) {
                show('Device list refreshed');
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Visibility(
                visible: _isButtonUnavailable &&
                    _bluetoothState == BluetoothState.STATE_ON,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.yellow,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Enable Bluetooth',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        future() async {
                          if (value) {
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          } else {
                            await FlutterBluetoothSerial.instance
                                .requestDisable();
                          }

                          await getPairedDevices();
                          _isButtonUnavailable = false;

                          if (_connected) {
                            _disconnect();
                          }
                        }

                        future().then((_) {
                          setState(() {});
                        });
                      },
                    )
                  ],
                ),
              ),
              Divider(height: 3, color: Colors.grey),
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "PAIRED DEVICES",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Device:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(
                          width: 3,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.55,
                          child: DropdownButton(
                            alignment: AlignmentDirectional.topCenter,
                            items: _getDeviceItems(),
                            onChanged: (value) =>
                                setState(() => _device = value!),
                            value: _devicesList.isNotEmpty ? _device : null,
                          ),
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isButtonUnavailable
                                ? null
                                : _connected
                                    ? _disconnect
                                    : _connect,
                            child: Text(
                              _connected ? 'Disconnect' : 'Connect',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 5,
                  ),
                  // Divider(height: 3, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "Appliances",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      // ignore: unnecessary_new
                                      side: new BorderSide(
                                        color: _deviceState[i] == 0
                                            ? colors['neutralBorderColor']!
                                            : _deviceState[i] == 1
                                                ? colors['onBorderColor']!
                                                : colors['offBorderColor']!,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    elevation: _deviceState == 0 ? 4 : 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              roomAppliance[i],
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: isConnected
                                                    ? _deviceState[i] == 0
                                                        ? colors[
                                                            'neutralTextColor']
                                                        : _deviceState[i] == 1
                                                            ? colors[
                                                                'onTextColor']
                                                            : colors[
                                                                'offTextColor']
                                                    : colors["disableColor"],
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                                backgroundColor: isConnected
                                                    ? Colors.blue
                                                    : colors["disableColor"]),
                                            onPressed: _connected
                                                ? () {
                                                    _sendOnMessageToBluetooth(
                                                        variables[i + 4], i);
                                                  }
                                                : floatingButtonDisableClick,
                                            child: Text(
                                              "ON",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                                backgroundColor: isConnected
                                                    ? Colors.blue
                                                    : colors["disableColor"]),
                                            onPressed: _connected
                                                ? () {
                                                    _sendOffMessageToBluetooth(
                                                        variables[i], i);
                                                  }
                                                : floatingButtonDisableClick,
                                            child: Text(
                                              "OFF",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              isConnected
                  ?
                  // Speech text
                  Column(
                      children: [
                        Divider(color: Colors.black87, thickness: 1.5),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: text,
                                    style: TextStyle(
                                      color: Colors.black,
                                    )),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  : Container(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 20),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                  Text(
                                    "NOTE: Please pair the device before connecting by going to the bluetooth settings",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            // elevation: 2,
                            child: Text("Bluetooth Settings"),
                            onPressed: () {
                              FlutterBluetoothSerial.instance.openSettings();
                            },
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: isConnected
          ? FloatingActionButtonLocation.miniCenterDocked
          : FloatingActionButtonLocation.endDocked,
      floatingActionButton: AvatarGlow(
        endRadius: 55,
        animate: isListening,
        glowColor: colors['neutralTextColor']!,
        child: FloatingActionButton(
          backgroundColor:
              isConnected ? colors['neutralTextColor'] : Colors.black12,
          onPressed: isConnected
              ? () async {
                  await toggleRecording();
                }
              : floatingButtonDisableClick,
          child: Icon(
            isListening ? Icons.mic : Icons.mic_off_outlined,
            size: 30,
          ),
        ),
      ),
      // bottomNavigationBar: FloatingActionButton(
      //   onPressed: () {},
      //   child: Icon(Icons.mic),
      // ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          value: device,
          child: Text(device.name ?? ''),
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    print('Connecting');
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        print('Awaiting to connect');
        await BluetoothConnection.toAddress(_device?.address)
            .then((_connection) {
          print('Connected to the device');
          show('Device connected');
          connection = _connection;
          setState(() {
            _connected = true;
            print(connection?.isConnected);
          });

          connection!.input?.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // void _onDataReceived(Uint8List data) {
  //   // Allocate buffer for parsed data
  //   int backspacesCounter = 0;
  //   data.forEach((byte) {
  //     if (byte == 8 || byte == 127) {
  //       backspacesCounter++;
  //     }
  //   });
  //   Uint8List buffer = Uint8List(data.length - backspacesCounter);
  //   int bufferIndex = buffer.length;

  //   // Apply backspace control character
  //   backspacesCounter = 0;
  //   for (int i = data.length - 1; i >= 0; i--) {
  //     if (data[i] == 8 || data[i] == 127) {
  //       backspacesCounter++;
  //     } else {
  //       if (backspacesCounter > 0) {
  //         backspacesCounter--;
  //       } else {
  //         buffer[--bufferIndex] = data[i];
  //       }
  //     }
  //   }
  // }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      for (var i = 0; i < 4; i++) {
        _deviceState[i] = 0;
      }
    });

    await connection?.close();
    show('Device disconnected');
    if (!connection!.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  _sendOnMessageToBluetooth(String message, int i) async {
    connection?.output.add(utf8.encode("$message") as Uint8List);
    await connection?.output.allSent;
    show('${roomAppliance[i]} LED turned on');
    setState(() {
      _deviceState[i] = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  _sendOffMessageToBluetooth(String message, int i) async {
    connection?.output.add(utf8.encode("$message") as Uint8List);
    await connection?.output.allSent;
    show('${roomAppliance[i]} LED switch Off');
    setState(() {
      _deviceState[i] = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  show(
    String message, {
    Duration duration = const Duration(milliseconds: 700),
  }) async {
    await Future.delayed(new Duration(milliseconds: 100));
    speak(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isConnected ? Colors.blue[300] : colors["disableColor"],
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  Future toggleRecording() {
    return SpeechApi.toggleRecording(
      onResult: (text) => setState(() {
        this.text = text;
        handleVoiceCommand(text);
      }),
      onListening: (isListening) {
        setState(() => this.isListening = isListening);
      },
    );
  }

  floatingButtonDisableClick() {
    show('Connect to device');
  }

  void handleVoiceCommand(String text) {
    List list = text.split(' ');
    var i = 0;
    while (roomAppliance.isNotEmpty) {
      if (list[0] == roomAppliance[i].toString().toLowerCase()) {
        break;
      }
      i++;
    }
    switch (list[list.length - 1]) {
      case "off":
        _sendOffMessageToBluetooth(variables[i], i);
        break;
      case "on":
        _sendOnMessageToBluetooth(variables[i + 4], i);
        break;
      // Add more cases for other voice commands here
      default:
        speak("Unrecognized command: $text");
    }
  }

  speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(0.9);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setVolume(1);
    await flutterTts.speak(text);
  }
}
