import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:google_fonts/google_fonts.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVIT Students Graph',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Hi(),
    );
  }
}

class Hi extends StatefulWidget {
  @override
  _HiState createState() => _HiState();
}

class _HiState extends State<Hi> {
  final GlobalKey _passCountChartKey = GlobalKey();

  Map<String, int> _passCounts = {};
  List<Map<String, String>> _failedStudentsData = [];
  final GlobalKey _summaryChartKey = GlobalKey(); // Add this to your state
  List<Map<String, String>> _absentStudentsData = [];

  String _selectedClass = "A";
  String _selectedBatch = '2020-2024';
  String _selectedSem = 'sem1';
  String _selectedExam = 'CAT1';
  String _selectedDept = 'IT';

  Map<String, List<_ChartData>> subjectData = {};
  double _maxY = 0.0;
  bool _dataLoaded = false;
  Map<String, String> summaryData = {};
  final List<GlobalKey> _chartKeys = []; // Track GlobalKeys for charts

  void _parseListOfFData(String listOfFData) {
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(listOfFData);
    print(listOfFData);
    final List<Map<String, String>> failedStudents = [];

    for (var row in rows.skip(1)) {
      // Skip header row
      if (row.length >= 4) {
        // Ensure there are enough columns
        final String name = row[1].toString(); // Name is in the second column
        final String subject =
            row[2].toString(); // Subject is in the third column
        failedStudents.add({'Name': name, 'Subject': subject});
      }
    }

    setState(() {
      _failedStudentsData = failedStudents; // Store the data in state
    });

    print(_failedStudentsData); // Output to verify
  }

  Future<void> _printFailuresList() async {
    final pdf = pw.Document();
    int rowsFirstPage = 20; // Rows on the first page for Failures List
    int rowsSubsequentPages = 30; // Rows on subsequent pages for Failures List

    // Handle the first page for Failures List
    if (_failedStudentsData.isNotEmpty) {
      final firstPageData = _failedStudentsData.sublist(
        0,
        _failedStudentsData.length > rowsFirstPage
            ? rowsFirstPage
            : _failedStudentsData.length,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Information
                pw.Text(
                  'Manakula Vinayagar Institute of Technology',
                  style: pw.TextStyle(fontSize: 24),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Department of Information Technology',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Batch: $_selectedBatch',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Semester: $_selectedSem Dept: $_selectedDept Class: $_selectedClass',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Exam: $_selectedExam',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Failures List', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),

                // Failures List Table with S.No.
                pw.Table.fromTextArray(
                  context: context,
                  headers: ['S.No.', 'Name', 'Subject'],
                  data: firstPageData.asMap().entries.map((entry) {
                    int index = entry.key + 1; // Serial number
                    var student = entry.value;
                    return [
                      index.toString(),
                      student['Name'] ?? '',
                      student['Subject'] ?? ''
                    ];
                  }).toList(),
                ),

                // Absent Students List, placed below the Failures List if space allows
                if (_absentStudentsData.isNotEmpty)
                  pw.Partition(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Text('Absent Students List',
                            style: pw.TextStyle(fontSize: 24)),
                        pw.SizedBox(height: 20),

                        // Absent Students List Table with S.No.
                        pw.Table.fromTextArray(
                          context: context,
                          headers: ['S.No.', 'Name', 'Absent Subjects'],
                          data:
                              _absentStudentsData.asMap().entries.map((entry) {
                            int index = entry.key + 1; // Serial number
                            var student = entry.value;
                            return [
                              index.toString(),
                              student['Name'] ?? '',
                              student['Subject'] ?? ''
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Handle subsequent pages for Failures List
    for (int i = rowsFirstPage;
        i < _failedStudentsData.length;
        i += rowsSubsequentPages) {
      final pageData = _failedStudentsData.sublist(
        i,
        i + rowsSubsequentPages > _failedStudentsData.length
            ? _failedStudentsData.length
            : i + rowsSubsequentPages,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Failures List Table with S.No. on subsequent pages
                pw.Table.fromTextArray(
                  context: context,
                  headers: ['S.No.', 'Name', 'Subject'],
                  data: pageData.asMap().entries.map((entry) {
                    int index =
                        i + entry.key + 1; // Adjusted serial number for pages
                    var student = entry.value;
                    return [
                      index.toString(),
                      student['Name'] ?? '',
                      student['Subject'] ?? ''
                    ];
                  }).toList(),
                ),

                // Absent Students List on new page if needed
                if (i + rowsSubsequentPages >= _failedStudentsData.length &&
                    _absentStudentsData.isNotEmpty)
                  pw.Partition(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Text('Absent Students List',
                            style: pw.TextStyle(fontSize: 24)),
                        pw.SizedBox(height: 20),

                        // Absent Students List Table with S.No.
                        pw.Table.fromTextArray(
                          context: context,
                          headers: ['S.No.', 'Name', 'Subject'],
                          data:
                              _absentStudentsData.asMap().entries.map((entry) {
                            int index =
                                entry.key + 1; // Serial number for absentees
                            var student = entry.value;
                            return [
                              index.toString(),
                              student['Name'] ?? '',
                              student['Subject'] ?? ''
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Save and print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

// Function to calculate pass counts

  Widget _buildPassCountChart(Map<String, int> passCounts) {
    // Limit the number of subjects to 6, or less if fewer are available
    final List<_ChartData> chartData = passCounts.entries
        .take(6) // This limits the list to the first 6 entries
        .map((entry) => _ChartData(entry.key, entry.value.toDouble()))
        .toList();

    return RepaintBoundary(
      key: _passCountChartKey,
      child: Container(
        width: 700, // Adjust width as needed
        height: 500, // Adjust height as needed
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Colors.white),
        child: SfCartesianChart(
          primaryXAxis: CategoryAxis(
            title: AxisTitle(
              text: 'Subjects',
              textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins'), // Set font size and family
            ),
            majorGridLines: MajorGridLines(width: 0),
            edgeLabelPlacement:
                EdgeLabelPlacement.shift, // Shift labels if overlapping
            labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
                fontFamily: 'Poppins'), // Axis labels font size
            labelIntersectAction:
                AxisLabelIntersectAction.wrap, // Wrap the labels
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(
              text: 'Pass Count',
              textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  fontFamily: 'Poppins',
                  color: Colors.black), // Set font size and family
            ),
            majorGridLines: MajorGridLines(width: 0), // Hide grid lines
            labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Poppins'), // Axis labels font size
            maximum: 70, // Set maximum Y-axis value to 70
            interval: 5, // Set the interval between grid lines to 5
          ),
          title: ChartTitle(
            text: 'Pass Counts by Subject',
            textStyle: TextStyle(
                fontSize: 20, fontFamily: 'Poppins'), // Chart title font size
          ),
          series: <ColumnSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
              animationDuration: 0,
              dataSource: chartData,
              xValueMapper: (_ChartData data, _) => data.grade,
              yValueMapper: (_ChartData data, _) => data.count,
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment
                    .outer, // Ensure labels are above the bars
                textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Poppins'), // Data labels font size
              ),
              color: Colors.teal, // Use a single color for simplicity
            ),
          ],
        ),
      ),
    );
  }

  void _getData() async {
    final url = Uri.parse('http://localhost/dashboard/mvit/getData.php');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'batch': _selectedBatch,
          'sem': _selectedSem,
          'exam': _selectedExam,
          'class': _selectedClass,
          'Dept': _selectedDept
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data.containsKey('excel')) {
            final String csvData = data['excel'];
            _parseCsvData(csvData);

            // Calculate pass counts and update the chart
            final passCounts = calculatePassCounts(csvData);
            setState(() {
              _passCounts = passCounts; // Update the state with the pass counts
            });
          }

          if (data.containsKey('summary')) {
            final String summaryCsv = data['summary'];
            _parseSummaryData(summaryCsv);
          }

          if (data.containsKey('ListofF')) {
            final String listOfFData = data['ListofF'];
            _parseListOfFData(listOfFData);
          }

          if (data.containsKey('ListofAbsent')) {
            final String listOfAbsentData = data['ListofAbsent'];
            _parseListOfAbsentData(listOfAbsentData);
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Map<String, int> calculatePassCounts(String csvData) {
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    List<String> headers = List<String>.from(rows[0]);
    List<List<dynamic>> data = rows.sublist(1);

    int sIndex = headers.indexOf('S');
    int aIndex = headers.indexOf('A');
    int bIndex = headers.indexOf('B');
    int cIndex = headers.indexOf('C');
    int dIndex = headers.indexOf('D');
    int eIndex = headers.indexOf('E');

    Map<String, int> passCounts = {};

    for (var row in data) {
      String subject = row[0] as String;
      int sCount = row[sIndex] as int;
      int aCount = row[aIndex] as int;
      int bCount = row[bIndex] as int;
      int cCount = row[cIndex] as int;
      int dCount = row[dIndex] as int;
      int eCount = row[eIndex] as int;

      int passCount = sCount + aCount + bCount + cCount + dCount + eCount;
      passCounts[subject] = passCount;
    }

    return passCounts; // Return the calculated pass counts
  }

  void _parseListOfAbsentData(String listOfAbsentData) {
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(listOfAbsentData);

    final List<Map<String, String>> absentStudents = [];

    for (var row in rows.skip(1)) {
      // Skip header row
      if (row.length >= 3) {
        // Corrected check
        final String name = row[1].toString(); // Name in second column
        final String subject =
            row[2].toString(); // Absent subjects in third column
        absentStudents.add({'Name': name, 'Subject': subject});
      }
    }

    setState(() {
      _absentStudentsData = absentStudents;
    });

    print(_absentStudentsData); // Verify the output
  }

  void _parseCsvData(String csvData) {
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(csvData);

    final headers = rows.first;
    final gradeHeaders = headers.skip(1).toList();

    Map<String, Map<String, int>> subjectGrades = {};
    for (var row in rows.skip(1)) {
      if (row.length > 1) {
        final subject = row[0];
        final grades = row.skip(1).toList().asMap();
        subjectGrades[subject] = {};
        for (var i = 0; i < gradeHeaders.length; i++) {
          final grade = gradeHeaders[i];
          final count = grades[i];
          if (count != null) {
            // Null check added
            subjectGrades[subject]![grade] = count as int;
          } else {
            print("Null count found in grades for $subject and grade $grade");
          }
        }
      }
    }

    setState(() {
      subjectData = {};
      _maxY = 0.0;

      subjectGrades.forEach((subject, grades) {
        List<_ChartData> chartData = [];
        grades.forEach((grade, count) {
          chartData.add(_ChartData(grade, count.toDouble()));
        });

        subjectData[subject] = chartData;
        _maxY = [...grades.values].reduce((a, b) => a > b ? a : b).toDouble();
      });

      _maxY += 6;
      _dataLoaded = true;
    });
  }

  void _parseSummaryData(String summaryCsv) {
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(summaryCsv);

    int totalStudents = 0;
    int passed = 0;
    int failed = 0;
    int absent = 0;
    int appeared = 0;

    final Map<String, int> summaryMap = {};

    for (var row in rows) {
      if (row.length >= 2) {
        summaryMap[row[0].toString()] = int.tryParse(row[1].toString()) ?? 0;
      }
    }

    totalStudents = summaryMap['Total Students'] ?? 0;
    passed = summaryMap['Students Passed'] ?? 0;
    failed = summaryMap['Students Failed'] ?? 0;
    absent = summaryMap['Students Absent'] ?? 0;
    appeared = summaryMap['Students Appeared'] ?? 0;

    final double passPercentage =
        (totalStudents > 0) ? (passed / totalStudents) * 100 : 0;
    final double failPercentage =
        (totalStudents > 0) ? (failed / totalStudents) * 100 : 0;
    final double absentPercentage =
        (totalStudents > 0) ? (absent / totalStudents) * 100 : 0;
    final double appearedPercentage =
        (totalStudents > 0) ? (appeared / totalStudents) * 100 : 0;
    final double overallPassPercentage =
        (appeared > 0) ? (passed / appeared) * 100 : 0;

    setState(() {
      summaryData = {
        'Total Students': '$totalStudents',
        'No of Students Appeared':
            '$appeared (${appearedPercentage.toStringAsFixed(2)}%)',
        'No of Students Absent':
            '$absent (${absentPercentage.toStringAsFixed(2)}%)',
        'No of Students Passed':
            '$passed (${passPercentage.toStringAsFixed(2)}%)',
        'No of Students Failed':
            '$failed (${failPercentage.toStringAsFixed(2)}%)',
        'Overall Pass Percentage':
            '$passed/$appeared (${overallPassPercentage.toStringAsFixed(2)}%)',
      };
    });

    // Data for Summary Chart
    summaryChartData = [
      _ChartData('Total', totalStudents.toDouble()),
      _ChartData('Appeared', appeared.toDouble()),
      _ChartData('Ab', absent.toDouble()),
      _ChartData('Pass', passed.toDouble()),
      _ChartData('Fail', failed.toDouble()),
    ];
  }

// Define this as a state variable
  List<_ChartData> summaryChartData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[200],
      appBar: AppBar(
        toolbarHeight: 160,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth < 600 // Adjust the breakpoint as needed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "MVIT-logo_news.png",
                        height: 100,
                      ),
                      SizedBox(
                        height: 8,
                      ), // Spacing between image and text
                      Text(
                        "Department of IT",
                        style: GoogleFonts.poppins(
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Internal assessment Report",
                        style: GoogleFonts.poppins(
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/MVIT-logo_news.png",
                        height: 100,
                      ),
                      Spacer(), // Spacing between image and text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Department of IT Internal assessment Report",
                              style: GoogleFonts.poppins(
                                textStyle:
                                    Theme.of(context).textTheme.titleLarge,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
          },
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Add the dropdown menu here

              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextButton("Submit", _getData),
                  SizedBox(width: 20),
                  _buildTextButton("Print Graph", _printDocument),
                  SizedBox(width: 20),
                  _buildTextButton(
                      "Failures List", () => _showFailuresListDialog(context)),
                ],
              ),
              const SizedBox(height: 20),
              _dataLoaded
                  ? _buildChartGrid()
                  : Center(
                      child: Text(
                      'No data to display',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.titleLarge,
                      ),
                    )),
              const SizedBox(height: 20),
              if (_dataLoaded)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 800;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 100),
                          child: Container(
                              height: 400,
                              width: 450,
                              child: _buildPassCountChart(_passCounts)),
                        ),
                        Text(
                          "Cumulative Score:",
                          style: GoogleFonts.poppins(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(height: 20),
                        isWideScreen
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(child: _buildSummaryTable()),
                                  Expanded(
                                      flex: 1, child: _buildSummaryChart()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildSummaryTable(),
                                  SizedBox(height: 20),
                                  _buildSummaryChart(),
                                ],
                              ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all(Color.fromRGBO(1, 68, 84, 0)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            side: BorderSide(color: Color.fromARGB(255, 132, 131, 131)),
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: Color.fromARGB(255, 89, 88, 88)),
      ),
    );
  }

  Future<List<Uint8List>> _captureCharts(List<GlobalKey> chartKeys,
      GlobalKey summaryChartKey, GlobalKey passCountChartKey) async {
    final List<Uint8List> chartImages = [];

    // Capture all regular charts
    for (final key in chartKeys) {
      final imageBytes = await _captureWidgetAsImage(key);
      if (imageBytes.isNotEmpty) {
        chartImages.add(imageBytes);
      } else {
        print("Skipped adding empty image for key: $key");
      }
    }

    // Capture Pass Count Chart
    final passCountImage = await _captureWidgetAsImage(passCountChartKey);
    if (passCountImage.isNotEmpty) {
      chartImages
          .add(passCountImage); // Add pass count chart before the summary chart
    } else {
      print("Skipped adding empty image for pass count chart.");
    }

    // Capture Summary Chart
    final summaryChartImage = await _captureWidgetAsImage(summaryChartKey);
    if (summaryChartImage.isNotEmpty) {
      chartImages.add(summaryChartImage);
    } else {
      print("Skipped adding empty image for summary chart.");
    }

    return chartImages;
  }

  void _showFailuresListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Failures List'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Subject')),
                ],
                rows: _failedStudentsData.map((student) {
                  return DataRow(cells: [
                    DataCell(Text(student['Name'] ?? '')),
                    DataCell(Text(student['Subject'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Print'),
              onPressed: () {
                _printFailuresList();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryChart() {
    return RepaintBoundary(
      key: _summaryChartKey,
      child: Container(
        // Adjust width if needed
        width: 300,
        height: 400, // Adjust height if needed
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(
                    text: 'Categories',
                    textStyle: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins'),
                  ),
                  majorGridLines: MajorGridLines(width: 0),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                      color: Colors.black,
                      fontFamily: 'Poppins'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'Count',
                    textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        fontFamily: 'Poppins',
                        color: Colors.black),
                  ),
                  majorGridLines: MajorGridLines(width: 0),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 22,
                      fontFamily: 'Poppins'),
                ),
                title: ChartTitle(
                  text: 'Summary Data Overview',
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                series: <ColumnSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    animationDuration: 0,
                    dataSource: summaryChartData,
                    xValueMapper: (_ChartData data, _) => data.grade,
                    yValueMapper: (_ChartData data, _) => data.count,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.outer,
                      textStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16), // Space between the charts
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _captureWidgetAsImage(GlobalKey key) async {
    RenderRepaintBoundary? boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      print("RenderRepaintBoundary not found for key: $key");
      return Uint8List(0); // Return empty image data if boundary is null
    }

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      print("Failed to convert image to ByteData.");
      return Uint8List(0); // Return empty image data if byteData is null
    }

    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }

  Future<void> _printDocument() async {
    // Show Snackbar indicating loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading...'),
        duration:
            Duration(minutes: 1), // Keep Snackbar visible until task completes
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            // Allow user to dismiss Snackbar manually
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    try {
      // Load asset image (college logo)
      final ByteData imageData =
          await rootBundle.load('assets/MVIT-logo_news.png');
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Capture charts (subject charts and summary chart) and pass count chart
      final chartImages = await _captureCharts(
          _chartKeys, _summaryChartKey, _passCountChartKey);
      final passCountChartImage = await _captureWidgetAsImage(
          _passCountChartKey); // Capture the pass count chart

      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoExtraLight();

      // First Page: College Image, Department Info, and First Four Charts
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            final availableWidth = context.page.pageFormat.availableWidth - 30;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Manakula Vinayagar Institute of Technology",
                  style: pw.TextStyle(fontSize: 20, font: font),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Department of $_selectedDept',
                  style: pw.TextStyle(fontSize: 17, font: font),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Batch: $_selectedBatch,Dept: $_selectedDept, Semester: $_selectedSem,',
                  style: pw.TextStyle(fontSize: 18, font: font),
                ),
                pw.Text(
                  'Exam: $_selectedExam Class: $_selectedClass',
                  style: pw.TextStyle(fontSize: 18, font: font),
                ),

                pw.SizedBox(height: 20),
                pw.Text(
                  'Subject Wise Result Analysis:',
                  style: pw.TextStyle(fontSize: 20, font: font),
                ),
                pw.SizedBox(height: 10),
                // Display first four charts
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: chartImages.take(4).map((image) {
                    return pw.Container(
                      width: (availableWidth + 15) / 2, // Adjust width
                      height: (availableWidth + 100) / 2, // Adjust height
                      child: pw.Image(
                        pw.MemoryImage(image),
                        fit: pw.BoxFit.contain,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Second Page: Remaining Charts, Summary Table, and Pass Count Chart
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            final availableWidth = context.page.pageFormat.availableWidth - 30;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Display remaining charts
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: chartImages.skip(4).map((image) {
                    return pw.Container(
                      width: (availableWidth + 10) / 2, // Adjust width
                      height: (availableWidth + 100) / 2, // Adjust height
                      child: pw.Image(
                        pw.MemoryImage(image),
                        fit: pw.BoxFit.contain,
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Summary:',
                  style: pw.TextStyle(fontSize: 20, font: font),
                ),
                pw.SizedBox(height: 10),
                // Summary Table
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Description', 'Percentage'],
                    ...summaryData.entries
                        .map((entry) => [entry.key, entry.value]),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Pass Count Chart
              ],
            );
          },
        ),
      );

      // Layout and print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      // Hide Snackbar when task completes
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      // Hide Snackbar on error and show an error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Error generating PDF: $e'),
        ),
      );
    }
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildDropdown(
          'Batch',
          [
            '2020-2024',
            '2021-2025',
            '2019-2023',
            '2018-2022',
            '2022-2026',
            '2023-2027',
            '2024-2028',
            '2025-2029',
            '2026-2030'
          ],
          _selectedBatch,
          (String? newValue) {
            setState(() {
              _selectedBatch = newValue!;
            });
          },
        ),
        SizedBox(
          width: 30,
        ),
        _buildDropdown(
          'Dept',
          [
            'IT',
            'CSE',
            'ECE',
            'EEE',
            'AIML',
          ],
          _selectedDept,
          (String? newValue) {
            setState(() {
              _selectedDept = newValue!;
            });
          },
        ),
        SizedBox(
          width: 30,
        ),
        _buildDropdown(
          'Semester',
          ['sem1', 'sem2', 'sem3', 'sem4', 'sem5', 'sem6', 'sem7', 'sem8'],
          _selectedSem,
          (String? newValue) {
            setState(() {
              _selectedSem = newValue!;
            });
          },
        ),
        SizedBox(
          width: 100,
        ),
        _buildDropdown(
          'Exam',
          ['CAT1', 'CAT2', 'Modal', 'University'],
          _selectedExam,
          (String? newValue) {
            setState(() {
              _selectedExam = newValue!;
            });
          },
        ),
        Container(
          height: 100,
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: DropdownButtonFormField<String>(
            value: _selectedClass,
            items: [
              DropdownMenuItem(value: 'A', child: Text('Class A')),
              DropdownMenuItem(value: 'B', child: Text('Class B')),
              DropdownMenuItem(value: 'C', child: Text('Class C')),
              DropdownMenuItem(value: 'D', child: Text('Class D')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClass = value!;
              });
            },
            decoration: InputDecoration(
              labelText: 'Class',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChartGrid() {
    final charts = subjectData.entries.toList();
    _chartKeys.clear(); // Clear the list before adding new keys

    // Determine how many charts to show based on selected exam
    int chartsToShow;
    if (_selectedExam == 'University') {
      chartsToShow = 6; // Show 9 charts for 'University'
    } else {
      chartsToShow = 6; // Show 6 charts for other exams
    }

    // Ensure that we do not try to display more charts than available
    chartsToShow = chartsToShow > charts.length ? charts.length : chartsToShow;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of charts per row based on screen width
        int chartsPerRow;
        if (constraints.maxWidth < 00) {
          chartsPerRow = 1; // Mobile screen size
        } else {
          chartsPerRow = 3; // Larger screen sizes
        }

        const double spacing = 8.0; // Space between charts

        List<Widget> chartRows = [];
        for (int i = 0; i < chartsToShow; i += chartsPerRow) {
          List<Widget> rowCharts = [];
          for (int j = i; j < i + chartsPerRow && j < chartsToShow; j++) {
            rowCharts.add(
              Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: _buildChart(charts[j].key, charts[j].value),
              ),
            );
          }
          chartRows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowCharts,
            ),
          );
        }

        return Column(
          children: chartRows,
        );
      },
    );
  }

  Widget _buildChart(String subject, List<_ChartData> data) {
    final chartKey = GlobalKey();
    _chartKeys.add(chartKey); // Add the key to the list for later use

    // Define a list of colors for the bars
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.indigo,
    ];

    return RepaintBoundary(
      key: chartKey,
      child: Container(
        height: 450,
        width: 550, // Increase width for more space
        decoration: BoxDecoration(color: Colors.white),
        child: SfCartesianChart(
          primaryXAxis: CategoryAxis(
            labelStyle: TextStyle(
                fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
            title: AxisTitle(
                text: 'Grades',
                textStyle:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // Rotate labels if necessary
            majorGridLines: MajorGridLines(width: 0), // Hide grid lines
            edgeLabelPlacement:
                EdgeLabelPlacement.shift, // Shift labels if overlapping
          ),
          primaryYAxis: NumericAxis(
            labelStyle: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            maximum: 60,
            interval: 5,
            title: AxisTitle(
                text: 'Number of Students', textStyle: TextStyle(fontSize: 25)),
            majorGridLines: MajorGridLines(width: 0), // Hide grid lines
          ),
          title: ChartTitle(
              text: subject,
              textStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          series: <ColumnSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
              animationDuration: 0,
              dataSource: data,
              xValueMapper: (_ChartData sales, _) => sales.grade,
              yValueMapper: (_ChartData sales, _) => sales.count,
              color: Colors.blue, // Use a single color
              dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              width: 0.6, // Adjust width to make bars thicker
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTable() {
    return Center(
      child: Container(
        height: 450,
        width: 550,
        padding: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: summaryData.entries.map((entry) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(entry.value),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.grey,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.grade, this.count);

  final String grade;
  final double count;
}
