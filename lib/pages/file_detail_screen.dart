import 'package:flutter/material.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/services/encryption_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class FileDetailsScreen extends StatelessWidget {
  final EncryptedFile file;

  FileDetailsScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileIcon(),
              const SizedBox(height: 20),
              Text(
                file.originalName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Type', file.originalType),
              _buildInfoRow('Size', '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
              _buildInfoRow('Encrypted on', _formatDate(file.dateEncrypted)),
              _buildInfoRow('Last accessed', _formatDate(file.lastAccessed)),
              _buildInfoRow('Folder', file.folderPath),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (file.originalType.startsWith('image/')) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (file.originalType.startsWith('video/')) {
      iconData = Icons.video_file;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.green;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        size: 60,
        color: iconColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.lock_open),
          label: const Text('Decrypt and Share'),
          onPressed: () => _decryptAndShare(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share Encrypted File'),
          onPressed: () => _shareEncryptedFile(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Delete File', style: TextStyle(color: Colors.red)),
          onPressed: () => _deleteFile(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _shareEncryptedFile(BuildContext context) async {
    FileEncryptionService.showLoadingOverlay(context, 'Preparing encrypted file for sharing...');
    try {
      List<XFile> encryptedFilePaths = await FileEncryptionService.getEncryptedFilePaths(file);
      await Share.shareXFiles(
        encryptedFilePaths,
        text: 'Sharing encrypted file: ${file.originalName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing encrypted file: ${e.toString()}')),
      );
    } finally {
      FileEncryptionService.hideLoadingOverlay(context);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _decryptAndShare(BuildContext context) async {
    try {
      await FileEncryptionService.decryptAndShare(file, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decrypting and sharing file: ${e.toString()}')),
      );
    }
  }

  void _deleteFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: const Text('Are you sure you want to delete this file?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                final fileProvider = Provider.of<FileProvider>(context, listen: false);
                fileProvider.deleteFile(file.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File deleted successfully')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}