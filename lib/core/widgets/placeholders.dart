import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - Coming Soon')),
    );
  }
}

// class ProfilePage extends PlaceholderPage { const ProfilePage({super.key}) : super(title: 'Profile'); }
// class TrendsPage extends PlaceholderPage { const TrendsPage({super.key}) : super(title: 'Trends'); }
// class SettingsPage extends PlaceholderPage { const SettingsPage({super.key}) : super(title: 'Settings'); }
// class HelpPage extends PlaceholderPage { const HelpPage({super.key}) : super(title: 'Help'); }
// class ExpertSessionPage extends PlaceholderPage { const ExpertSessionPage({super.key}) : super(title: 'Expert Session'); }
// class PricingPage extends PlaceholderPage { const PricingPage({super.key}) : super(title: 'Pricing'); }
// class ExplorePage extends PlaceholderPage { const ExplorePage({super.key}) : super(title: 'Explore'); }
// class NotesHistoryPage extends PlaceholderPage { const NotesHistoryPage({super.key}) : super(title: 'Notes History'); }
// class WhatIsIntellixPage extends PlaceholderPage { const WhatIsIntellixPage({super.key}) : super(title: 'What is Intellix'); }
// class NotificationPage extends PlaceholderPage { const NotificationPage({super.key}) : super(title: 'Notifications'); }
