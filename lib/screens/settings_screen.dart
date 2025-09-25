import 'package:flutter/material.dart';
import 'favorites_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            icon: Icons.favorite,
            title: 'Favorites',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.download,
            title: 'Downloads',
            onTap: () {
              // TODO: Navigate to downloads
              print('Navigate to Downloads');
            },
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              // TODO: Show about dialog
              _showAboutDialog(context);
            },
          ),
          _buildSettingsItem(
            icon: Icons.description,
            title: 'Licenses',
            onTap: () {
              // TODO: Show licenses
              showLicensePage(context: context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[600],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Ebook App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.book,
        size: 50,
      ),
      children: [
        const Text('A simple ebook reader app built with Flutter.'),
      ],
    );
  }
}