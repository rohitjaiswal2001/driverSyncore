import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String contentMarkdown;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.contentMarkdown,
  });

  static void openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Terms of Service',
          contentMarkdown: _termsContent,
        ),
      ),
    );
  }

  static void openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Privacy Policy',
          contentMarkdown: _privacyContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Last updated: August 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.border),
              ),
              Text(
                contentMarkdown,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _termsContent = '''
1. Acceptance of Terms
By creating a globelink Driver account and using our logistics tracking services, you agree to comply with and be bound by these Terms of Service. If you do not agree, please do not use the application.

2. Driver Account & Authentication
You are responsible for maintaining the confidentiality of your login credentials and for all activities conducted under your account. You must notify globelink immediately of any unauthorized use.

3. Location Tracking & Telematics Services
globelink requires live GPS location access to facilitate shipment routing, customer delivery status, and background location telematics during active shipments. Live location streaming only operates while a shipment is in started or ongoing status.

4. User Obligations & Conduct
Drivers must operate motor vehicles safely and in full compliance with local traffic laws. You agree not to manipulate GPS location data, falsify shipment delivery statuses, or misuse customer contact information.

5. Modifications & Terminations
globelink reserves the right to suspend or terminate driver account access at any time for violation of safety policies or system abuse.
''';

  static const _privacyContent = '''
1. Information We Collect
We collect driver identification information (name, email address, phone number, vehicle details) and real-time location data necessary to track shipment progress during active deliveries.

2. Use of Location Data
Live GPS coordinates are collected in both foreground and background states strictly when a shipment is ongoing. Location data is shared only with authorized fleet managers and dispatchers to ensure accurate delivery estimates.

3. Data Storage & Security
Your data is securely stored using industry-standard encryption protocols. We do not sell or rent driver personal information or location logs to third parties.

4. Permissions Required
The application requests camera permissions (for proof of delivery photo capture), storage permissions (for document downloads), and precise location permissions (for navigation & telematics).

5. Contact & Support
If you have questions regarding your data privacy, please contact the globelink Support Team.
''';
}
