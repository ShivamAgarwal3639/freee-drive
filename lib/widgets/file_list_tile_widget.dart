import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/services/encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';


class ItemListTileWidget extends StatefulWidget {
  final EncryptedFile file;
  const ItemListTileWidget({super.key, required this.file});

  @override
  State<ItemListTileWidget> createState() => _ItemListTileWidgetState();
}

class _ItemListTileWidgetState extends State<ItemListTileWidget> {
  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);
    final file = widget.file;
    return Builder(
      builder: (context) {
        return ListTile(
          dense: true,
          leading: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: IconDataClass.getFileColor(file.originalType),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                IconDataClass.getFileIcon(file.originalType),
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            file.originalName.split(".")[0].length <= 12
                ? file.originalName
                : "${file.originalName.split(".")[0].substring(0, 12)}...${file
                .originalName.split(".")[1]}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle:
          Text('${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: ColorsMaterial.allColour),
            onSelected: (value) =>
                _handleFileAction(value, file, context, folderProvider),
            itemBuilder: (BuildContext context) =>
            [
              PopupMenuItem(
                value: 'move',
                child: ListTile(
                  leading: Icon(Icons.folder,
                      color: ColorsMaterial.folderColour),
                  title: const Text('Move to Folder'),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading:
                  Icon(Icons.share, color: ColorsMaterial.allColour),
                  title: const Text('Share'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
          onTap: () {
            Get.to(() => FileDetailsScreen(file: file));
          },
        );
      }
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
        const SnackBar(content: Text('File moved successfully')),
      );
    }

    void _showDeleteConfirmationDialog(BuildContext context, EncryptedFile file) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete File'),
            content:
            Text('Are you sure you want to delete ${file.originalName}?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Delete'),
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
        const SnackBar(content: Text('File deleted successfully')),
      );
    }

}
