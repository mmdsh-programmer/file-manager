import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../utils/const.dart';

Widget fileTypeWidget(String type, String size, String iconPath, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Container(
            height: 20.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: color == orange ? orange.withOpacity(0.8) : color,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: TextStyle(
                        color: color == yellow ? Colors.black : Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(size,
                      style: TextStyle(
                        color: color == orange
                            ? Colors.black.withOpacity(0.5)
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(iconPath,
                  height: 20.h, width: 30.w, fit: BoxFit.contain),
            ),
          )
        ],
      ),
    ),
  );
}

Widget subtitle(FileSystemEntity entity) {
  return FutureBuilder<FileStat>(
    future: entity.stat(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        if (entity is File) {
          int size = snapshot.data!.size;

          return Text(
            FileManager.formatBytes(size),
          );
        }
        return Text(
          "${snapshot.data!.modified}".substring(0, 10),
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        );
      } else {}
      return const Text("");
    },
  );
}
