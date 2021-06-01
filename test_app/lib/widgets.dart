import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

// import 'package:test_app/painters.dart';
// import 'package:test_app/structures.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

// class PaintStream extends StatefulWidget {
//   final BluetoothCharacteristic char;
//   const PaintStream({Key key, this.char}) : super(key: key);

//   @override
//   _PaintStream createState() => _PaintStream();
// }

// class _PaintStream extends State<PaintStream> {
//   var data = DataStruct();

//   List<int> outputList = [-1];

//   Future<void> _notifPressed() async {
//     await widget.char.setNotifyValue(true);
//     setState(() {});
//   }

//   Widget _streamBuilder(c, snapshot) {
//     data.setVals(snapshot.data);
//     return PaintWidget(data: data);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.char.isNotifying) {
//       return IconButton(
//         icon: Icon(Icons.access_alarm),
//         onPressed: () => _notifPressed(),
//       );
//     } else {
//       return SafeArea(
//         child: StreamBuilder<List<int>>(
//           stream: widget.char.value,
//           initialData: widget.char.lastValue,
//           builder: (c, snapshot) => _streamBuilder(c, snapshot),
//         ),
//       );
//     }
//   }
// }

// class _PaintStreamTest extends State<PaintStream> {
//   var data = DataStruct();

//   List<int> outputList = [-1];

//   Future<void> _notifPressed() async {
//     await widget.char.setNotifyValue(true);
//     setState(() {});
//   }

//   Widget _streamBuilder(c, snapshot) {
//     data.setVals(snapshot.data);
//     return PaintWidget(data: data);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.char.isNotifying) {
//       return IconButton(
//         icon: Icon(Icons.access_alarm),
//         onPressed: () => _notifPressed(),
//       );
//     } else {
//       return SafeArea(
//         child: StreamBuilder<List<int>>(
//           stream: widget.char.value,
//           initialData: widget.char.lastValue,
//           builder: (c, snapshot) => _streamBuilder(c, snapshot),
//         ),
//       );
//     }
//   }
// }
