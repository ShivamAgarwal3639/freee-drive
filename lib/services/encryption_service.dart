import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

class FileEncryptionService {
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const int maxChunkSize = 10 * 1024 * 1024; // 10 MB per encrypted image

  static Future<void> encryptAndUpload(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String? selectedFormat = await _showFormatSelectionDialog(context);
      if (selectedFormat != null) {
        showLoadingOverlay(context, 'Encrypting file...');
        try {
          await _encryptFile(file, context, selectedFormat);
        } finally {
          hideLoadingOverlay(context);
        }
      }
    }
  }

  static Future<String?> _showFormatSelectionDialog(
      BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Encryption Format'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'png');
              },
              child: const Text('PNG Image'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'txt');
              },
              child: const Text('Text File'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _encryptFile(
      File file, BuildContext context, String format) async {
    int fileSize = await file.length();
    if (fileSize > maxFileSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size exceeds 50 MB limit')),
      );
      return;
    }

    Uint8List fileBytes = await file.readAsBytes();

    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    List<String> encryptedFilePaths = [];
    List<int> chunkSizes = [];

    for (int i = 0; i < fileBytes.length; i += maxChunkSize) {
      int end = (i + maxChunkSize < fileBytes.length)
          ? i + maxChunkSize
          : fileBytes.length;
      Uint8List chunk = fileBytes.sublist(i, end);

      final encrypted = encrypter.encryptBytes(chunk, iv: iv);
      final dataToStore = json.encode({
        'encrypted': base64Encode(encrypted.bytes),
        'key': base64Encode(key.bytes),
        'iv': base64Encode(iv.bytes),
        'chunkIndex': i ~/ maxChunkSize,
        'originalName': file.path.split('/').last,
      });

      String filePath;
      if (format == 'png') {
        img.Image image = _stringToImage(dataToStore);
        List<int> pngBytes = img.encodePng(image);
        filePath = await _saveEncryptedFile(pngBytes, 'png');
      } else {
        filePath = await _saveEncryptedFile(utf8.encode(dataToStore), 'txt');
      }

      encryptedFilePaths.add(filePath);
      chunkSizes.add(chunk.length);
    }

    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final newFile = EncryptedFile(
      id: Uuid().v4(),
      originalName: file.path.split('/').last,
      encryptedName:
      encryptedFilePaths.map((path) => path.split('/').last).join(','),
      originalType: lookupMimeType(file.path) ?? 'application/octet-stream',
      size: fileSize,
      dateEncrypted: DateTime.now(),
      lastAccessed: DateTime.now(),
      folderPath: '/Documents',
      encryptionFormat: format,
      chunkSizes: chunkSizes,
    );

    await fileProvider.addFile(newFile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File encrypted and uploaded successfully')),
    );
  }

  static Future<String> _saveEncryptedFile(
      List<int> bytes, String extension) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String fileName = '${Uuid().v4()}.$extension';
    String filePath = '${appDir.path}/$fileName';
    File file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  static img.Image _stringToImage(String data) {
    List<int> bytes = utf8.encode(data);
    int width = sqrt(bytes.length).ceil();
    int height = (bytes.length / width).ceil();
    img.Image image = img.Image(width: width, height: height);

    for (int i = 0; i < bytes.length; i++) {
      int x = i % width;
      int y = i ~/ width;
      image.setPixelRgba(x, y, bytes[i], bytes[i], bytes[i], 255);
    }

    return image;
  }

  static Future<File> decryptFile(
      EncryptedFile encryptedFile, BuildContext context) async {
    showLoadingOverlay(context, 'Decrypting file...');
    try {
      List<String> encryptedFilePaths = encryptedFile.encryptedName.split(',');
      List<Uint8List> decryptedChunks = [];

      for (int i = 0; i < encryptedFilePaths.length; i++) {
        String filePath = encryptedFilePaths[i];
        Directory appDir = await getApplicationDocumentsDirectory();
        File file = File('${appDir.path}/$filePath');

        if (!await file.exists()) {
          throw Exception('Encrypted file not found');
        }

        String data;
        if (encryptedFile.encryptionFormat == 'png') {
          img.Image? image = img.decodePng(await file.readAsBytes());
          if (image == null) {
            throw Exception('Failed to decode image');
          }
          data = _imageToString(image);
        } else {
          data = await file.readAsString();
        }

        Map<String, dynamic> decodedData = json.decode(data);

        final key = encrypt.Key.fromBase64(decodedData['key']);
        final iv = encrypt.IV.fromBase64(decodedData['iv']);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));

        final decrypted = encrypter.decryptBytes(
          encrypt.Encrypted.fromBase64(decodedData['encrypted']),
          iv: iv,
        );

        decryptedChunks.add(Uint8List.fromList(decrypted));
      }

      Uint8List fullDecryptedData =
      Uint8List.fromList(decryptedChunks.expand((chunk) => chunk).toList());

      String decryptedFilePath =
          '${(await getTemporaryDirectory()).path}/${encryptedFile.originalName}';
      File decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(fullDecryptedData);

      return decryptedFile;
    } finally {
      hideLoadingOverlay(context);
    }
  }

  static String _imageToString(img.Image image) {
    List<int> bytes = [];
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        bytes.add(image.getPixel(x, y).r.toInt());
      }
    }
    return utf8.decode(bytes.where((byte) => byte != 0).toList());
  }

  static Future<void> decryptAndShare(
      EncryptedFile file, BuildContext context) async {
    showLoadingOverlay(context, 'Decrypting and preparing to share...');
    try {
      File decryptedFile = await decryptFile(file, context);
      await Share.shareXFiles([XFile(decryptedFile.path)],
          text: 'Sharing decrypted file: ${file.originalName}');

      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      file.lastAccessed = DateTime.now();
      await fileProvider.updateFile(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decrypting file: ${e.toString()}')),
      );
    } finally {
      hideLoadingOverlay(context);
    }
  }

  static void showLoadingOverlay(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: LoadingOverlay(message: message),
        );
      },
    );
  }

  static void hideLoadingOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<List<XFile>> getEncryptedFilePaths(EncryptedFile file) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    return file.encryptedName
        .split(',')
        .map((name) => XFile('${appDir.path}/$name'))
        .toList();
  }
}