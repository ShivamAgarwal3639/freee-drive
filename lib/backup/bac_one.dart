// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;
// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:share_plus/share_plus.dart';
// import 'dart:ui' as ui;
// import 'package:rx_shared_preferences/rx_shared_preferences.dart';
// import 'package:path/path.dart' as path;
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'File Encryption App',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: HomePage(),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   File? _selectedFile;
//   File? _encryptedImageFile;
//   File? _decryptedFile;
//   late RxSharedPreferences _rxPrefs;
//
//   @override
//   void initState() {
//     super.initState();
//     _rxPrefs = RxSharedPreferences.getInstance();
//   }
//
//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.any,
//       allowMultiple: false,
//     );
//
//     if (result != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//       });
//     }
//   }
//
//   Future<void> _encryptAndConvert() async {
//     if (_selectedFile == null) return;
//
//     // Check file size
//     int fileSize = await _selectedFile!.length();
//     if (fileSize > 10 * 1024 * 1024) {
//       // 10 MB
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('File size exceeds 10 MB limit')),
//       );
//       return;
//     }
//
//     // Read file as bytes
//     Uint8List fileBytes = await _selectedFile!.readAsBytes();
//
//     // Encrypt the file
//     final key = encrypt.Key.fromSecureRandom(32);
//     final iv = encrypt.IV.fromSecureRandom(16);
//     final encrypter = encrypt.Encrypter(encrypt.AES(key));
//     final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
//
//     // Prepare data to be stored in the image
//     final dataToStore = json.encode({
//       'encrypted': base64Encode(encrypted.bytes),
//       'key': base64Encode(key.bytes),
//       'iv': base64Encode(iv.bytes),
//       'originalName': path.basename(_selectedFile!.path),
//     });
//
//     // Convert encrypted data to image
//     img.Image image = _stringToImage(dataToStore);
//
//     // Save image
//     List<int> pngBytes = img.encodePng(image);
//     print('Encoded PNG size: ${pngBytes.length} bytes');
//     Directory appDir = await getApplicationDocumentsDirectory();
//     String originalName = path.basenameWithoutExtension(_selectedFile!.path);
//     String filePath = '${appDir.path}/${originalName}en.png';
//     File imageFile = File(filePath);
//     await imageFile.writeAsBytes(pngBytes);
//     print('Saved encrypted image to: $filePath');
//
//     // Save file locations to RxSharedPreferences
//     await _rxPrefs.setString('original_${originalName}', _selectedFile!.path);
//     await _rxPrefs.setString('encrypted_${originalName}', filePath);
//
//     setState(() {
//       _encryptedImageFile = imageFile;
//     });
//
//     // Open share dialog
//     await _shareEncryptedImage();
//   }
//
//   Future<void> _shareEncryptedImage() async {
//     if (_encryptedImageFile != null) {
//       await Share.shareXFiles([XFile(_encryptedImageFile!.path)],
//           text: 'Encrypted Image');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No encrypted image to share')),
//       );
//     }
//   }
//
//   Future<void> _pickAndDecrypt() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['png'],
//       allowMultiple: false,
//     );
//
//     if (result != null) {
//       File file = File(result.files.single.path!);
//       await _decryptAndRestore(file);
//     }
//   }
//
//   Future<void> _decryptAndRestore(File imageFile) async {
//     try {
//       // Read image file
//       Uint8List imageBytes = await imageFile.readAsBytes();
//
//       print('File size: ${imageBytes.length} bytes');
//       if (imageBytes.isEmpty) {
//         throw Exception('The file is empty');
//       }
//
//       print('First 10 bytes: ${imageBytes.take(10).toList()}');
//
//       // Try decoding with img.decodePng
//       img.Image? image = img.decodePng(imageBytes);
//
//       // If img.decodePng fails, try using dart:ui
//       if (image == null) {
//         print('img.decodePng failed, trying dart:ui decoder');
//         image = await _decodeImageWithUi(imageBytes);
//       }
//
//       if (image == null) throw Exception('Failed to decode image');
//
//       // Extract data from image
//       String extractedData = _imageToString(image);
//       print('Extracted data length: ${extractedData.length}');
//       Map<String, dynamic> decodedData = json.decode(extractedData);
//
//       // Decrypt the data
//       final key = encrypt.Key(base64Decode(decodedData['key']));
//       final iv = encrypt.IV(base64Decode(decodedData['iv']));
//       final encrypter = encrypt.Encrypter(encrypt.AES(key));
//       final decrypted = encrypter.decryptBytes(
//         encrypt.Encrypted(base64Decode(decodedData['encrypted'])),
//         iv: iv,
//       );
//
//       // Save decrypted file with original name
//       String originalName = decodedData['originalName'];
//       Directory appDir = await getApplicationDocumentsDirectory();
//       String filePath = '${appDir.path}/$originalName';
//       File decryptedFile = File(filePath);
//       await decryptedFile.writeAsBytes(decrypted);
//
//       // Save decrypted file location to RxSharedPreferences
//       await _rxPrefs.setString('decrypted_${path.basenameWithoutExtension(originalName)}', filePath);
//
//       setState(() {
//         _decryptedFile = decryptedFile;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('File decrypted successfully')),
//       );
//       await Share.shareXFiles([XFile(filePath)], text: 'Decrypted File');
//     } catch (e) {
//       print('Decryption error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to decrypt file: $e')),
//       );
//     }
//   }
//
//   Future<img.Image?> _decodeImageWithUi(Uint8List imageBytes) async {
//     ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
//     ui.FrameInfo fi = await codec.getNextFrame();
//     ui.Image uiImage = fi.image;
//
//     // Convert ui.Image to img.Image
//     img.Image image = img.Image(width: uiImage.width, height: uiImage.height);
//     List<int> pixels = await uiImage
//         .toByteData(format: ui.ImageByteFormat.rawRgba)
//         .then((byteData) => byteData!.buffer.asUint8List());
//
//     for (int y = 0; y < uiImage.height; y++) {
//       for (int x = 0; x < uiImage.width; x++) {
//         int index = (y * uiImage.width + x) * 4;
//         image.setPixelRgba(x, y, pixels[index], pixels[index + 1],
//             pixels[index + 2], pixels[index + 3]);
//       }
//     }
//
//     return image;
//   }
//
//   img.Image _stringToImage(String data) {
//     List<int> bytes = utf8.encode(data);
//     int width = sqrt(bytes.length).ceil();
//     int height = (bytes.length / width).ceil();
//     img.Image image = img.Image(width: width, height: height);
//
//     for (int i = 0; i < bytes.length; i++) {
//       int x = i % width;
//       int y = i ~/ width;
//       image.setPixelRgba(x, y, bytes[i], bytes[i], bytes[i], 255);
//     }
//
//     return image;
//   }
//
//   String _imageToString(img.Image image) {
//     List<int> bytes = [];
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         img.Pixel pixel = image.getPixel(x, y);
//         bytes.add(pixel.r.toInt());
//       }
//     }
//     return utf8.decode(bytes.where((b) => b != 0).toList(),
//         allowMalformed: true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('File Encryption App')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: _pickFile,
//               child: const Text('Select File to Encrypt'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _encryptAndConvert,
//               child: const Text('Encrypt, Convert to Image, and Share'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickAndDecrypt,
//               child: const Text('Select and Decrypt Image'),
//             ),
//             const SizedBox(height: 20),
//             if (_selectedFile != null)
//               Text('Selected file: ${_selectedFile!.path}'),
//             if (_encryptedImageFile != null)
//               Text('Encrypted image: ${_encryptedImageFile!.path}'),
//             if (_decryptedFile != null)
//               Text('Decrypted file: ${_decryptedFile!.path}'),
//           ],
//         ),
//       ),
//     );
//   }
// }