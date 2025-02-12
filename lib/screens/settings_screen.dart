import 'package:flutter/material.dart';
import 'admin/populate_data_screen.dart';
import '../utils/mock_data_generator.dart';

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
          ListTile(
            title: const Text('Generate Mock Carousel Data'),
            subtitle: const Text('Populate Firebase with sample carousel items'),
            trailing: const Icon(Icons.data_array),
            onTap: () async {
              try {
                final generator = MockDataGenerator();
                await generator.clearExistingCarouselData();
                await generator.generateMockCarouselData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mock carousel data generated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating mock data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
