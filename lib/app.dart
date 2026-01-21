import 'package:flutter/material.dart';

class InstaDAMApp extends StatelessWidget {
  const InstaDAMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaDAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'InstaDAM',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
