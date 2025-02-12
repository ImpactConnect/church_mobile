import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  final String title;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder(
        future: _loadEventDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'YOUR_IMAGE_URL', // Replace with actual image URL
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Event Details
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                
                // Date and Time
                _buildInfoRow(Icons.calendar_today, 'Date: February 15-17, 2024'),
                _buildInfoRow(Icons.access_time, 'Time: 9:00 AM - 5:00 PM'),
                _buildInfoRow(Icons.location_on, 'Venue: Church Main Hall'),
                
                const SizedBox(height: 20),
                
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join us for three days of worship, fellowship, and spiritual growth. '
                  'This youth conference features dynamic speakers, worship sessions, '
                  'workshops, and activities designed to strengthen your faith and '
                  'build lasting relationships.',
                ),
                
                const SizedBox(height: 20),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add registration logic
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Register Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _loadEventDetails() async {
    // Add logic to load event details from Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay
  }
}
