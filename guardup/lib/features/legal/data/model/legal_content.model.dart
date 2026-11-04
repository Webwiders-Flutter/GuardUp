import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/content_type.enum.dart';

part 'legal_content.model.freezed.dart';
part 'legal_content.model.g.dart';

/// Represents a single legal clause or policy section card.
@freezed
abstract class LegalClause with _$LegalClause {
  const factory LegalClause({
    required String clauseNumber,
    required String tag,
    required String title,
    required String content,
  }) = _LegalClause;

  factory LegalClause.fromJson(Map<String, dynamic> json) =>
      _$LegalClauseFromJson(json);
}

/// Data model representing a legal document or governance policy.
@freezed
abstract class LegalContentModel with _$LegalContentModel {
  const factory LegalContentModel({
    required String id,
    required ContentType contentType,
    required String title,
    String? subtitle,
    String? headerDescription,
    @Default([]) List<LegalClause> clauses,
    required String contentHtml,
    DateTime? updatedAt,
  }) = _LegalContentModel;

  factory LegalContentModel.fromJson(Map<String, dynamic> json) =>
      _$LegalContentModelFromJson(json);

  /// Factory providing elite static content matching GuardUp VIP protection governance.
  factory LegalContentModel.staticContent(ContentType type) {
    switch (type) {
      case ContentType.terms:
        const headerTitle = 'Master Service Governance';
        const headerSub = 'Physical Security, On-Demand Escort & VIP Logistics';
        const headerDesc =
            'These Terms govern all close-protection deployment, tactical ground escort, and specialized security details booked via GuardUp Global. Engagement of certified operatives entails binding obligations regarding legal conduct, identity compliance, and emergency protocols.';

        const clauses = [
          LegalClause(
            clauseNumber: 'CLAUSE 1.0',
            tag: 'Operational Protocol',
            title: 'Close-Protection & Tactical Escort',
            content: 'All booked protection operatives are licensed under national and municipal security regulatory frameworks. Operatives maintain autonomous discretion to implement defensive counter-measures, evasive driving routes, and protective extraction maneuvers when imminent peril is identified.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 2.0',
            tag: 'Identity & Clearance',
            title: 'Vetting & Client Compliance',
            content: 'Clients must undergo mandatory biometric or government ID verification prior to armed operative dispatch. Providing fraudulent credentials, concealing active legal warrants, or instructing operatives to participate in unlawful activities will result in immediate mission termination with zero refund.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 3.0',
            tag: 'Billing & Retainers',
            title: 'Hourly Deployments & Standby Rates',
            content: 'Protection assignments are billed at hourly rates with minimum operational billing windows. Extended overwatch, cross-jurisdictional transit, and hazardous zone premiums are calculated transparently and invoiced immediately upon mission completion.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 4.0',
            tag: 'Confidentiality',
            title: 'Discretion & Non-Disclosure',
            content: 'GuardUp enforces strict non-disclosure obligations across all missions. Operatives and platform staff are legally bound against disclosing client identities, transit itineraries, travel schedules, or private communications under any circumstances.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 5.0',
            tag: 'Statutory Limits',
            title: 'Limitation of Liability & Force Majeure',
            content: 'While GuardUp verifies security clearances, licensing, and insurance of all registered operatives, GuardUp acts as an intermediary coordinating network. Force majeure events including civil insurrections, declared states of emergency, air traffic airspace shutdowns, or catastrophic grid failures absolve instant fulfillment guarantees.',
          ),
        ];

        return LegalContentModel(
          id: 'master-service-governance',
          contentType: type,
          title: 'Terms & Conditions',
          subtitle: headerSub,
          headerDescription: headerDesc,
          clauses: clauses,
          updatedAt: DateTime(2026, 1, 1),
          contentHtml: _generateHtml(
            headerTitle,
            headerSub,
            headerDesc,
            clauses,
          ),
        );

      case ContentType.privacyPolicy:
        const headerTitle = 'Information Security & Telemetry';
        const headerSub = 'Tactical Telemetry, Encryption & Data Sovereignty';
        const headerDesc =
            'Your operational telemetry, travel itineraries, and emergency contacts are safeguarded with military-grade encryption. GuardUp adheres to international zero-knowledge privacy standards to ensure complete client discretion.';

        const clauses = [
          LegalClause(
            clauseNumber: 'CLAUSE 1.0',
            tag: 'Active Telemetry',
            title: 'Real-Time Geolocation Tracking',
            content: 'Live GPS telemetry is accessed strictly during active close-protection sessions to coordinate operative arrival, calculate dynamic extraction paths, and coordinate emergency reinforcement dispatch. Tracking terminates immediately upon booking conclusion.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 2.0',
            tag: 'Data Sovereignty',
            title: 'Zero-Knowledge Cryptographic Storage',
            content: 'Identity credentials, biometric validation hashes, and payment tokens are stored with AES-256 encryption at rest and TLS 1.3 in transit. Raw payment details are processed exclusively through compliant PCI-DSS Tier 1 vault gateways.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 3.0',
            tag: 'Non-Commercial Data',
            title: 'Zero Data Brokerage or Monetization',
            content: 'GuardUp maintains a strict anti-monetization policy. Your profile records, deployment locations, and travel habits will never be shared, leased, or disclosed to advertising networks or third-party analytical vendors.',
          ),
          LegalClause(
            clauseNumber: 'CLAUSE 4.0',
            tag: 'Client Autonomy',
            title: 'Telemetry Purging & Erasure Rights',
            content: 'Clients possess unilateral rights to purge non-statutory deployment histories, location breadcrumbs, and stored communication transcripts directly from account privacy controls at any time.',
          ),
        ];

        return LegalContentModel(
          id: 'privacy-policy-governance',
          contentType: type,
          title: 'Privacy Policy',
          subtitle: headerSub,
          headerDescription: headerDesc,
          clauses: clauses,
          updatedAt: DateTime(2026, 1, 1),
          contentHtml: _generateHtml(
            headerTitle,
            headerSub,
            headerDesc,
            clauses,
          ),
        );

      case ContentType.aboutUs:
        const headerTitle = 'GuardUp Command & Operations';
        const headerSub =
            'Next-Generation Close Protection & Security Dispatch';
        const headerDesc =
            'GuardUp was engineered to eliminate friction in personal security. By bridging certified protection specialists, bodyguards, and armored escorts with individuals and corporate executives, we provide unparalleled safety with instant availability.';

        const clauses = [
          LegalClause(
            clauseNumber: 'PILLAR 1.0',
            tag: 'Operative Standards',
            title: 'Rigorous Vetting & Background Clearances',
            content: 'Every security operative in our network undergoes comprehensive background vetting, credential authentication, firearms proficiency evaluations, and tactical defensive driving audits.',
          ),
          LegalClause(
            clauseNumber: 'PILLAR 2.0',
            tag: 'Rapid Deployment',
            title: 'High-Speed Dispatch Infrastructure',
            content: 'Our dispatch algorithms connect verified principals with nearby certified operatives in real time, reducing response windows from hours to minutes.',
          ),
        ];

        return LegalContentModel(
          id: 'about-guardup',
          contentType: type,
          title: 'About Us',
          subtitle: headerSub,
          headerDescription: headerDesc,
          clauses: clauses,
          updatedAt: DateTime(2026, 1, 1),
          contentHtml: _generateHtml(
            headerTitle,
            headerSub,
            headerDesc,
            clauses,
          ),
        );

      case ContentType.deleteAccount:
        const headerTitle = 'Account Termination Governance';
        const headerSub = 'Cryptographic Deletion & Audit Compliance';
        const headerDesc =
            'Initiating account deletion permanently disconnects active security retainers, purges identification documents, and removes personal records from the GuardUp network.';

        const clauses = [
          LegalClause(
            clauseNumber: 'PROTOCOL 1.0',
            tag: 'Irreversible Deletion',
            title: 'Immediate Credential Purging',
            content: 'Upon confirmation, your profile, active payment tokens, and saved addresses are scrubbed from active production databases.',
          ),
          LegalClause(
            clauseNumber: 'PROTOCOL 2.0',
            tag: 'Statutory Compliance',
            title: 'Regulatory Financial Archival',
            content: 'In accordance with anti-money laundering and tax governance regulations, completed transaction receipts and legal invoices are retained in an immutable vault for the statutorily mandated duration.',
          ),
        ];

        return LegalContentModel(
          id: 'delete-account-policy',
          contentType: type,
          title: 'Delete Account Policy',
          subtitle: headerSub,
          headerDescription: headerDesc,
          clauses: clauses,
          updatedAt: DateTime(2026, 1, 1),
          contentHtml: _generateHtml(
            headerTitle,
            headerSub,
            headerDesc,
            clauses,
          ),
        );

      case ContentType.support:
        const headerTitle = '24/7 Security Operations Center';
        const headerSub = 'Emergency Overwatch & Client Support';
        const headerDesc =
            'Our tactical command center maintains continuous surveillance of active security details, rapid reinforcement routing, and real-time principal assistance.';

        const clauses = [
          LegalClause(
            clauseNumber: 'DESK 1.0',
            tag: 'Emergency Response',
            title: 'SOS & Priority Extraction',
            content: 'In critical distress situations during an active mission, utilize the in-app SOS trigger for immediate response routing and law enforcement relay.',
          ),
          LegalClause(
            clauseNumber: 'DESK 2.0',
            tag: 'General Inquiries',
            title: 'Billing & Corporate Retainers',
            content: 'For contract modifications, invoice queries, or recurring corporate retainer setups, submit a ticket via Contact Us or reach dispatch directly.',
          ),
        ];

        return LegalContentModel(
          id: 'support-governance',
          contentType: type,
          title: 'Help & Support',
          subtitle: headerSub,
          headerDescription: headerDesc,
          clauses: clauses,
          updatedAt: DateTime(2026, 1, 1),
          contentHtml: _generateHtml(
            headerTitle,
            headerSub,
            headerDesc,
            clauses,
          ),
        );
    }
  }

  static String _generateHtml(
    String headerTitle,
    String headerSub,
    String headerDesc,
    List<LegalClause> clauses,
  ) {
    final buffer = StringBuffer();
    buffer.write('''
      <div class="header-card">
        <h2 style="color: #EDCC73; margin: 0 0 4px 0;">$headerTitle</h2>
        <p style="color: #A0A5BA; font-size: 13px; margin: 0 0 12px 0;">$headerSub</p>
        <p style="color: #FFFFFF; font-size: 14px; line-height: 1.5; margin: 0;">$headerDesc</p>
      </div>
    ''');

    for (final c in clauses) {
      buffer.write('''
        <div class="clause-card" style="margin-top: 16px;">
          <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
            <span style="color: #EDCC73; font-weight: bold; font-size: 11px;">${c.clauseNumber}</span>
            <span style="color: #A0A5BA; font-size: 11px;">${c.tag}</span>
          </div>
          <h3 style="color: #FFFFFF; font-size: 15px; margin: 0 0 8px 0;">${c.title}</h3>
          <p style="color: #C0C5D8; font-size: 13px; line-height: 1.5; margin: 0;">${c.content}</p>
        </div>
      ''');
    }

    return buffer.toString();
  }
}
