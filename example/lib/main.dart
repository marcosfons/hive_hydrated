import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:hive_hydrated/hive_hydrated.dart';
import 'package:path_provider/path_provider.dart';

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

  static Future<String> getPath() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  final HiveHydratedSubject<int> _controller = HiveHydratedSubject<int>(
    boxName: 'teste',
    firstValue: 80,
    // seedValue: 3,
    hivePathAsync: getPath
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
      body: Container(
        child: Center(
          child: StreamBuilder<int>(
            stream: _controller.stream,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              print(snapshot.data);
              if(snapshot.hasData)
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Slider(
                      min: 0,
                      max: 100,
                      label: snapshot.data.toString(),
                      value: snapshot.data.toDouble(),
                      onChanged: (v) =>_controller.add(v.toInt()),
                    ),
                    Container(height: 10,),
                    Text(snapshot.data.toString())
                  ],
                );
                // return Text('O valor é: ${snapshot.data}');
              else if(snapshot.hasError)
                return Text('Ocorreu um erro!');
              return CircularProgressIndicator();
            }
          ),
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
