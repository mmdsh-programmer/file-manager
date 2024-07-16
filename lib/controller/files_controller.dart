import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_info/storage_info.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class FilesController extends GetxController {
  final FileManagerController controller = FileManagerController();

  double deviceAvailableSize = 0;
  double deviceTotalSize = 0;

  var documentSize = 0.0;
  var videoSize = 0.0;
  var imageSize = 0.0;
  var soundSize = 0.0;

  @override
  void onInit() {
    super.onInit();

    _getSpace().then((value) {
      update();
    });
  }

  Future<void> _getSpace() async {
    deviceAvailableSize = await StorageInfo.getStorageFreeSpaceInGB;
    deviceTotalSize = await StorageInfo.getStorageTotalSpaceInGB + 10;
    update();
  }

  Future<void> selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList
                        .map((e) => ListTile(
                              title: Text(
                                FileManager.basename(e),
                              ),
                              onTap: () {
                                controller.openDirectory(e);
                                Navigator.pop(context);
                              },
                            ))
                        .toList()),
              );
            }
            return const Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: const Text("نام"),
                  onTap: () {
                    controller.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("حجم"),
                  onTap: () {
                    controller.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("تاریخ"),
                  onTap: () {
                    controller.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("نوع"),
                  onTap: () {
                    controller.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  createFile(BuildContext context, String path) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController fileName = TextEditingController();
        TextEditingController fileSize = TextEditingController();
        TextEditingController fileExtension = TextEditingController();
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    decoration: const InputDecoration(
                      hintText: "نام فایل",
                    ),
                    controller: fileName,
                  ),
                ),
                ListTile(
                  trailing: const Text("بایت"),
                  title: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "حجم فایل",
                    ),
                    controller: fileSize,
                  ),
                ),
                ListTile(
                  title: TextField(
                    decoration: const InputDecoration(
                      hintText: "پسوند فایل",
                    ),
                    controller: fileExtension,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Directory documentsDir =
                        await getApplicationDocumentsDirectory();

                    String folderPath = path;
                    try {
                      Directory folder = Directory(folderPath);
                      if (!await folder.exists()) {
                        await folder.create(recursive: true);
                      }
                      File file = File(
                          '$folderPath/${fileName.text}.${fileExtension.text}');
                      if (!await file.exists()) {
                        await file.create();
                        RandomAccessFile raf =
                            await file.open(mode: FileMode.write);
                        for (int i = 0; i < int.parse(fileSize.text); i++) {
                          await raf.writeByte(0x00);
                        }

                        await raf.close().then((value) {
                          Navigator.pop(context);
                        });
                      }
                    } catch (e) {
                      alert(context, "مشکل ناشناخته ای رخ داد");
                    }
                  },
                  child: const Text(
                    'ساخت فایل',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
    update();
  }

  createFolder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController folderName = TextEditingController();
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    decoration: const InputDecoration(
                      hintText: "نام پوشه",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    controller: folderName,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (folderName.text.isEmpty || folderName.text == "") {
                      return;
                    }

                    try {
                      await FileManager.createFolder(
                              controller.getCurrentPath, folderName.text)
                          .then((value) {
                        Navigator.pop(context);
                        controller.setCurrentPath =
                            "${controller.getCurrentPath}/${folderName.text}";
                      });
                    } catch (e) {
                      alert(context, "پوشه از قبل وجود دارد");
                    }
                    update();
                  },
                  child: const Text(
                    'ساخت پوشه',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> alert(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(message),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'متوجه شدم',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  calculateSize(List<FileSystemEntity> entities) {
    documentSize = 0;
    videoSize = 0;
    imageSize = 0;
    soundSize = 0;
    for (var i = 0; i < entities.length; i++) {
      if (entities[i].path.contains(".pdf") ||
          entities[i].path.contains(".doc") ||
          entities[i].path.contains(".txt") ||
          entities[i].path.contains(".ppt") ||
          entities[i].path.contains(".docx") ||
          entities[i].path.contains(".pptx") ||
          entities[i].path.contains(".xlsx") ||
          entities[i].path.contains(".xls")) {
        documentSize += entities[i].statSync().size / 1000000;
      }
      if (entities[i].path.contains(".mp4") ||
          entities[i].path.contains(".mkv") ||
          entities[i].path.contains(".avi") ||
          entities[i].path.contains(".flv") ||
          entities[i].path.contains(".wmv") ||
          entities[i].path.contains(".mov") ||
          entities[i].path.contains(".3gp") ||
          entities[i].path.contains(".webm")) {
        videoSize += entities[i].statSync().size / 1000000;
      }
      if (entities[i].path.contains(".jpg") ||
          entities[i].path.contains(".jpeg") ||
          entities[i].path.contains(".png") ||
          entities[i].path.contains(".gif") ||
          entities[i].path.contains(".bmp") ||
          entities[i].path.contains(".webp")) {
        imageSize += (entities[i].statSync().size / 1000000);
      }
      if (entities[i].path.contains(".mp3") ||
          entities[i].path.contains(".wav") ||
          entities[i].path.contains(".aac") ||
          entities[i].path.contains(".ogg") ||
          entities[i].path.contains(".wma") ||
          entities[i].path.contains(".flac") ||
          entities[i].path.contains(".m4a")) {
        soundSize += entities[i].statSync().size / 1000000;
      }
    }

    update();
  }
}

// Image Preview Screen
class ImagePreviewScreen extends StatelessWidget {
  final String filePath;

  const ImagePreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش نمایش فایل تصویری')),
      body: PhotoView(
        imageProvider: FileImage(File(filePath)),
      ),
    );
  }
}

// PDF Preview Screen
class PDFPreviewScreen extends StatelessWidget {
  final String filePath;

  const PDFPreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش نمایش فایل pdf')),
      body: PDFView(filePath: filePath),
    );
  }
}

// Video Preview Screen
class VideoPreviewScreen extends StatefulWidget {
  final String filePath;

  const VideoPreviewScreen({required this.filePath});

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش نمایش فایل ویدیویی')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}

// Audio Preview Screen
class AudioPreviewScreen extends StatefulWidget {
  final String filePath;

  const AudioPreviewScreen({required this.filePath});

  @override
  _AudioPreviewScreenState createState() => _AudioPreviewScreenState();
}

class _AudioPreviewScreenState extends State<AudioPreviewScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setFilePath(widget.filePath).then((_) {
      _audioPlayer.play();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش نمایش فایل صوتی')),
      body: Center(
        child: Text('در حال پخش صدا ...'),
      ),
    );
  }
}

// Text Preview Screen
class TextPreviewScreen extends StatelessWidget {
  final String filePath;

  const TextPreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: File(filePath).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text('پیش نمایش فایل متنی')),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(snapshot.data ?? 'مشکل در نمایش فایل'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text('پیش نمایش فایل متن')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
