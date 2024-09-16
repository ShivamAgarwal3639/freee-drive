import 'dart:developer';
import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:data_increptor/provider/file_provider.dart';
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
  const RecentFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final recentFiles = fileProvider.files
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Files',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentFiles.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final file = recentFiles[index];
            return ListTile(
              leading: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: IconDataClass.getFileColor(file.originalType),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      IconDataClass.getFileIcon(file.originalType),
                      size: 20,
                      color: Colors.white,
                    ),
                  )),
              title: Text(file.originalName.split(".")[0].length <= 12
                  ? file.originalName
                  : "${file.originalName.split(".")[0].substring(0, 12)}...${file.originalName.split(".")[1]}"),
              subtitle:
                  Text('${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                Get.to(() => FileDetailsScreen(
                      file: file,
                    ));
              },
            );
          },
        ),
      ],
    );
  }
}
