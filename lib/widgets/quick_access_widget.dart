import 'package:data_increptor/color/colors.dart';
import 'package:data_increptor/pages/file_type_page.dart';
import 'package:data_increptor/pages/folder_management_page.dart';
import 'package:flutter/material.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickAccessItem(
          context,
          Icons.border_all_rounded,
          'Folders',
          ColorsMaterial.allColour,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => FolderManagementPage())),
        ),
        _buildQuickAccessItem(
          context,
          Icons.image,
          'Images',
          ColorsMaterial.imageColour,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageFilesPage())),
        ),
        _buildQuickAccessItem(
          context,
          Icons.video_collection,
          'Video',
          ColorsMaterial.videoColour,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoFilesPage())),
        ),
        _buildQuickAccessItem(
          context,
          Icons.insert_drive_file,
          'Files',
          ColorsMaterial.filesColour,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OtherFilesPage())),
        ),
      ],
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}