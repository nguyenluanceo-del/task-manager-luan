import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý công việc',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý công việc'),
        ),
        body: const Center(
          child: Text(
            'App đấu thầu đang chạy 🚀',
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
