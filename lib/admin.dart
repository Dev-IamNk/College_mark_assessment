import 'dart:convert'; // For jsonEncode
import 'dart:io';
import 'package:app2/chart.dart';
import 'package:app2/Home.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // For HTTP requests

class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _selectedClass = 'A'; // Default value
  String _batch = '';
  String _selectedSemester = 'sem1';
  String _selectedExam = 'University';
  String _selectedDept = 'IT';
  List<List<dynamic>> _csvData = [];

  int _getColumnIndex(List<dynamic> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      String header = headers[i].toString().trim().toLowerCase();
      for (String name in possibleNames) {
        if (header == name.toLowerCase()) return i;
      }
    }
    return -1; // Not found
  }

// Updated _extractAbsentStudentsData
  List<List<dynamic>> _extractAbsentStudentsData(List<List<dynamic>> csvData) {
    List<List<dynamic>> absentStudentsData = [];
    absentStudentsData.add(['Register Number', 'Name', 'Absent Subjects']);

    int regCol =
        _getColumnIndex(csvData[0], ['Register No', 'Register Number']);
    int nameCol = _getColumnIndex(csvData[0], ['Name']);
    int sNoCol = _getColumnIndex(csvData[0], ['S. No']); // optional

    for (int i = 1; i < csvData.length; i++) {
      String reg = csvData[i][regCol].toString().trim();
      String name = csvData[i][nameCol].toString().trim();
      List<String> absentSubjects = [];

      for (int j = 0; j < csvData[0].length; j++) {
        if (j == regCol || j == nameCol || j == sNoCol) continue;
        String subject = csvData[0][j].toString().trim();
        String grade = csvData[i][j].toString().trim().toUpperCase();
        if (grade == 'AB') absentSubjects.add(subject);
      }

      if (absentSubjects.isNotEmpty) {
        absentStudentsData.add([reg, name, absentSubjects.join(', ')]);
      }
    }

    return absentStudentsData;
  }

// Updated _extractFailedStudentsData
  List<List<dynamic>> _extractFailedStudentsData(List<List<dynamic>> csvData) {
    List<List<dynamic>> failedStudentsData = [];
    failedStudentsData
        .add(['Register Number', 'Name', 'Failed Subjects', 'Grades']);

    int regCol = _getColumnIndex(csvData[0],
        ['Register No', 'Register Number', 'Register Num', 'Reg No']);
    int nameCol =
        _getColumnIndex(csvData[0], ['Name', 'Student Name', 'Full Name']);
    int sNoCol = _getColumnIndex(csvData[0], ['S.No', 'Serial No', 'SerialNo']);

    for (int i = 1; i < csvData.length; i++) {
      String reg = csvData[i][regCol].toString().trim();
      String name = csvData[i][nameCol].toString().trim();

      List<String> failedSubjects = [];
      List<String> failedGrades = [];

      for (int j = 0; j < csvData[0].length; j++) {
        if (j == regCol || j == nameCol || j == sNoCol) continue;
        String subject = csvData[0][j].toString().trim();
        String grade = csvData[i][j].toString().trim().toUpperCase();
        if (grade == 'F') {
          failedSubjects.add(subject);
          failedGrades.add(grade);
        }
      }

      if (failedSubjects.isNotEmpty) {
        failedStudentsData.add(
            [reg, name, failedSubjects.join(', '), failedGrades.join(', ')]);
      }
    }

    return failedStudentsData;
  }

// Updated _generateStudentGradesCsv
  String _generateStudentGradesCsv(List<List<dynamic>> csvData) {
    List<List<dynamic>> studentGradesData = [];
    studentGradesData.add(['Name', 'Subject', 'Grade']);

    int regCol =
        _getColumnIndex(csvData[0], ['Register No', 'Register Number']);
    int nameCol = _getColumnIndex(csvData[0], ['Name']);
    int sNoCol = _getColumnIndex(csvData[0], ['S. No']); // optional

    for (int i = 1; i < csvData.length; i++) {
      String name = csvData[i][nameCol].toString().trim();

      for (int j = 0; j < csvData[0].length; j++) {
        if (j == regCol || j == nameCol || j == sNoCol) continue;
        String subject = csvData[0][j].toString().trim();
        String grade = csvData[i][j].toString().trim().toUpperCase();
        studentGradesData.add([name, subject, grade]);
      }
    }

    return const ListToCsvConverter().convert(studentGradesData);
  }

  Future<void> _pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      List<List<dynamic>> csvData = [];

      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          var excel = Excel.decodeBytes(result.files.single.bytes!);
          csvData = _excelToCsvData(excel);
        }
      } else {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        csvData = _excelToCsvData(excel);
      }

      if (csvData.isNotEmpty) {
        setState(() {
          _csvData = (_selectedExam == 'University')
              ? csvData
              : _convertMarksToGrades(csvData);
        });

        // Extract failed students' data
        List<List<dynamic>> failedStudentsData =
            _extractFailedStudentsData(_csvData);
        // Extract absent students' data
        List<List<dynamic>> absentStudentsData =
            _extractAbsentStudentsData(_csvData);

        // For debugging: print the absent students data
        for (var row in absentStudentsData) {
          print(row);
        }

        // Convert absent students' data to CSV string if needed
        String absentStudentsCsv =
            const ListToCsvConverter().convert(absentStudentsData);
        print(absentStudentsCsv);
      }
    }
  }

  List<List<dynamic>> _excelToCsvData(Excel excel) {
    List<List<dynamic>> csvData = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        List<dynamic> rowData = [];
        for (var cell in row) {
          rowData.add(cell?.value ?? '');
        }
        csvData.add(rowData);
      }
    }

    return csvData;
  }

  List<List<dynamic>> _convertMarksToGrades(List<List<dynamic>> csvData) {
    for (int i = 1; i < csvData.length; i++) {
      for (int j = 3; j < csvData[i].length; j++) {
        String cellValue = csvData[i][j].toString().trim();
        if (cellValue != 'AB') {
          int score = int.tryParse(cellValue) ?? 0;
          csvData[i][j] = _convertScoreToGrade(score);
        }
      }
    }
    return csvData;
  }

  String _convertScoreToGrade(int score) {
    if (score >= 90 && score <= 100) {
      return 'S';
    } else if (score >= 80 && score < 90) {
      return 'A';
    } else if (score >= 70 && score < 80) {
      return 'B';
    } else if (score >= 60 && score < 70) {
      return 'C';
    } else if (score >= 55 && score < 60) {
      return 'D';
    } else if (score >= 50 && score < 55) {
      return 'E';
    } else {
      return 'F';
    }
  }

  List<Map<String, int>> _calculateGradeCounts(List<List<dynamic>> csvData) {
    List subjects = csvData[0].sublist(3);
    List<Map<String, int>> gradeCounts =
        List.generate(subjects.length, (_) => {});

    for (int i = 1; i < csvData.length; i++) {
      for (int j = 3; j < csvData[i].length; j++) {
        String grade = csvData[i][j].toString().trim();
        gradeCounts[j - 3][grade] = (gradeCounts[j - 3][grade] ?? 0) + 1;
      }
    }

    return gradeCounts;
  }

  String _generateGradeCountCsv(
      List<Map<String, int>> gradeCounts, List subjects) {
    List<String> grades = ['S', 'A', 'B', 'C', 'D', 'E', 'F'];

    List<List<dynamic>> output = [];
    output.add(['Subject', ...grades]);

    for (int i = 0; i < subjects.length; i++) {
      List<dynamic> row = [subjects[i]];
      for (String grade in grades) {
        row.add(gradeCounts[i][grade] ?? 0);
      }
      output.add(row);
    }

    return const ListToCsvConverter().convert(output);
  }

  String _generateStudentSummaryCsv(List<List<dynamic>> csvData) {
    int totalStudents = csvData.length - 1;
    int absentOccurrences = 0; // Total count of 'AB'
    int failedStudents = 0; // Count of students who failed
    int passedStudents = 0; // Count of students who passed

    // Determine column range based on selected exam type
    int startColumn = 3;
    int endColumn = (_selectedExam == 'University')
        ? 11
        : 8; // Adjust end column based on exam type

    // Iterate over each student record
    for (int i = 1; i < csvData.length; i++) {
      bool hasFailed = false;

      // Iterate over each subject for the student
      for (int j = startColumn; j <= endColumn && j < csvData[i].length; j++) {
        String grade = csvData[i][j].toString().trim();

        if (grade == 'AB') {
          absentOccurrences++; // Increment absent occurrences
        } else if (grade == 'F') {
          hasFailed = true; // Mark the student as having failed
        }
      }

      if (hasFailed) {
        failedStudents++; // Increment failed students count
      } else {
        passedStudents++; // Increment passed students count
      }
    }

    int appearedStudents = totalStudents - absentOccurrences;

    List<List<dynamic>> summaryData = [
      ['Total Students', totalStudents],
      ['Students Passed', passedStudents],
      ['Students Failed', failedStudents],
      ['Students Absent', absentOccurrences],
      ['Students Appeared', appearedStudents],
    ];

    return const ListToCsvConverter().convert(summaryData);
  }

  Future<void> _submitData() async {
    if (_batch.isNotEmpty && _csvData.isNotEmpty) {
      // Generate the necessary CSV data
      String gradeCountCsv = _generateGradeCountCsv(
        _calculateGradeCounts(_csvData),
        _csvData[0].sublist(3),
      );

      String summaryContent = _generateStudentSummaryCsv(_csvData);
      String studentGradesCsv = _generateStudentGradesCsv(_csvData);
      String listOfF =
          ListToCsvConverter().convert(_extractFailedStudentsData(_csvData));

      // Extract absent students' data and convert to CSV
      String listOfAbsent =
          ListToCsvConverter().convert(_extractAbsentStudentsData(_csvData));

      // Prepare the headers and body for the request
      Map<String, String> headers = {"Content-Type": "application/json"};
      Map<String, dynamic> body = {
        'batch': _batch,
        'class': _selectedClass, // Include selected class
        'sem': _selectedSemester,
        'exam': _selectedExam,
        'excel': gradeCountCsv,
        'summary': summaryContent,
        'student_grades': studentGradesCsv,
        'ListofF': listOfF,
        'ListofAbsent': listOfAbsent, // Add the absent students CSV list
        'Dept': _selectedDept,
      };

      try {
        // Send the POST request
        final response = await http.post(
          Uri.parse('http://127.0.0.1/dashboard/mvit/upload.php'),
          headers: headers,
          body: jsonEncode(body),
        );

        // Handle the response
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data successfully submitted!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit data.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }

    // Navigate to a different page after submission
    Navigator.push(context, MaterialPageRoute(builder: (c) => Hi()));
  }

  Widget _buildUploadButton(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: _pickExcelFile,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered) ||
                  states.contains(MaterialState.focused) ||
                  states.contains(MaterialState.pressed)) {
                return Colors.indigoAccent;
              }
              return null;
            },
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: _submitData,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered) ||
                  states.contains(MaterialState.focused) ||
                  states.contains(MaterialState.pressed)) {
                return Colors.indigoAccent;
              }
              return null;
            },
          ),
        ),
        child: Text(
          'Submit',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (c) => Hi()));
              },
              icon: Icon(Icons.arrow_forward))
        ],
        backgroundColor: Color.fromRGBO(1, 68, 84, 0.2),
        title: const Text("Grade Analyser Admin"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                  hintText: 'Enter Batch Name',
                ),
                onChanged: (value) {
                  setState(() {
                    _batch = value;
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedSemester,
                items: [
                  DropdownMenuItem(value: 'sem1', child: Text('Semester 1')),
                  DropdownMenuItem(value: 'sem2', child: Text('Semester 2')),
                  DropdownMenuItem(value: 'sem3', child: Text('Semester 3')),
                  DropdownMenuItem(value: 'sem4', child: Text('Semester 4')),
                  DropdownMenuItem(value: 'sem5', child: Text('Semester 5')),
                  DropdownMenuItem(value: 'sem6', child: Text('Semester 6')),
                  DropdownMenuItem(value: 'sem7', child: Text('Semester 7')),
                  DropdownMenuItem(value: 'sem8', child: Text('Semester 8')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Semester',
                ),
              ),
            ),
            Container(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedDept,
                items: [
                  DropdownMenuItem(value: 'IT', child: Text('IT')),
                  DropdownMenuItem(value: 'CSE', child: Text('CSE')),
                  DropdownMenuItem(value: 'ECE', child: Text('ECE')),
                  DropdownMenuItem(value: 'EEE', child: Text('EEE')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDept = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Dept',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedExam,
                items: [
                  DropdownMenuItem(
                      value: 'University', child: Text('University')),
                  DropdownMenuItem(
                      value: 'CAT1', child: Text('CAT 1')),
                  DropdownMenuItem(
                      value: 'CAT2', child: Text('CAT 2')),
                  DropdownMenuItem(value: 'Modal', child: Text('Modal')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedExam = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Exam Type',
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildUploadButton(context, 'Upload Excel File'),
            SizedBox(height: 20),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }
}
