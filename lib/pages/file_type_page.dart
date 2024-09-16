import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/widgets/file_list_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';

class ImageFilesPage extends StatelessWidget {
  const ImageFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFileTypePage(
        context, 'Images', (file) => file.originalType.startsWith('image/'));
  }
}

class VideoFilesPage extends StatelessWidget {
  const VideoFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFileTypePage(
        context, 'Videos', (file) => file.originalType.startsWith('video/'));
  }
}

class OtherFilesPage extends StatelessWidget {
  const OtherFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFileTypePage(
        context,
        'Other Files',
        (file) =>
            !file.originalType.startsWith('image/') &&
            !file.originalType.startsWith('file/'));
  }
}

Widget _buildFileTypePage(
    BuildContext context, String title, bool Function(EncryptedFile) filter) {
  final fileProvider = Provider.of<FileProvider>(context);
  final filteredFiles = fileProvider.files.where(filter).toList();

  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: ListView.builder(
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return ItemListTileWidget(file: file,);
      },
    ),
  );
}
