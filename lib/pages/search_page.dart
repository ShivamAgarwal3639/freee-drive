import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/pages/file_detail_screen.dart';
import 'package:data_increptor/model/data_model.dart';
import 'package:data_increptor/provider/file_provider.dart';
import 'package:data_increptor/widgets/file_list_tile_widget.dart';
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
                return ItemListTileWidget(
                  file: file,
                );
              },
            ),
    );
  }
}
