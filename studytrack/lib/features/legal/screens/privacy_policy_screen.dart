import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Privacy Policy',
      subtitle: 'Last updated 1 May 2026',
      padBody: true,
      body: _LegalBody(sections: _privacySections),
    );
  }
}

// ── Terms of Service ─────────────────────────────────────────────────────────

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Terms of Service',
      subtitle: 'Last updated 1 May 2026',
      padBody: true,
      body: _LegalBody(sections: _termsSections),
    );
  }
}

// ── Shared renderer ───────────────────────────────────────────────────────────

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.sections});
  final List<_Section> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl + AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((s) => _SectionWidget(section: s)).toList(),
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({required this.section});
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.65,
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section(this.heading, this.body);
  final String heading;
  final String body;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY TEXT
// ─────────────────────────────────────────────────────────────────────────────

const List<_Section> _privacySections = [
  _Section(
    '1. Who We Are',
    'StudyTrack ("we", "us", "our") is an independent student productivity '
        'application developed to help health-sciences students organise their '
        'timetables, track study progress, and collaborate with peers. '
        'This Privacy Policy explains how we collect, use, and protect your personal '
        'data when you use the StudyTrack mobile application.',
  ),
  _Section(
    '2. Information We Collect',
    'Account information: When you sign up, we collect your full name, email '
        'address, course name, and year of study.\n\n'
        'Profile data: Study preferences, daily study goal, prime study time, and '
        'study style that you voluntarily provide during onboarding or later edits.\n\n'
        'Usage data: Study session durations, topic ratings, timetable entries, exam '
        'dates, and group membership — all created by you and stored on your behalf.\n\n'
        'Automatically collected data: Device type, operating system version, app '
        'version, and anonymised crash reports (via Sentry) to help us fix bugs.\n\n'
        'Voice notes: Audio recordings you create are processed locally on your device '
        'for transcription and are not transmitted to our servers unless you explicitly '
        'choose to upload them.',
  ),
  _Section(
    '3. How We Use Your Information',
    'We use your information solely to:\n'
        '• Provide and improve the StudyTrack service.\n'
        '• Personalise your experience (e.g., AI study recommendations via Google Gemini).\n'
        '• Send study reminders and exam countdown notifications (only if you enable them).\n'
        '• Generate your Weekly Wrapped report and progress analytics.\n'
        '• Diagnose and fix application crashes using anonymised crash reports.\n\n'
        'We do not sell, rent, or share your personal data with third parties for '
        'advertising purposes.',
  ),
  _Section(
    '4. Third-Party Services',
    'StudyTrack integrates with the following third-party services:\n\n'
        'Supabase (supabase.com) — provides our cloud database and authentication. '
        'Your data is stored in Supabase\'s managed PostgreSQL database, governed by '
        'their Privacy Policy.\n\n'
        'Google Gemini AI (ai.google.dev) — used to generate AI study summaries and '
        'tutor responses. Only your topic content and study context (not personally '
        'identifying information) is sent to the Gemini API.\n\n'
        'Sentry (sentry.io) — used for anonymised crash reporting. Stack traces and '
        'device metadata are shared with Sentry; no personally identifying information '
        'is included in crash reports by default.\n\n'
        'Spotify (spotify.com) — optional ambient music integration. If enabled, '
        'StudyTrack obtains a short-lived access token via OAuth; we do not store '
        'your Spotify credentials.',
  ),
  _Section(
    '5. Data Retention',
    'Your account data is retained for as long as your account remains active. '
        'You may permanently delete your account and all associated data at any time '
        'from Settings → Account → Delete Account. Deletion is irreversible.',
  ),
  _Section(
    '6. Data Security',
    'We protect your data using industry-standard measures:\n'
        '• All data is transmitted over HTTPS/TLS.\n'
        '• Supabase enforces row-level security (RLS) so you can only access your own data.\n'
        '• API keys are injected at build time and never embedded as plaintext in the app binary.\n'
        '• Sensitive local cache data is encrypted using AES-256 on device.\n\n'
        'No method of electronic storage or transmission is 100% secure. We encourage '
        'you to use a strong, unique password for your account.',
  ),
  _Section(
    '7. Children\'s Privacy',
    'StudyTrack is intended for users who are at least 16 years of age (or the '
        'minimum digital consent age in your jurisdiction). We do not knowingly collect '
        'data from children under 16. If you believe a child has created an account, '
        'please contact us and we will promptly delete it.',
  ),
  _Section(
    '8. Your Rights',
    'Depending on your location, you may have the right to:\n'
        '• Access the personal data we hold about you.\n'
        '• Correct inaccurate data (via Settings → Edit Profile).\n'
        '• Delete your data (via Settings → Delete Account).\n'
        '• Export your data as JSON (via Settings → Export Data).\n'
        '• Object to or restrict certain processing.\n\n'
        'To exercise any other rights, contact us at the address below.',
  ),
  _Section(
    '9. Changes to This Policy',
    'We may update this Privacy Policy from time to time. We will notify you of '
        'significant changes by displaying a notice in the app. Continued use after '
        'notice constitutes acceptance of the updated policy.',
  ),
  _Section(
    '10. Contact Us',
    'If you have questions about this Privacy Policy or wish to exercise your '
        'rights, please open an issue on our GitHub repository or contact the developer '
        'via the Support section in Settings.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// TERMS OF SERVICE TEXT
// ─────────────────────────────────────────────────────────────────────────────

const List<_Section> _termsSections = [
  _Section(
    '1. Acceptance of Terms',
    'By downloading, installing, or using StudyTrack ("the App"), you agree to '
        'be bound by these Terms of Service ("Terms"). If you do not agree to these '
        'Terms, do not use the App.',
  ),
  _Section(
    '2. Eligibility',
    'You must be at least 16 years old (or the applicable age of digital consent '
        'in your country) to create an account. By registering, you represent that '
        'you meet this requirement.',
  ),
  _Section(
    '3. Your Account',
    'You are responsible for maintaining the confidentiality of your account '
        'credentials and for all activity that occurs under your account. You agree to '
        'notify us immediately of any unauthorised use of your account.\n\n'
        'You may not use another person\'s account without their permission.',
  ),
  _Section(
    '4. Acceptable Use',
    'You agree NOT to:\n'
        '• Use the App for any unlawful purpose or in violation of any regulations.\n'
        '• Upload, share, or transmit content that is defamatory, harassing, obscene, '
        'or infringes any third-party intellectual property rights.\n'
        '• Attempt to reverse-engineer, decompile, or extract source code from the App.\n'
        '• Interfere with or disrupt the App\'s servers, networks, or security features.\n'
        '• Use automated tools (bots, scrapers) to access or extract data from the App.',
  ),
  _Section(
    '5. User-Generated Content',
    'You retain ownership of all content you create in StudyTrack (notes, topics, '
        'group messages, voice recordings). By using the App, you grant us a limited, '
        'non-exclusive licence to store and process that content solely for the purpose '
        'of providing the service to you.\n\n'
        'You are solely responsible for the content you share in study groups. We '
        'reserve the right to remove content that violates these Terms.',
  ),
  _Section(
    '6. AI-Generated Content',
    'The App uses Google Gemini AI to generate study recommendations and tutor '
        'responses. AI-generated content is provided for educational assistance only '
        'and should not be relied upon as professional medical, legal, or academic advice. '
        'Always verify AI-generated information with authoritative sources.',
  ),
  _Section(
    '7. Intellectual Property',
    'The StudyTrack application, including its design, code, branding, and '
        'non-user-generated content, is owned by the developer and protected by '
        'applicable copyright and intellectual property laws. You are granted a '
        'limited, non-transferable licence to use the App for personal, '
        'non-commercial purposes.',
  ),
  _Section(
    '8. Disclaimers',
    'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR '
        'IMPLIED, INCLUDING BUT NOT LIMITED TO FITNESS FOR A PARTICULAR PURPOSE, '
        'ACCURACY, OR NON-INFRINGEMENT.\n\n'
        'We do not guarantee that the App will be error-free, uninterrupted, or free '
        'of viruses. Study schedules, exam countdowns, and progress data depend on the '
        'accuracy of information you enter.',
  ),
  _Section(
    '9. Limitation of Liability',
    'To the maximum extent permitted by law, the developer shall not be liable for '
        'any indirect, incidental, special, or consequential damages arising out of or '
        'relating to your use of the App, including but not limited to loss of data, '
        'missed exams, or academic consequences.',
  ),
  _Section(
    '10. Termination',
    'We reserve the right to suspend or terminate your account at any time if you '
        'violate these Terms. You may delete your account at any time via Settings.\n\n'
        'Upon termination, your right to use the App ceases immediately. Sections 7, 8, '
        '9, and 11 survive termination.',
  ),
  _Section(
    '11. Governing Law',
    'These Terms are governed by the laws of the jurisdiction in which the '
        'developer is domiciled, without regard to conflict-of-law principles. '
        'Any disputes shall be resolved through binding arbitration or the courts '
        'of that jurisdiction.',
  ),
  _Section(
    '12. Changes to Terms',
    'We may update these Terms at any time. We will notify you of material changes '
        'via an in-app notice. Continued use of the App after the effective date of '
        'updated Terms constitutes your acceptance.',
  ),
  _Section(
    '13. Contact',
    'Questions about these Terms? Please open an issue on our GitHub repository '
        'or use the Support option in Settings.',
  ),
];
