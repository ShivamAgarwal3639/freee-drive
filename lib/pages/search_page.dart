import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  List<EncryptedFile> _searchResults = [];

  void _performSearch(String query) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    setState(() {
      _searchQuery = query;
      _searchResults = fileProvider.files
          .where((file) =>
              file.originalName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('Start typing to search'))
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final file = _searchResults[index];
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
                  subtitle: Text(
                      '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () {
                    Get.to(() => FileDetailsScreen(
                          file: file,
                        ));
                  },
                );
              },
            ),
    );
  }
}
