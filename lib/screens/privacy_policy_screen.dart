import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnkit Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: [Add date before public launch]',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 20),
            _Section(
              title: '1. Information We Collect',
              body:
                  'We collect your name, email address, and a device identifier (used for fraud prevention). If you sign in with Google, we receive your name and email from Google. We collect your UPI ID only when you request a withdrawal.',
            ),
            _Section(
              title: '2. How We Use Your Information',
              body:
                  'Your data is used to manage your account, credit rewards, process withdrawals, prevent fraud (e.g. detecting multiple accounts on one device), and send you important notifications about your account.',
            ),
            _Section(
              title: '3. Data Sharing',
              body:
                  'We do not sell your personal data. We share limited data with our ad network (AdMob), offerwall partners, and payment gateway (Razorpay/Cashfree) only as needed to process ads, tasks, and payouts.',
            ),
            _Section(
              title: '4. Data Security',
              body:
                  'Your data is stored on Firebase (Google Cloud), which encrypts data at rest. We do not store sensitive documents like ID proofs.',
            ),
            _Section(
              title: '5. Your Rights',
              body:
                  'You may request deletion of your account and associated data at any time by contacting support, in accordance with applicable data protection laws (including India\'s DPDP Act).',
            ),
            _Section(
              title: '6. Contact',
              body:
                  'For any privacy-related questions, contact us at codewithkutub@gmail.com.',
            ),
            SizedBox(height: 24),
            Text(
              'This is placeholder text for development. Replace with a lawyer-reviewed version before public launch.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}