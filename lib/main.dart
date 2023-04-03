// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection? connection;

  late int _deviceState;

  bool isDisconnecting = false;

  Map<String, Color?> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[400],
    'offTextColor': Colors.red[400],
    'neutralTextColor': Colors.blue,
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

    _deviceState = 0; // neutral

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
        title: Text("HOMIFY"),
        backgroundColor: colors['neutralTextColor'],
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton(
                          items: _getDeviceItems(),
                          onChanged: (value) =>
                              setState(() => _device = value!),
                          value: _devicesList.isNotEmpty ? _device : null,
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "NOTE: If you cannot find the device in the list, please pair the device by going to the bluetooth settings",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 5),
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
                  Divider(height: 3, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "Appliances",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.37,
                    child: SingleChildScrollView(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    // ignore: unnecessary_new
                                    side: new BorderSide(
                                      color: _deviceState == 0
                                          ? colors['neutralBorderColor']!
                                          : _deviceState == 1
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
                                            "DEVICE 1",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: _deviceState == 0
                                                  ? colors['neutralTextColor']
                                                  : _deviceState == 1
                                                      ? colors['onTextColor']
                                                      : colors['offTextColor'],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOnMessageToBluetooth(
                                                      "b");
                                                }
                                              : null,
                                          child: Text("ON"),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOffMessageToBluetooth(
                                                      "a");
                                                }
                                              : null,
                                          child: Text("OFF"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    // ignore: unnecessary_new
                                    side: new BorderSide(
                                      color: _deviceState == 0
                                          ? colors['neutralBorderColor']!
                                          : _deviceState == 1
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
                                            "DEVICE 2",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: _deviceState == 0
                                                  ? colors['neutralTextColor']
                                                  : _deviceState == 1
                                                      ? colors['onTextColor']
                                                      : colors['offTextColor'],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOnMessageToBluetooth(
                                                      "c");
                                                }
                                              : null,
                                          child: Text("ON"),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOffMessageToBluetooth(
                                                      "d");
                                                }
                                              : null,
                                          child: Text("OFF"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    // ignore: unnecessary_new
                                    side: new BorderSide(
                                      color: _deviceState == 0
                                          ? colors['neutralBorderColor']!
                                          : _deviceState == 1
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
                                            "DEVICE 3",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: _deviceState == 0
                                                  ? colors['neutralTextColor']
                                                  : _deviceState == 1
                                                      ? colors['onTextColor']
                                                      : colors['offTextColor'],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOnMessageToBluetooth(
                                                      "e");
                                                }
                                              : null,
                                          child: Text("ON"),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOffMessageToBluetooth(
                                                      "f");
                                                }
                                              : null,
                                          child: Text("OFF"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    // ignore: unnecessary_new
                                    side: new BorderSide(
                                      color: _deviceState == 0
                                          ? colors['neutralBorderColor']!
                                          : _deviceState == 1
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
                                            "DEVICE 4",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: _deviceState == 0
                                                  ? colors['neutralTextColor']
                                                  : _deviceState == 1
                                                      ? colors['onTextColor']
                                                      : colors['offTextColor'],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOnMessageToBluetooth(
                                                      "g");
                                                }
                                              : null,
                                          child: Text("ON"),
                                        ),
                                        TextButton(
                                          onPressed: _connected
                                              ? () {
                                                  _sendOffMessageToBluetooth(
                                                      "h");
                                                }
                                              : null,
                                          child: Text("OFF"),
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
            ],
          ),
        ),
      ),
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
        show('Device connected');

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
      _deviceState = 0;
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
  _sendOnMessageToBluetooth(String message) async {
    connection?.output.add(utf8.encode("$message") as Uint8List);
    await connection?.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  _sendOffMessageToBluetooth(String message) async {
    connection?.output.add(utf8.encode("$message") as Uint8List);
    await connection?.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  show(
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    await Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue[300],
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}
