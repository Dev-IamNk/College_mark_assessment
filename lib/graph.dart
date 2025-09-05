import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Excel Column Chart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }     
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<_ChartData> chartData = [];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes != null) {
        var excel = Excel.decodeBytes(fileBytes);
        _parseExcelData(excel);
      }
    }
  }

  void _parseExcelData(Excel excel) {
    List<_ChartData> data = [];
    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet != null) {
        for (var row in sheet.rows.skip(1)) {  // Skip header row
          var xValue = row[0]?.value;
          var yValue = row[0]?.value;
          if (xValue != null && yValue != null) {
            data.add(_ChartData(xValue.toString(), double.parse(yValue.toString())));
          }
        }
      }
    }
    setState(() {
      chartData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel File to Column Chart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Upload Excel File'),
            ),
            const SizedBox(height: 20),
            chartData.isNotEmpty
                ? Container(
              height: 400,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                  )
                ],
              ),
            )
                : const Text('No data to display'),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
