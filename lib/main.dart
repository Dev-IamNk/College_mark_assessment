import 'package:app2/admin.dart';
import 'package:app2/chart.dart';
import 'package:app2/Home.dart';
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
        debugShowCheckedModeBanner: false,
        title: 'Flutter Excel Column Chart',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AdminPage());
  }
}
