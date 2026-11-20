import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../controllers/admin_access_scope.dart';
import 'admin_workspace_screen.dart';
import 'favorites_screen.dart';
import 'personal_library_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final signedIn = auth.status == AuthStatus.signedIn;
    final admin = AdminAccessScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: 'Refresh account access',
              onPressed: admin.isLoading
                  ? null
                  : () => admin.refresh(forceRefresh: true),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              signedIn
                  ? (auth.currentUser?.displayName ??
                        auth.currentUser?.email ??
                        'Account')
                  : 'Guest mode',
            ),
            subtitle: Text(
              signedIn
                  ? (auth.currentUser?.email ?? '')
                  : 'Sign in to use personal features',
            ),
          ),
          if (signedIn)
            _buildSettingsItem(
              icon: Icons.edit,
              title: 'Edit display name',
              onTap: () => _editDisplayName(context),
            ),
          if (signedIn && admin.isLoading)
            const ListTile(title: Text('Checking account access...')),
          if (signedIn && admin.error != null)
            ListTile(
              title: Text(admin.error!),
              trailing: TextButton(
                onPressed: () => admin.refresh(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ),
          if (signedIn && admin.isAdmin)
            _buildSettingsItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin workspace',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminWorkspaceScreen()),
              ),
            ),
          _buildSettingsItem(
            icon: Icons.favorite,
            title: 'Favorites',
            onTap: signedIn
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  }
                : null,
          ),
          _buildSettingsItem(
            icon: Icons.bookmarks_outlined,
            title: 'Bookmarks & Notes',
            onTap: () {
              if (!signedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sign in to view bookmarks and notes.'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalLibraryScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'Preview only · Download unavailable',
            onTap: null,
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
          _buildSettingsItem(
            icon: signedIn ? Icons.logout : Icons.login,
            title: signedIn ? 'Sign out' : 'Sign in',
            onTap: auth.isBusy
                ? null
                : () async {
                    if (!signedIn) {
                      auth.leaveGuest();
                      return;
                    }
                    final error = await auth.signOut();
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final auth = AuthScope.of(context);
    var nameInput = auth.currentUser?.displayName ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: TextFormField(
          initialValue: nameInput,
          autofocus: true,
          onChanged: (value) => nameInput = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, nameInput.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!context.mounted || name == null) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a display name.')));
      return;
    }
    final error = await auth.updateDisplayName(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Display name updated.')));
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Ebook App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.book, size: 50),
      children: [const Text('A simple ebook reader app built with Flutter.')],
    );
  }
}
