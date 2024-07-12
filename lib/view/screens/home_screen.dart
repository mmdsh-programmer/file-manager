import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../controller/files_controller.dart';
import '../../utils/const.dart';
import '../widgets/widgets.dart';
import '../screens/document_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilesController myController = Get.put(FilesController());
  String searchQuery = '';
  var gotPermission = false;
  var isMoving = false;
  var fullScreen = false;
  var isSearching = false;
  late FileSystemEntity selectedFile;

  @override
  void initState() {
    super.initState();
    getPermission();
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
        Visibility(
            visible: isMoving,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  selectedFile.rename(
                      "${myController.controller.getCurrentPath}/${FileManager.basename(selectedFile)}");
                  setState(() {
                    isMoving = false;
                  });
                },
                child: const Row(
                  children: [
                    Text("انتقال به اینجا",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Icon(Icons.paste),
                  ],
                ),
              ),
            )),
        Visibility(
          visible: !isMoving,
          child: PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry>[
                  PopupMenuItem(
                    value: 'button1',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.file_present,
                          color: orage2,
                        ),
                        const Text("فایل جدید"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'button2',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.folder_open, color: orange),
                        const Text("پوشه جدید"),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (value) {
                switch (value) {
                  case 'button1':
                    myController.createFile(
                        context, myController.controller.getCurrentPath);

                    break;
                  case 'button2':
                    myController.createFolder(context);

                    break;
                }
              },
              child: const Icon(Icons.create_new_folder_outlined)),
        ),
        Visibility(
          visible: !isMoving,
          child: IconButton(
            onPressed: () => myController.sort(context),
            icon: const Icon(Icons.sort_rounded),
          ),
        ),
      ],
      title: const Text("مدیریت فایل",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await myController.controller.goToParentDirectory().then((value) {
            if (myController.controller.getCurrentPath ==
                "/storage/emulated/0") {
              fullScreen = false;
              setState(() {});
            }
          });
        },
      ),
    );
  }

  Drawer drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'دسته بندی اسناد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('فایل های تصویری'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'فایل های تصویری'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library),
            title: Text('فایل های ویديویی'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'فایل های ویدیويی'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.audiotrack),
            title: Text('فایل های صوتی'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'فایل های صوتی'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('فایل های PDF'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'فایل های PDF'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.text_snippet),
            title: Text('فایل های متنی'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'فایل های متنی'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.question_mark),
            title: Text('سایر فایل ها'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentPage(documentType: 'سایر فایل ها'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: myController.controller,
      child: Scaffold(
        appBar: appBar(context),
        drawer: drawer(context),
        body: FileManager(
          controller: myController.controller,
          builder: (context, snapshot) {
            myController.calculateSize(snapshot);

            final List<FileSystemEntity> entities = isSearching
                ? snapshot
                    .where((element) => element.path.contains(searchQuery))
                    .toList()
                : snapshot
                    .where((element) =>
                        element.path != '/storage/emulated/0/Android')
                    .toList();
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Visibility(
                      visible: !fullScreen,
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                            child: TextButton(
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      Color.fromRGBO(255, 211, 182, 1))),
                              child: const Row(
                                children: [
                                  Text(
                                    "نمایش دسته بندی ها",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20.h,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                fileTypeWidget(
                                    "اسناد",
                                    "${myController.documentSize.toStringAsFixed(2)} مگابایت",
                                    "assets/3d/file.png",
                                    yellow),
                                fileTypeWidget(
                                    "فیلم ها",
                                    "${myController.videoSize.toStringAsFixed(2)} مگابایت",
                                    "assets/3d/video.png",
                                    orange),
                                fileTypeWidget(
                                    "عکس ها",
                                    "${myController.imageSize.toStringAsFixed(2)} مگایایت",
                                    "assets/3d/image.png",
                                    black),
                                fileTypeWidget(
                                    "موسیقی ها",
                                    "${myController.soundSize.toStringAsFixed(2)} مگابایت",
                                    "assets/3d/music.png",
                                    orange),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text("فایل های اخیر",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                                InkWell(
                                  onTap: () {
                                    fullScreen = true;
                                    setState(() {});
                                  },
                                  child: Text(
                                    "نمایش کلی",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 0),
                      itemCount: entities.length,
                      itemBuilder: (context, index) {
                        FileSystemEntity entity = entities[index];

                        return Ink(
                          color: Colors.transparent,
                          child: ListTile(
                            trailing: PopupMenuButton(
                                itemBuilder: (BuildContext context) {
                                  return <PopupMenuEntry>[
                                    PopupMenuItem(
                                      value: 'button1',
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.delete, color: orange),
                                          const Text("حذف"),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'button2',
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.rotate_left_sharp,
                                              color: yellow),
                                          const Text("ویرایش نام"),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'button3',
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.move_down_rounded,
                                              color: black),
                                          const Text("انتقال"),
                                        ],
                                      ),
                                    )
                                  ];
                                },
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'button1':
                                      if (FileManager.isDirectory(entity)) {
                                        await entity
                                            .delete(recursive: true)
                                            .then((value) {
                                          setState(() {});
                                        });
                                        ;
                                      } else {
                                        await entity.delete().then((value) {
                                          setState(() {});
                                        });
                                        ;
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
                                                  await entity
                                                      .rename(
                                                    "${myController.controller.getCurrentPath}/${renameController.text.trim()}",
                                                  )
                                                      .then((value) {
                                                    Navigator.pop(context);
                                                    setState(() {});
                                                  });
                                                },
                                                child: const Text("تایید"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      break;
                                    case 'button3':
                                      selectedFile = entity;
                                      setState(() {
                                        isMoving = true;
                                      });
                                      break;
                                  }
                                },
                                child: const Icon(Icons.more_vert)),
                            leading: FileManager.isFile(entity)
                                ? Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Image.asset("assets/3d/file.png"),
                                  )
                                : Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Image.asset("assets/3d/folder.png"),
                                  ),
                            title: Text(
                              FileManager.basename(
                                entity,
                                showFileExtension: true,
                              ),
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: subtitle(
                              entity,
                            ),
                            onTap: () async {
                              if (FileManager.isDirectory(entity)) {
                                try {
                                  myController.controller.openDirectory(entity);
                                } catch (e) {
                                  myController.alert(
                                      context, "توانایی باز کردن این پوشه");
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
      ),
    );
  }

  Future<void> getPermission() async {
    final storagePermission = await Permission.storage.request();
    final mediaLocationPermission =
        await Permission.accessMediaLocation.request();
    final manageExternalStoragePermission =
        await Permission.manageExternalStorage.request();

    if (storagePermission.isGranted &&
        mediaLocationPermission.isGranted &&
        manageExternalStoragePermission.isGranted) {
      setState(() {
        gotPermission = true;
      });
    } else {
      setState(() {
        gotPermission = false;
      });
    }
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
