import 'package:flutter/material.dart';

import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/string.extension.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import 'review.widgets.dart';

/// Rates, experience, skills and bio of a bodyguard (self-registered or
/// company-managed).
class BodyguardDetailsSection extends StatelessWidget {
  const BodyguardDetailsSection({
    super.key,
    required this.bodyguard,
    this.services = const [],
  });

  final BodyguardModel bodyguard;

  /// Service names: the account's services for a self-registered bodyguard,
  /// the bodyguard's own for a company-managed one.
  final List<String> services;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bio = bodyguard.bio?.trim();
    final languages = bodyguard.languages?.toCommaSeparatedList ?? const [];
    final certifications =
        bodyguard.certifications?.toCommaSeparatedList ?? const [];
    final experienceYears = bodyguard.experienceYears ?? 0;
    final hourlyRate = bodyguard.hourlyRate ?? 0;
    final rating = bodyguard.rating ?? 0;
    final hasChips =
        services.isNotEmpty ||
        languages.isNotEmpty ||
        certifications.isNotEmpty;

    return AppDetailSection(
      title: 'Bodyguard Operative Details',
      subtitle: 'Rates, experience, skills and professional bio',
      icon: Icons.security_outlined,
      items: [
        (
          label: 'Hourly Rate',
          value: hourlyRate > 0 ? '${hourlyRate.toUsdAmount} / hr' : 'Not set',
          icon: Icons.attach_money_rounded,
        ),
        (
          label: 'Rating',
          value: rating > 0 ? '★ ${rating.toStringAsFixed(1)}' : '0.0',
          icon: Icons.star_rate_rounded,
        ),
        (
          label: 'Experience',
          value: experienceYears > 0
              ? '$experienceYears ${experienceYears == 1 ? 'year' : 'years'}'
              : 'Less than a year',
          icon: Icons.workspace_premium_outlined,
        ),
        if (bodyguard.address != null && bodyguard.address!.isNotEmpty)
          (
            label: 'Service Area',
            value: bodyguard.address!,
            icon: Icons.location_on_outlined,
          ),
        if (bio != null && bio.isNotEmpty)
          (label: 'Bio', value: bio, icon: Icons.description_outlined),
      ],
      child: hasChips
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (services.isNotEmpty)
                  ProfileChipGroup(
                    title: 'Services & Specializations',
                    values: services,
                    color: colors.primary,
                  ),
                if (languages.isNotEmpty)
                  ProfileChipGroup(
                    title: 'Languages',
                    values: languages,
                    color: colors.info,
                    icon: Icons.translate_rounded,
                  ),
                if (certifications.isNotEmpty)
                  ProfileChipGroup(
                    title: 'Certifications & Licenses',
                    values: certifications,
                    color: colors.success,
                    icon: Icons.verified_outlined,
                  ),
              ],
            )
          : null,
    );
  }
}
