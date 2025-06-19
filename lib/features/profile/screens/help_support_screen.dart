import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com', // Replace with your support email
      queryParameters: {
        'subject': 'App Support Request',
      },
    );
    if (!await launchUrl(emailLaunchUri)) {
      // TODO: Show an error message to the user if email app can't be launched
      debugPrint('Could not launch email client');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const ExpansionTile(
            title: Text('How do I book a venue?'),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You can book a venue by navigating to the venue details page and clicking on the "Book Now" button. Follow the on-screen instructions to complete your booking.'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How can I cancel a booking?'),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('To cancel a booking, please go to "My Bookings", find the booking you wish to cancel, and look for a cancel option. Cancellation policies may apply.'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I update my profile information?'),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You can update your profile information by navigating to the "My Profile" screen and tapping on "Personal Details".'),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Contact Us',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email Support'),
            subtitle: const Text('support@example.com'), // Replace
            onTap: _launchEmail,
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Call Us (Mon-Fri, 9am-5pm)'),
            subtitle: const Text('+1-234-567-8900'), // Replace
            onTap: () async {
              final Uri phoneLaunchUri = Uri.parse('tel:+1-234-567-8900'); // Replace
               if (!await launchUrl(phoneLaunchUri)) {
                  debugPrint('Could not launch phone dialer');
               }
            },
          ),
          // Add more contact options or links as needed
        ],
      ),
    );
  }
}