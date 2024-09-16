import 'package:data_increptor/services/encryption_service.dart';
import 'package:data_increptor/widgets/home_screen_widget.dart';
import 'package:data_increptor/pages/search_page.dart';
import 'package:data_increptor/widgets/quick_access_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorphCloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorageOverview(),
              SizedBox(height: 20),
              QuickAccess(),
              SizedBox(height: 20),
              RecentFiles(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => FileEncryptionService.encryptAndUpload(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}