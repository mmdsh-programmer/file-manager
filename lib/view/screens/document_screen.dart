import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentPage extends StatefulWidget {
  final String documentType;

  DocumentPage({required this.documentType});

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    List<FileSystemEntity> files = await _getFiles();
    setState(() {
      _files = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentType),
      ),
      body: _files.isEmpty
          ? Center(child: Text('No files found'))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_files[index].path.split('/').last),
                );
              },
            ),
    );
  }
}

Future<bool> _requestPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

Future<List<FileSystemEntity>> _getFiles() async {
  // Request permission
  bool permissionGranted = await _requestPermission();
  if (!permissionGranted) return [];

  // Get the external storage directories
  List<Directory>? directories = await getExternalStorageDirectories();
  if (directories == null || directories.isEmpty) return [];

  // Log the directories being accessed
  for (Directory directory in directories) {
    print('Accessing directory: ${directory.path}');
  }

  // Recursively list all files
  List<FileSystemEntity> files = [];
  for (Directory directory in directories) {
    await _listFiles(directory, files);
  }

  return files;
}

Future<void> _listFiles(
    Directory directory, List<FileSystemEntity> files) async {
  await for (FileSystemEntity entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      files.add(entity);
      print('Found file: ${entity.path}'); // Log the file path
    }
  }
}
