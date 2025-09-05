// import 'dart:convert'; // For jsonEncode
// import 'dart:io';
// import 'package:app2/chart.dart';
// import 'package:app2/Home.dart';
// import 'package:flutter/material.dart';
// import 'package:csv/csv.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:excel/excel.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http; // For HTTP requests

// class AdminPage extends StatefulWidget {
//   @override
//   State<AdminPage> createState() => _AdminPageState();
// }

// class _AdminPageState extends State<AdminPage> {
//   String _batch = '';
//   String _selectedSemester = 'sem1';
//   String _selectedExam = 'University';
//   List<List<dynamic>> _csvData = [];

//   List<List<dynamic>> _extractFailedStudentsData(List<List<dynamic>> csvData) {
//     List<List<dynamic>> failedStudentsData = [];

//     // Add header row to the output
//     failedStudentsData.add(['Register Number', 'Name', 'Subject', 'Grade']);

//     // Determine column range based on exam type
//     int endColumn = _selectedExam == 'University' ? 11 : 8;

//     // Iterate over each student record
//     for (int i = 1; i < csvData.length; i++) {
//       String registerNumber = csvData[i][0]
//           .toString()
//           .trim(); // Register number in the first column
//       String studentName =
//           csvData[i][2].toString().trim(); // Name in the second column

//       // Iterate over each subject for the student within the determined column range
//       for (int j = 3; j <= endColumn; j++) {
//         String subject = csvData[0][j]
//             .toString()
//             .trim(); // Subject names are in the first row
//         String grade = csvData[i][j].toString().trim();

//         if (grade == 'F') {
//           failedStudentsData.add([registerNumber, studentName, subject, grade]);
//         }
//       }
//     }

//     return failedStudentsData;
//   }

//   Future<void> _pickExcelFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx', 'xls'],
//     );

//     if (result != null) {
//       List<List<dynamic>> csvData = [];

//       if (kIsWeb) {
//         if (result.files.single.bytes != null) {
//           var excel = Excel.decodeBytes(result.files.single.bytes!);
//           csvData = _excelToCsvData(excel);
//         }
//       } else {
//         File file = File(result.files.single.path!);
//         var bytes = file.readAsBytesSync();
//         var excel = Excel.decodeBytes(bytes);
//         csvData = _excelToCsvData(excel);
//       }

//       if (csvData.isNotEmpty) {
//         setState(() {
//           // Check if the selected exam is "University" to convert scores
//           if (_selectedExam == 'University') {
//             _csvData = _convertUniversityMarksToGrades(csvData);
//             print(_csvData);
//           } else {
//             _csvData = _convertMarksToGrades(csvData);
//           }
//         });

//         List<List<dynamic>> failedStudentsData =
//             _extractFailedStudentsData(_csvData);

//         // For debugging: print the failed students data
//         for (var row in failedStudentsData) {
//           print(row);
//         }

//         // You can also convert the failed students' data to a CSV string if needed
//         String failedStudentsCsv =
//             const ListToCsvConverter().convert(failedStudentsData);
//         print(failedStudentsCsv);
//       }
//     }
//   }

//   List<List<dynamic>> _convertUniversityMarksToGrades(
//       List<List<dynamic>> csvData) {
//     for (int i = 1; i < csvData.length; i++) {
//       for (int j = 3; j < csvData[i].length; j++) {
//         String cellValue = csvData[i][j].toString().trim();
//         if (cellValue != 'AB') {
//           int score = int.tryParse(cellValue) ?? 0;
//           csvData[i][j] = _convertUniversityScoreToGrade(score);
//         }
//       }
//     }
//     return csvData;
//   }

//   String _convertUniversityScoreToGrade(int score) {
//     if (score == 10) {
//       return 'S';
//     } else if (score == 9) {
//       return 'A';
//     } else if (score == 8) {
//       return 'B';
//     } else if (score == 7) {
//       return 'C';
//     } else if (score == 6) {
//       return 'D';
//     } else if (score == 5) {
//       return 'E';
//     } else {
//       return 'F';
//     }
//   }

//   List<List<dynamic>> _excelToCsvData(Excel excel) {
//     List<List<dynamic>> csvData = [];

//     for (var table in excel.tables.keys) {
//       for (var row in excel.tables[table]!.rows) {
//         List<dynamic> rowData = [];
//         for (var cell in row) {
//           rowData.add(cell?.value ?? '');
//         }
//         csvData.add(rowData);
//       }
//     }

//     return csvData;
//   }

//   List<List<dynamic>> _convertMarksToGrades(List<List<dynamic>> csvData) {
//     for (int i = 1; i < csvData.length; i++) {
//       for (int j = 3; j < csvData[i].length; j++) {
//         String cellValue = csvData[i][j].toString().trim();
//         if (cellValue != 'AB') {
//           int score = int.tryParse(cellValue) ?? 0;
//           csvData[i][j] = _convertScoreToGrade(score);
//         }
//       }
//     }
//     return csvData;
//   }

//   String _convertScoreToGrade(int score) {
//     if (score >= 90 && score <= 100) {
//       return 'S';
//     } else if (score >= 80 && score < 90) {
//       return 'A';
//     } else if (score >= 70 && score < 80) {
//       return 'B';
//     } else if (score >= 60 && score < 70) {
//       return 'C';
//     } else if (score >= 55 && score < 60) {
//       return 'D';
//     } else if (score >= 50 && score < 55) {
//       return 'E';
//     } else {
//       return 'F';
//     }
//   }

//   List<Map<String, int>> _calculateGradeCounts(List<List<dynamic>> csvData) {
//     List subjects = csvData[0].sublist(3);
//     List<Map<String, int>> gradeCounts =
//         List.generate(subjects.length, (_) => {});

//     for (int i = 1; i < csvData.length; i++) {
//       for (int j = 3; j < csvData[i].length; j++) {
//         String grade = csvData[i][j].toString().trim();
//         gradeCounts[j - 3][grade] = (gradeCounts[j - 3][grade] ?? 0) + 1;
//       }
//     }

//     return gradeCounts;
//   }

//   String _generateGradeCountCsv(
//       List<Map<String, int>> gradeCounts, List subjects) {
//     List<String> grades = ['S', 'A', 'B', 'C', 'D', 'E', 'F'];

//     List<List<dynamic>> output = [];
//     output.add(['Subject', ...grades]);

//     for (int i = 0; i < subjects.length; i++) {
//       List<dynamic> row = [subjects[i]];
//       for (String grade in grades) {
//         row.add(gradeCounts[i][grade] ?? 0);
//       }
//       output.add(row);
//     }

//     return const ListToCsvConverter().convert(output);
//   }

//   String _generateStudentSummaryCsv(List<List<dynamic>> csvData) {
//     int totalStudents = csvData.length - 1;
//     int absentOccurrences = 0; // Total count of 'AB'
//     int failedStudents = 0; // Count of students who failed
//     int passedStudents = 0; // Count of students who passed

//     // Determine column range based on selected exam type
//     int startColumn = 3;
//     int endColumn = (_selectedExam == 'University')
//         ? 11
//         : 8; // Adjust end column based on exam type

//     // Iterate over each student record
//     for (int i = 1; i < csvData.length; i++) {
//       bool hasFailed = false;

//       // Iterate over each subject for the student
//       for (int j = startColumn; j <= endColumn && j < csvData[i].length; j++) {
//         String grade = csvData[i][j].toString().trim();

//         if (grade == 'AB') {
//           absentOccurrences++; // Increment absent occurrences
//         } else if (grade == 'F') {
//           hasFailed = true; // Mark the student as having failed
//         }
//       }

//       if (hasFailed) {
//         failedStudents++; // Increment failed students count
//       } else {
//         passedStudents++; // Increment passed students count
//       }
//     }

//     int appearedStudents = totalStudents - absentOccurrences;

//     List<List<dynamic>> summaryData = [
//       ['Total Students', totalStudents],
//       ['Students Passed', passedStudents],
//       ['Students Failed', failedStudents],
//       ['Students Absent', absentOccurrences],
//       ['Students Appeared', appearedStudents],
//     ];

//     return const ListToCsvConverter().convert(summaryData);
//   }

//   String _generateStudentGradesCsv(List<List<dynamic>> csvData) {
//     List<List<dynamic>> studentGradesData = [];

//     // Add header row
//     studentGradesData.add(['Name', 'Subject', 'Grade']);

//     // Iterate over each student record
//     for (int i = 1; i < csvData.length; i++) {
//       String studentName = csvData[i][1]
//           .toString()
//           .trim(); // Assuming name is in the second column

//       // Iterate over each subject for the student
//       for (int j = 3; j < csvData[i].length; j++) {
//         String subject = csvData[0][j]
//             .toString()
//             .trim(); // Subject names are in the first row
//         String grade = csvData[i][j].toString().trim();

//         studentGradesData.add([studentName, subject, grade]);
//       }
//     }

//     return const ListToCsvConverter().convert(studentGradesData);
//   }

//   Future<void> _submitData() async {
//     if (_batch.isNotEmpty && _csvData.isNotEmpty) {
//       String gradeCountCsv = _generateGradeCountCsv(
//         _calculateGradeCounts(_csvData),
//         _csvData[0].sublist(3),
//       );

//       String summaryContent = _generateStudentSummaryCsv(_csvData);
//       String studentGradesCsv = _generateStudentGradesCsv(_csvData);
//       String ListofF =
//           ListToCsvConverter().convert(_extractFailedStudentsData(_csvData));

//       Map<String, String> headers = {"Content-Type": "application/json"};
//       Map<String, dynamic> body = {
//         'batch': _batch,
//         'sem': _selectedSemester,
//         'exam': _selectedExam,
//         'excel': gradeCountCsv,
//         'summary': summaryContent, // Including the summary CSV content
//         'student_grades': studentGradesCsv,
//         'ListofF': ListofF,

//         // Including the student grades CSV content
//       };

//       try {
//         final response = await http.post(
//           Uri.parse('http://192.168.56.1/Dashboard/clgProject/upload.php'),
//           headers: headers,
//           body: jsonEncode(body),
//         );

//         if (response.statusCode == 200) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Data successfully submitted!')),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to submit data.')),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('An error occurred: $e')),
//         );
//       }
//     }
//     Navigator.push(context, MaterialPageRoute(builder: (c) => Hi()));
//   }

//   Widget _buildUploadButton(BuildContext context, String text) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 40),
//       child: ElevatedButton(
//         onPressed: _pickExcelFile,
//         style: ButtonStyle(
//           backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
//           overlayColor: MaterialStateProperty.resolveWith<Color?>(
//             (Set<MaterialState> states) {
//               if (states.contains(MaterialState.hovered) ||
//                   states.contains(MaterialState.focused) ||
//                   states.contains(MaterialState.pressed)) {
//                 return Colors.indigoAccent;
//               }
//               return null;
//             },
//           ),
//         ),
//         child: Text(
//           text,
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 40),
//       child: ElevatedButton(
//         onPressed: _submitData,
//         style: ButtonStyle(
//           backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
//           overlayColor: MaterialStateProperty.resolveWith<Color?>(
//             (Set<MaterialState> states) {
//               if (states.contains(MaterialState.hovered) ||
//                   states.contains(MaterialState.focused) ||
//                   states.contains(MaterialState.pressed)) {
//                 return Colors.indigoAccent;
//               }
//               return null;
//             },
//           ),
//         ),
//         child: Text(
//           'Submit',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 255, 255, 255),
//       appBar: AppBar(
//         actions: [
//           IconButton(
//               onPressed: () {
//                 Navigator.push(
//                     context, MaterialPageRoute(builder: (c) => Hi()));
//               },
//               icon: Icon(Icons.arrow_forward))
//         ],
//         backgroundColor: Color.fromRGBO(1, 68, 84, 0.2),
//         title: const Text("Grade Analyser Admin"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//               child: TextField(
//                 decoration: const InputDecoration(
//                   labelText: 'Batch Name',
//                   hintText: 'Enter Batch Name',
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _batch = value;
//                   });
//                 },
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//               child: DropdownButtonFormField<String>(
//                 value: _selectedSemester,
//                 items: [
//                   DropdownMenuItem(value: 'sem1', child: Text('Semester 1')),
//                   DropdownMenuItem(value: 'sem2', child: Text('Semester 2')),
//                   DropdownMenuItem(value: 'sem3', child: Text('Semester 3')),
//                   DropdownMenuItem(value: 'sem4', child: Text('Semester 4')),
//                   DropdownMenuItem(value: 'sem5', child: Text('Semester 5')),
//                   DropdownMenuItem(value: 'sem6', child: Text('Semester 6')),
//                   DropdownMenuItem(value: 'sem7', child: Text('Semester 7')),
//                   DropdownMenuItem(value: 'sem8', child: Text('Semester 8')),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedSemester = value!;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   labelText: 'Semester',
//                 ),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//               child: DropdownButtonFormField<String>(
//                 value: _selectedExam,
//                 items: [
//                   DropdownMenuItem(
//                       value: 'University', child: Text('University')),
//                   DropdownMenuItem(
//                       value: 'Internal1', child: Text('Internal 1')),
//                   DropdownMenuItem(
//                       value: 'Internal2', child: Text('Internal 2')),
//                   DropdownMenuItem(value: 'Modal', child: Text('Modal')),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedExam = value!;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   labelText: 'Exam Type',
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             _buildUploadButton(context, 'Upload Excel File'),
//             SizedBox(height: 20),
//             _buildSubmitButton(context),
//           ],
//         ),
//       ),
//     );
//   }
// }
