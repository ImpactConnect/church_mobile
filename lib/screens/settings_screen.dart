import 'package:flutter/material.dart';
import 'admin/populate_data_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            onTap: () {
              // TODO: Implement account settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              // TODO: Implement notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            onTap: () {
              // TODO: Implement theme settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin'),
            subtitle: const Text('Manage app data'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PopulateDataScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              // TODO: Implement about screen
            },
          ),
        ],
      ),
    );
  }
}
