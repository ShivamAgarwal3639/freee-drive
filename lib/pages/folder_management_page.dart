import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/services/encryption_service.dart';
import 'package:uuid/uuid.dart';

class FolderManagementPage extends StatefulWidget {
  final String initialPath;

  FolderManagementPage({Key? key, this.initialPath = '/'}) : super(key: key);

  @override
  _FolderManagementPageState createState() => _FolderManagementPageState();
}

class _FolderManagementPageState extends State<FolderManagementPage> {
  late String currentPath;
  final _formKey = GlobalKey<FormState>();
  String _newFolderName = '';

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);
    final fileProvider = Provider.of<FileProvider>(context);

    List<Folder> currentFolders = folderProvider.folders
        .where((folder) =>
            folder.path.startsWith(currentPath) &&
            folder.path.split('/').length == currentPath.split('/').length + 1)
        .toList();

    List<EncryptedFile> currentFiles = fileProvider.files
        .where((file) => file.folderPath == currentPath)
        .toList();

    return WillPopScope(
      onWillPop: () async {
        if (currentPath != '/') {
          setState(() {
            currentPath = currentPath.substring(
                0, currentPath.lastIndexOf('/', currentPath.length - 2) + 1);
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Folders'),
          backgroundColor: ColorsMaterial.allColour,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ' path: $currentPath',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                children: [
                  ...currentFolders
                      .map((folder) => _buildFolderItem(folder, context)),
                  ...currentFiles.map((file) => _buildFileItem(file, context)),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateFolderDialog(context),
          backgroundColor: ColorsMaterial.folderColour,
          child: const Icon(Icons.create_new_folder),
        ),
      ),
    );
  }

  Widget _buildFolderItem(Folder folder, BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          currentPath = folder.path;
        });
      },
      child: Card(
        color: ColorsMaterial.folderColour,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 70, color: Colors.white),
            Text(
              folder.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(EncryptedFile file, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => FileDetailsScreen(file: file));
      },
      onLongPress: () {
        _showFileOptionsMenu(context, file);
      },
      child: Card(
        color: IconDataClass.getFileColor(file.originalType),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconDataClass.getFileIcon(file.originalType),
                size: 52, color: Colors.white),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                file.originalName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptionsMenu(BuildContext context, EncryptedFile file) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.folder, color: ColorsMaterial.folderColour),
                title: const Text('Move to Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveFolderDialog(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file, context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: ColorsMaterial.allColour),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareFile(file, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoveFolderDialog(BuildContext context, EncryptedFile file) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Move ${file.originalName} to Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: folderProvider.folders.map((folder) {
                return ListTile(
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

  void _deleteFile(EncryptedFile file, BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.deleteFile(file.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File deleted successfully')),
    );
  }

  void _shareFile(EncryptedFile file, BuildContext context) {
    FileEncryptionService.decryptAndShare(file, context);
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Folder Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a folder name';
                }
                return null;
              },
              onSaved: (value) {
                _newFolderName = value!;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _createFolder(context);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _createFolder(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    folderProvider.addFolder(Folder(
      id: const Uuid().v4(),
      name: _newFolderName,
      path: '$currentPath$_newFolderName/',
      fileIds: [],
      dateCreated: DateTime.now(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Folder created successfully')),
    );
  }
}
