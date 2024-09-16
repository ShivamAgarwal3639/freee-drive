import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/provider/file_provider.dart';
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
  static Future<void> encryptAndUpload(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      await _encryptFile(file, context);
    }
  }

  static Future<void> _encryptFile(File file, BuildContext context) async {
    int fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size exceeds 10 MB limit')),
      );
      return;
    }

    Uint8List fileBytes = await file.readAsBytes();

    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    final dataToStore = json.encode({
      'encrypted': base64Encode(encrypted.bytes),
      'key': base64Encode(key.bytes),
      'iv': base64Encode(iv.bytes),
      'originalName': file.path.split('/').last,
    });

    img.Image image = _stringToImage(dataToStore);
    List<int> pngBytes = img.encodePng(image);

    Directory appDir = await getApplicationDocumentsDirectory();
    String encryptedFileName = '${Uuid().v4()}.png';
    String filePath = '${appDir.path}/$encryptedFileName';
    File imageFile = File(filePath);
    await imageFile.writeAsBytes(pngBytes);

    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final newFile = EncryptedFile(
      id: Uuid().v4(),
      originalName: file.path.split('/').last,
      encryptedName: encryptedFileName,
      originalType: lookupMimeType(file.path) ?? 'application/octet-stream',
      size: fileSize,
      dateEncrypted: DateTime.now(),
      lastAccessed: DateTime.now(),
      folderPath: '/Documents', // Default folder, can be changed later
    );

    await fileProvider.addFile(newFile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File encrypted and uploaded successfully')),
    );
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


  static Future<File> decryptFile(EncryptedFile encryptedFile, BuildContext context) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    File imageFile = File('${appDir.path}/${encryptedFile.encryptedName}');

    if (!await imageFile.exists()) {
      throw Exception('Encrypted file not found');
    }

    img.Image? image = img.decodePng(await imageFile.readAsBytes());
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    String data = _imageToString(image);
    Map<String, dynamic> decodedData = json.decode(data);

    final key = encrypt.Key.fromBase64(decodedData['key']);
    final iv = encrypt.IV.fromBase64(decodedData['iv']);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted.fromBase64(decodedData['encrypted']),
      iv: iv,
    );

    String decryptedFilePath = '${appDir.path}/${encryptedFile.originalName}';
    File decryptedFile = File(decryptedFilePath);
    await decryptedFile.writeAsBytes(decrypted);

    return decryptedFile;
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

  static Future<void> decryptAndShare(EncryptedFile file, BuildContext context) async {
    try {
      File decryptedFile = await decryptFile(file, context);
      await Share.shareXFiles([XFile(decryptedFile.path)], text: 'Sharing decrypted file: ${file.originalName}');

      // Update last accessed time
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      file.lastAccessed = DateTime.now();
      await fileProvider.updateFile(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decrypting file: ${e.toString()}')),
      );
    }
  }
}