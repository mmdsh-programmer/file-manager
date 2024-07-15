import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_manager/file_manager.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../../controller/files_controller.dart';
import '../widgets/widgets.dart';

class DocumentPage extends StatefulWidget {
  final String documentType;

  DocumentPage({required this.documentType});

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  List<FileSystemEntity> _files = [];
  late final FilesController myController;
  String searchQuery = '';
  var isSearching = false;
  late FileSystemEntity selectedFile;

  @override
  void initState() {
    super.initState();
    myController = FilesController();
    _fetchFiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchFiles() async {
    List<FileSystemEntity> files = await _getFiles();
    setState(() {
      _files = _filterFilesByType(files, widget.documentType);
    });
  }

  List<FileSystemEntity> _filterFilesByType(
      List<FileSystemEntity> files, String documentType) {
    List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    List<String> videoExtensions = ['mp4', 'avi', 'mkv'];
    List<String> audioExtensions = ['mp3', 'wav'];
    List<String> textExtensions = ['txt', 'json', 'xml'];

    return files.where((file) {
      if (file is File) {
        String extension = file.path.split('.').last.toLowerCase();
        switch (documentType) {
          case 'image':
            return imageExtensions.contains(extension);
          case 'video':
            return videoExtensions.contains(extension);
          case 'audio':
            return audioExtensions.contains(extension);
          case 'pdf':
            return extension == 'pdf';
          case 'text':
            return textExtensions.contains(extension);
          default:
            return !imageExtensions.contains(extension) &&
                !videoExtensions.contains(extension) &&
                !audioExtensions.contains(extension) &&
                extension != 'pdf' &&
                !textExtensions.contains(extension);
        }
      }
      return false;
    }).toList();
  }

  String _renderPageTitle(String title) {
    switch (title) {
      case "image":
        return "فایل های تصویری";
      case "video":
        return "فایل های ویدیویی";
      case "audio":
        return "فایل های صوتی";
      case "pdf":
        return "فایل های pdf";
      case "text":
        return "فایل های متنی";
      default:
        return "سایر فایل ها";
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _files.where((file) {
      final filename = FileManager.basename(file, showFileExtension: false);
      return filename.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_renderPageTitle(widget.documentType)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: _files.isEmpty
          ? const Center(child: Text('فایلی یافت نشد'))
          : FileManager(
              controller: myController.controller,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SizedBox(
                          height: 7.5.h,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                isSearching = true;
                                searchQuery = value;
                                if (searchQuery.isEmpty ||
                                    searchQuery == "" ||
                                    searchQuery == " ") {
                                  isSearching = false;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.grey[200],
                              hintText: 'جست و جو فایل ها',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 0),
                          itemCount: isSearching
                              ? filteredFiles.length
                              : _files.length,
                          itemBuilder: (context, index) {
                            FileSystemEntity entity = isSearching
                                ? filteredFiles[index]
                                : _files[index];

                            return Ink(
                              color: Colors.transparent,
                              child: ListTile(
                                trailing: PopupMenuButton(
                                    itemBuilder: (BuildContext context) {
                                      return <PopupMenuEntry>[
                                        const PopupMenuItem(
                                          value: 'button1',
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Colors.orange),
                                              Text("حذف"),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'button2',
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Icon(Icons.rotate_left_sharp,
                                                  color: Colors.yellow),
                                              Text("ویرایش نام"),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'button1':
                                          if (entity is Directory) {
                                            await entity
                                                .delete(recursive: true)
                                                .then((value) {
                                              setState(() {
                                                _files.remove(entity);
                                              });
                                            });
                                          } else {
                                            await entity.delete().then((value) {
                                              setState(() {
                                                _files.remove(entity);
                                              });
                                            });
                                          }
                                          break;
                                        case 'button2':
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              TextEditingController
                                                  renameController =
                                                  TextEditingController();
                                              return AlertDialog(
                                                title: Text(
                                                    "ویرایش ${FileManager.basename(entity)}"),
                                                content: TextField(
                                                  controller: renameController,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text("انصراف"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      String newName =
                                                          renameController.text
                                                              .trim();
                                                      String newPath = entity
                                                              .parent.path +
                                                          Platform
                                                              .pathSeparator +
                                                          newName;
                                                      await entity
                                                          .rename(newPath)
                                                          .then((value) {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          _files[index] =
                                                              File(newPath);
                                                        });
                                                      });
                                                    },
                                                    child: const Text("تایید"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          break;
                                      }
                                    },
                                    child: const Icon(Icons.more_vert)),
                                leading: entity is File
                                    ? Card(
                                        color: Colors.transparent,
                                        elevation: 0,
                                        child:
                                            Image.asset("assets/3d/file.png"),
                                      )
                                    : Card(
                                        color: Colors.transparent,
                                        elevation: 0,
                                        child:
                                            Image.asset("assets/3d/folder.png"),
                                      ),
                                title: Text(
                                  FileManager.basename(
                                    entity,
                                    showFileExtension: false,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: subtitle(
                                  entity,
                                ),
                                onTap: () async {
                                  if (entity is Directory) {
                                    try {
                                      myController.controller
                                          .openDirectory(entity);
                                    } catch (e) {
                                      myController.alert(context,
                                          "توانایی باز کردن این پوشه نیست");
                                    }
                                  } else {
                                    previewFile(entity);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void previewFile(FileSystemEntity entity) {
    if (entity is File) {
      String filePath = entity.path;
      String fileExtension = filePath.split('.').last;

      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        // Preview Image
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewScreen(filePath: filePath),
            ));
      } else if (fileExtension == 'pdf') {
        // Preview PDF
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFPreviewScreen(filePath: filePath),
            ));
      } else if (['mp4', 'avi', 'mkv'].contains(fileExtension)) {
        // Preview Video
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(filePath: filePath),
            ));
      } else if (['mp3', 'wav'].contains(fileExtension)) {
        // Preview Audio
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioPreviewScreen(filePath: filePath),
            ));
      } else if (['txt', 'json', 'xml'].contains(fileExtension)) {
        // Preview Text
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextPreviewScreen(filePath: filePath),
            ));
      } else {
        // Unsupported file type
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('نوع فایل پشتیبانی نمیشود')),
        );
      }
    }
  }
}

Future<bool> _requestPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.manageExternalStorage.request();
    status = await Permission.storage.request();
    status = await Permission.mediaLibrary.request();
  }
  return status.isGranted;
}

Future<List<FileSystemEntity>> _getFiles() async {
  bool permissionGranted = await _requestPermission();
  if (!permissionGranted) return [];

  Directory directory = Directory('/storage/emulated/0');
  if (!await directory.exists()) return [];

  print('Accessing directory: ${directory.path}');

  List<FileSystemEntity> files = [];
  await _listFiles(directory, files);

  return files;
}

Future<void> _listFiles(
    Directory directory, List<FileSystemEntity> files) async {
  await for (FileSystemEntity entity
      in directory.list(recursive: true, followLinks: false)) {
    try {
      if (entity is File) {
        files.add(entity);
        print('Found file: ${entity.path}');
      }
    } catch (e) {
      print('Failed to access ${entity.path}: $e');
    }
  }
}
