import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:test_app/view.dart';
import 'package:test_app/widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget _streamBuilder(c, snapshot) {
    final state = snapshot.data;
    if (state == BluetoothState.on) {
      return FindDevicesScreen();
    }
    return MyHomePage(title: 'Flutter Demo Home Page');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: StreamBuilder(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) => _streamBuilder(c, snapshot),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordPair = "Bluetooth not enabled";
    return Scaffold(
      appBar: AppBar(
        title: Text(wordPair),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Please enable Bluetooth',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  final Widget stopButton = FloatingActionButton(
    child: Icon(Icons.stop),
    onPressed: () => FlutterBlue.instance.stopScan(),
    backgroundColor: Colors.red,
  );

  final Widget startButton = FloatingActionButton(
    child: Icon(Icons.search),
    onPressed: () =>
        FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
  );

  Widget _streamBuilderFB(c, snapshot) {
    if (snapshot.data) {
      return stopButton;
    } else {
      return startButton;
    }
  }

  Widget _streamBuilder2(c, snapshot, device) {
    if (snapshot.data == BluetoothDeviceState.connected) {
      return RaisedButton(
        child: Text('OPEN'),
        onPressed: () => Navigator.of(c).push(MaterialPageRoute(
            builder: (context) => DeviceScreenView(device: device))),
      );
    }
    return Text(snapshot.data.toString());
  }

  Widget _deviceScreenBuilder(context, r) {
    r.device.connect();
    return DeviceScreenView(device: r.device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                // Currently connected devices
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                                stream: d.state,
                                initialData: BluetoothDeviceState.disconnected,
                                builder: (c, snapshot) =>
                                    _streamBuilder2(c, snapshot, d)),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                // Devices available to connect to
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      _deviceScreenBuilder(context, r))),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) => _streamBuilderFB(c, snapshot),
      ),
    );
  }
}
