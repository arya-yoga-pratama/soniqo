import 'dart:io';
import 'package:flutter/material.dart';

/// Default cover asset to use when a cover is missing.
const String kDefaultCover = 'assets/poster/Baby.jpg';

/// Helper to get an ImageProvider for both assets and local files.
ImageProvider getImageProvider(String path) {
  if (path.isEmpty) return const AssetImage(kDefaultCover);

  if (path.startsWith('assets/')) {
    return AssetImage(path);
  } else {
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    } else {
      return const AssetImage(kDefaultCover);
    }
  }
}

/// Helper widget to build cover images with automatic asset/file detection.
Widget buildCoverImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (path.isEmpty) {
    return Image.asset(kDefaultCover, width: width, height: height, fit: fit);
  }

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        kDefaultCover,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  } else {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          kDefaultCover,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else {
      return Image.asset(kDefaultCover, width: width, height: height, fit: fit);
    }
  }
}
