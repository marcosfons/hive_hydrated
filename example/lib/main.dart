import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:hive_hydrated/hive_hydrated.dart';

void _setTargetPlatformForDesktop() {
  // No need to handle macOS, as it has now been added to TargetPlatform.
  if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _setTargetPlatformForDesktop();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Hydrated Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  @override
  _ExamplePageState createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {

  final HiveHydratedSubject<int> _controller = HiveHydratedSubject<int>(
    boxName: 'teste',
    seedValue: 0,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste Hive Hydrated'),
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: _controller.stream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if(snapshot.hasData)
              return Text('O valor é: ${snapshot.data}');
            else if(snapshot.hasError)
              return Text('Ocorreu um erro!');
            return CircularProgressIndicator();
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _controller.add(_controller.value + 1);
        },
      ),
    );
  }
}
