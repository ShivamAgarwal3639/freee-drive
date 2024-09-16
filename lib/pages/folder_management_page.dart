import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:uuid/uuid.dart';

class FolderManagementPage extends StatefulWidget {
  @override
  _FolderManagementPageState createState() => _FolderManagementPageState();
}

class _FolderManagementPageState extends State<FolderManagementPage> {
  final _formKey = GlobalKey<FormState>();
  String _newFolderName = '';

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Folders'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'New Folder Name'),
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        folderProvider.addFolder(Folder(
                          id: const Uuid().v4(),
                          name: _newFolderName,
                          path: '/$_newFolderName', // Simple path creation, you might want to make this more sophisticated
                          fileIds: [], // New folders start with an empty list of file IDs
                          dateCreated: DateTime.now(),
                        ));
                        _formKey.currentState!.reset();
                      }
                    },
                    child: const Text('Create Folder'),
                  ),

                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: folderProvider.folders.length,
              itemBuilder: (context, index) {
                final folder = folderProvider.folders[index];
                return ListTile(
                  title: Text(folder.name),
                  subtitle: Text('Created on: ${folder.dateCreated.toString()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      folderProvider.deleteFolder(folder.id);
                    },
                  ),
                  onTap: () {
                    _showMoveFilesDialog(context, folder, fileProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveFilesDialog(BuildContext context, Folder folder, FileProvider fileProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Move Files to ${folder.name}'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fileProvider.files.length,
              itemBuilder: (context, index) {
                final file = fileProvider.files[index];
                return CheckboxListTile(
                  title: Text(file.originalName),
                  value: file.folderPath == folder.name,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        file.folderPath = value ? folder.name : '/';
                        fileProvider.updateFile(file);
                      });
                    }
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}