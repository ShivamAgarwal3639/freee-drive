import 'package:data_increptor/model/data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FileProvider with ChangeNotifier {
  final RxSharedPreferences _rxPrefs = RxSharedPreferences.getInstance();
  List<EncryptedFile> _files = [];
  List<EncryptedFile> get files => _files;

  FileProvider() {
    loadFiles();
  }

  Future<void> loadFiles() async {
    final filesJson = await _rxPrefs.getString('files') ?? '{}';
    final filesMap = json.decode(filesJson) as Map<String, dynamic>;
    _files = filesMap.values
        .map((fileJson) => EncryptedFile.fromJson(fileJson))
        .toList();
    notifyListeners();

    _rxPrefs.getStringStream('files').listen((filesJson) {
      if (filesJson != null) {
        final filesMap = json.decode(filesJson) as Map<String, dynamic>;
        _files = filesMap.values
            .map((fileJson) => EncryptedFile.fromJson(fileJson))
            .toList();
        notifyListeners();
      }
    });
  }

  Future<void> addFile(EncryptedFile file) async {
    _files.add(file);
    await _saveFiles();
  }

  Future<void> updateFile(EncryptedFile file) async {
    final index = _files.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _files[index] = file;
      await _saveFiles();
    }
  }

  Future<void> deleteFile(String fileId) async {
    _files.removeWhere((f) => f.id == fileId);
    await _saveFiles();
  }

  Future<void> _saveFiles() async {
    final filesMap = Map.fromIterables(
      _files.map((f) => f.id),
      _files.map((f) => f.toJson()),
    );
    await _rxPrefs.setString('files', json.encode(filesMap));
  }
}

class FolderProvider with ChangeNotifier {
  final RxSharedPreferences _rxPrefs = RxSharedPreferences.getInstance();
  List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  FolderProvider() {
    loadFolders();
  }

  Future<void> loadFolders() async {
    final foldersJson = await _rxPrefs.getString('folders') ?? '{}';
    final foldersMap = json.decode(foldersJson) as Map<String, dynamic>;
    _folders = foldersMap.values
        .map((folderJson) => Folder.fromJson(folderJson))
        .toList();
    notifyListeners();

    _rxPrefs.getStringStream('folders').listen((foldersJson) {
      if (foldersJson != null) {
        final foldersMap = json.decode(foldersJson) as Map<String, dynamic>;
        _folders = foldersMap.values
            .map((folderJson) => Folder.fromJson(folderJson))
            .toList();
        notifyListeners();
      }
    });
  }

  Future<void> addFolder(Folder folder) async {
    _folders.add(folder);
    await _saveFolders();
  }

  Future<void> updateFolder(Folder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      await _saveFolders();
    }
  }

  Future<void> deleteFolder(String folderId) async {
    _folders.removeWhere((f) => f.id == folderId);
    await _saveFolders();
  }

  Future<void> _saveFolders() async {
    final foldersMap = Map.fromIterables(
      _folders.map((f) => f.id),
      _folders.map((f) => f.toJson()),
    );
    await _rxPrefs.setString('folders', json.encode(foldersMap));
  }
}

