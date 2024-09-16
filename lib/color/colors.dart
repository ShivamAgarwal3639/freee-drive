import 'package:flutter/material.dart';

class ColorsMaterial {
  static Color allColour = const Color(0xff5a85e1);
  static Color folderColour = const Color(0xff5ddfdf);
  static Color imageColour = const Color(0xffde5edb);
  static Color videoColour = const Color(0xffdf5757);
  static Color filesColour = const Color(0xfff78858);
  static Color audioColour = const Color(0xff8b5cde);
  static Color pdfColour = const Color(0xff5ad77c);
}

class IconDataClass {
  static IconData getFileIcon(String fileType) {
    if (fileType.startsWith('image/')) return Icons.image;
    if (fileType.startsWith('video/')) return Icons.video_file;
    if (fileType.startsWith('audio/')) return Icons.audio_file;
    if (fileType == 'application/pdf') return Icons.picture_as_pdf;
    if (fileType.contains('word')) return Icons.description;
    if (fileType.contains('sheet')) return Icons.table_chart;
    if (fileType.contains('presentation')) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  static Color getFileColor(String fileType) {
    if (fileType.startsWith('image/')) return ColorsMaterial.imageColour;
    if (fileType.startsWith('video/')) return ColorsMaterial.videoColour;
    if (fileType.startsWith('audio/')) return ColorsMaterial.audioColour;
    if (fileType == 'application/pdf') return ColorsMaterial.pdfColour;
    if (fileType.contains('word')) return ColorsMaterial.filesColour;
    if (fileType.contains('sheet')) return ColorsMaterial.filesColour;
    if (fileType.contains('presentation')) return ColorsMaterial.filesColour;
    return ColorsMaterial.filesColour;
  }
}
