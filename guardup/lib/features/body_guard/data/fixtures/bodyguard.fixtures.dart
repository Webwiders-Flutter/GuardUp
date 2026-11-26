import '/features/auth/data/enum/user_status.enum.dart';
import '/features/company/data/fixtures/company.fixtures.dart';
import '../enum/week_day.enum.dart';
import '../model/body_guard.model.dart';
import '../model/user_availability.model.dart';

/// Placeholder 7-day schedule used by [bodyguardPlaceholders].
final List<UserAvailabilityModel> placeholderAvailabilities = [
  for (final day in WeekDay.values)
    UserAvailabilityModel(
      id: 'avail_${day.apiValue}',
      dayOfWeek: day,
      isAvailable: true,
      fromTime: '08:00 AM',
      toTime: '10:00 PM',
    ),
];

/// Placeholder bodyguards for skeleton loaders and preview fallbacks only.
/// Never shown as real data.
final List<BodyGuardModel> bodyguardPlaceholders = [
  BodyGuardModel(
    id: 'guard_vikram_singh',
    name: 'Vikram Singh',
    company: companyPlaceholders[0],
    availabilities: placeholderAvailabilities,
    hourlyRate: 60.0,
    bio: 'Former Special Forces operative with 5+ years of high-threat dignitary protection, tactical motorcade operations, and counter-surveillance across global metropolitan centers.',
    qualifications: 'Certified Close Protection Spec',
    status: UserStatus.active,
  ),
  BodyGuardModel(
    id: 'guard_marcus_sterling',
    name: 'Marcus Sterling',
    company: companyPlaceholders[1],
    availabilities: placeholderAvailabilities,
    hourlyRate: 85.0,
    bio: 'High-value bullion and luxury asset courier protection specialist with extensive urban combat and emergency route-clearing background.',
    qualifications: 'Tactical Defensive Driving Spec',
    status: UserStatus.active,
  ),
  BodyGuardModel(
    id: 'guard_elena_rostova',
    name: 'Elena Rostova',
    company: companyPlaceholders[2],
    availabilities: placeholderAvailabilities,
    hourlyRate: 75.0,
    bio: 'Former intelligence tactical trainer specializing in high-profile celebrity, diplomat, and executive close-quarter protection details.',
    qualifications: 'Executive Protection & Threat Recon',
    status: UserStatus.active,
  ),
];
