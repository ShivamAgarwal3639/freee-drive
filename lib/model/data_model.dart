import 'dart:convert';

class EncryptedFile {
  final String id;
  final String originalName;
  final String encryptedName;
  final String originalType;
  final int size;
  final DateTime dateEncrypted;
  DateTime lastAccessed;
  String folderPath;

  EncryptedFile({
    required this.id,
    required this.originalName,
    required this.encryptedName,
    required this.originalType,
    required this.size,
    required this.dateEncrypted,
    required this.lastAccessed,
    required this.folderPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalName': originalName,
    'encryptedName': encryptedName,
    'originalType': originalType,
    'size': size,
    'dateEncrypted': dateEncrypted.toIso8601String(),
    'lastAccessed': lastAccessed.toIso8601String(),
    'folderPath': folderPath,
  };

  factory EncryptedFile.fromJson(Map<String, dynamic> json) => EncryptedFile(
    id: json['id'],
    originalName: json['originalName'],
    encryptedName: json['encryptedName'],
    originalType: json['originalType'],
    size: json['size'],
    dateEncrypted: DateTime.parse(json['dateEncrypted']),
    lastAccessed: DateTime.parse(json['lastAccessed']),
    folderPath: json['folderPath'],
  );
}

class Folder {
  final String id;
  final String name;
  final String path;
  List<String> fileIds;
  final DateTime dateCreated;

  Folder({
    required this.id,
    required this.name,
    required this.path,
    required this.fileIds,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'fileIds': fileIds,
    'dateCreated': dateCreated.toIso8601String(),
  };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    fileIds: List<String>.from(json['fileIds']),
    dateCreated: DateTime.parse(json['dateCreated']),
  );
}