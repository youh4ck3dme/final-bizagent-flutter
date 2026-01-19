import 'package:flutter/material.dart';
import 'dart:io';

ImageProvider getPlatformSpecificImage(String path) {
  if (path.startsWith('http')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}
