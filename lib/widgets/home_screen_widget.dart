import 'dart:developer';
import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/services/encryption_service.dart';
import 'package:data_increptor/widgets/file_list_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class StorageOverview extends StatelessWidget {
  const StorageOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    const totalStorage = 120 * 1024 * 1024 * 1024; // 120 GB in bytes
    final usedStorage =
        fileProvider.files.fold(0, (sum, file) => sum + file.size);
    // log(usedStorage.toString());

    return const Column(
      children: [
        // CircularProgressIndicator(
        //   value: usedStorage / totalStorage,
        //   backgroundColor: Colors.grey[300],
        //   valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        // ),
        // const SizedBox(height: 10),
        // Text(
        //   '${(usedStorage / 1024 / 1024 / 1024).toStringAsFixed(2)} GB of ${totalStorage / 1024 / 1024 / 1024} GB used',
        //   style: const TextStyle(fontSize: 16),
        // ),
      ],
    );
  }
}

class RecentFiles extends StatelessWidget {
  const RecentFiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final folderProvider = Provider.of<FolderProvider>(context);
    final recentFiles = fileProvider.files
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recent Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorsMaterial.allColour,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentFiles.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final file = recentFiles[index];
            return ItemListTileWidget(file: file,);
          },
        ),
      ],
    );
  }

  void _handleFileAction(String action, EncryptedFile file,
      BuildContext context, FolderProvider folderProvider) {
    switch (action) {
      case 'move':
        _showMoveFolderDialog(context, file, folderProvider);
        break;
      case 'share':
        FileEncryptionService.decryptAndShare(file, context);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context, file);
        break;
    }
  }

  void _showMoveFolderDialog(
      BuildContext context, EncryptedFile file, FolderProvider folderProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Move ${file.originalName} to Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: folderProvider.folders.map((folder) {
                return ListTile(
                  leading:
                      Icon(Icons.folder, color: ColorsMaterial.folderColour),
                  title: Text(folder.name),
                  onTap: () {
                    _moveFileToFolder(file, folder.path, context);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _moveFileToFolder(
      EncryptedFile file, String newPath, BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    file.folderPath = newPath;
    fileProvider.updateFile(file);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File moved successfully')),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, EncryptedFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete File'),
          content:
              Text('Are you sure you want to delete ${file.originalName}?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteFile(file, context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteFile(EncryptedFile file, BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.deleteFile(file.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File deleted successfully')),
    );
  }
}
