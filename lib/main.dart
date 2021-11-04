import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test images grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Test page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum _DataType {
  files,
  network,
}

class _MyHomePageState extends State<MyHomePage> {
  var _dataPrepared = false;
  var _dataType = _DataType.files;
  final _fileImages = [];

  Future<bool> _prepareData() async {
    if (_dataPrepared) {
      return false;
    }
    _fileImages.clear();

    final appDir = (await getApplicationDocumentsDirectory()).path;
    final dataDir = Directory(path.join(appDir, 'test_data'));

    if (await dataDir.exists()) {
      await dataDir.delete(recursive: true);
    }
    await dataDir.create(recursive: true);

    for (var i = 1; i <= 30; i++) {
      final filename = '$i.jpg';
      final data = await rootBundle.load('assets/data_single/test_img.jpg');
      final file = File(path.join(dataDir.path, filename));
      await file.writeAsBytes(
        data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
      );
      print('Write file: $filename');
    }

    _fileImages.addAll(await dataDir.list().toList());
    _dataPrepared = true;
    return true;
  }

  void _showImages(_DataType dataType) {
    switch (dataType) {
      case _DataType.files:
        for (var file in _fileImages) {
          imageCache?.evict(FileImage(file));
        }
        break;
      case _DataType.network:
        break;
    }

    setState(() {
      _dataType = dataType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<bool>(
          future: _prepareData(),
          builder: (context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.hasData) {
              return _createBody();
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
      floatingActionButton: _createFab(),
    );
  }

  FloatingActionButton? _createFab() {
    switch (_dataType) {
      case _DataType.files:
        return FloatingActionButton.extended(
          icon: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          label: const Text('Show from network'),
          onPressed: () {
            _showImages(_DataType.network);
          },
        );
      case _DataType.network:
        return FloatingActionButton.extended(
          icon: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          label: const Text('Show from files'),
          onPressed: () {
            _showImages(_DataType.files);
          },
        );
    }
  }

  Widget _createBody() {
    switch (_dataType) {
      case _DataType.files:
        return GridView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: _fileImages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (context, index) {
            return Image.file(
              _fileImages[index],
              fit: BoxFit.cover,
            );
          },
        );
      case _DataType.network:
        return GridView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: _fileImages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (context, index) {
            return Image.network(
              'https://picsum.photos/1000/1000?random=$index',
              fit: BoxFit.cover,
            );
          },
        );
    }
  }
}
