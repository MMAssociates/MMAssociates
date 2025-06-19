import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Secrets Of Sports App',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Last Updated: [Date]', // TODO: Update this date
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Text(
              '1. Introduction',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Welcome to Secrets Of Sports App. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about our policy, or our practices with regards to your personal information, please contact us at support@example.com.',
            ),
            SizedBox(height: 15),
            Text(
              '2. Information We Collect',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'We collect personal information that you voluntarily provide to us when you register on the App, express an interest in obtaining information about us or our products and services, when you participate in activities on the App or otherwise when you contact us.',
            ),
            SizedBox(height: 10),
            Text(
              'The personal information that we collect depends on the context of your interactions with us and the App, the choices you make and the products and features you use. The personal information we collect may include the following: Name, Email Address, Phone Number, Location Data (if permission granted), etc.',
            ),
            SizedBox(height: 15),
            Text(
              '3. How We Use Your Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'We use personal information collected via our App for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.',
            ),
            // TODO: Add more sections like:
            // - Will Your Information Be Shared With Anyone?
            // - How Long Do We Keep Your Information?
            // - How Do We Keep Your Information Safe?
            // - Do We Collect Information From Minors?
            // - What Are Your Privacy Rights?
            // - Controls for Do-Not-Track Features
            // - Do California Residents Have Specific Privacy Rights?
            // - Do We Make Updates to This Policy?
            // - How Can You Contact Us About This Policy?
            SizedBox(height: 20),
            Text(
              '[... Add your full privacy policy text here ...]'
            ),
          ],
        ),
      ),
    );
  }
}