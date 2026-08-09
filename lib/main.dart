import 'package:flutter/material.dart';
import 'ui/single_switch_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '农场取码代理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const SingleSwitchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
