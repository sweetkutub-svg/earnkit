import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnkit Terms & Conditions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: [Add date before public launch]',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 20),
            _Section(
              title: '1. Eligibility',
              body:
                  'You must be at least 18 years old to create an account and use Earnkit. By signing up, you confirm that the information you provide is accurate.',
            ),
            _Section(
              title: '2. How Earning Works',
              body:
                  'You earn EarnGrow Points by watching rewarded ads and completing offerwall tasks. Points convert to real ₹ at a rate set by Earnkit and shown on the Withdrawal screen. Reward rates may be adjusted based on actual ad/offerwall revenue.',
            ),
            _Section(
              title: '3. Withdrawals',
              body:
                  'Withdrawals are only available once your balance crosses the minimum threshold shown in the app. Withdrawal requests are processed via UPI and may take time to reflect depending on the payment gateway.',
            ),
            _Section(
              title: '4. Fraud & Abuse',
              body:
                  'Any attempt to manipulate earnings through fake ad views, emulators, rooted devices, multiple accounts on one device, or automated tools will result in account suspension and forfeiture of balance.',
            ),
            _Section(
              title: '5. No Gambling Mechanics',
              body:
                  'Earnkit does not use random-chance reward mechanics (e.g. spin wheels, lottery draws). All rewards are earned through verified activity only.',
            ),
            _Section(
              title: '6. Changes to Terms',
              body:
                  'We may update these terms from time to time. Continued use of the app after changes means you accept the updated terms.',
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