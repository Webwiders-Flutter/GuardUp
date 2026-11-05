import 'package:flutter/material.dart';

import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/auth/data/model/user.model.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/body_guard/data/enum/guard_service.enum.dart';
import '/gen/assets.gen.dart';

/// Service category for customer browsing.
class CustomerServiceCategory {
  final String id;
  final String title;
  final String icon;

  const CustomerServiceCategory({
    required this.id,
    required this.title,
    required this.icon,
  });

  static List<CustomerServiceCategory> defaultCategories = [
    CustomerServiceCategory(
      id: 'all',
      title: 'All',
      icon: Assets.svg.menu.path,
    ),
    CustomerServiceCategory(
      id: 'premium_car',
      title: 'Premium car',
      icon: Assets.svg.car.path,
    ),
    CustomerServiceCategory(
      id: 'licensed_armed',
      title: 'Licensed armed',
      icon: Assets.svg.check.path,
    ),
    CustomerServiceCategory(
      id: 'corporate_visits',
      title: 'Corporate visits',
      icon: Assets.svg.visit.path,
    ),
  ];
}

/// Summary model for featured security companies.
class CustomerCompanyItem {
  final String id;
  final String name;
  final String initials;
  final int activeGuards;
  final double rating;
  final String bookingsCount;
  final String experienceYears;

  const CustomerCompanyItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.activeGuards,
    required this.rating,
    required this.bookingsCount,
    required this.experienceYears,
  });

  static const List<CustomerCompanyItem> sampleCompanies = [
    CustomerCompanyItem(
      id: 'comp_securepro',
      name: 'SecurePro Security Ltd.',
      initials: 'SP',
      activeGuards: 12,
      rating: 4.9,
      bookingsCount: '540+ Bookings',
      experienceYears: '15+ Yrs Exp',
    ),
    CustomerCompanyItem(
      id: 'comp_aegis',
      name: 'Aegis Elite Tactical',
      initials: 'AE',
      activeGuards: 8,
      rating: 4.98,
      bookingsCount: '510 Bookings',
      experienceYears: '22+ Yrs Exp',
    ),
  ];
}

/// Extended data helper for bodyguards matching the design mockups.
class CustomerBodyguardItem {
  final BodyGuardModel model;
  final String availabilityStatus;
  final List<String> tagLabels;

  const CustomerBodyguardItem({
    required this.model,
    required this.availabilityStatus,
    required this.tagLabels,
  });

  static List<CustomerBodyguardItem> get sampleBodyguards => [
    CustomerBodyguardItem(
      model: BodyGuardModel(
        id: 'guard_vikram_singh',
        user: UserModel(
          id: 'usr_vikram',
          name: 'Vikram Singh',
          profileImageUrl: Assets.images.profilePicture.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        currency: 'USD',
        rating: 4.9,
        reviewCount: 128,
        experienceYears: 9,
        serviceTypes: [
          GuardService.vipCloseProtection,
          GuardService.armedEscort,
          GuardService.tacticalDriver,
        ],
        bio: 'Elite executive bodyguard licensed for high-threat executive transit, armed security, and corporate event defense.',
        isVerified: true,
      ),
      availabilityStatus: 'Available Today',
      tagLabels: ['Armed', 'Tactical Driver'],
    ),
    CustomerBodyguardItem(
      model: BodyGuardModel(
        id: 'guard_marcus_sterling',
        user: UserModel(
          id: 'usr_marcus',
          name: 'Marcus Sterling',
          profileImageUrl: Assets.images.profilePicture2.path,
          role: UserRole.guard,
        ),
        hourlyRate: 85.0,
        currency: 'USD',
        rating: 4.95,
        reviewCount: 214,
        experienceYears: 8,
        serviceTypes: [
          GuardService.vipCloseProtection,
          // GuardService.corporateProtection,
        ],
        bio: 'Former military intelligence officer providing comprehensive tactical escort and corporate reconnaissance.',
        isVerified: true,
      ),
      availabilityStatus: 'Available Now',
      tagLabels: ['Armed Escort', 'Recon Specialist'],
    ),
    CustomerBodyguardItem(
      model: BodyGuardModel(
        id: 'guard_elena_rostova',
        user: UserModel(
          id: 'usr_elena',
          name: 'Elena Rostova',
          profileImageUrl: Assets.images.profilePicture.path,
          role: UserRole.guard,
        ),
        hourlyRate: 75.0,
        currency: 'USD',
        rating: 4.92,
        reviewCount: 95,
        experienceYears: 6,
        serviceTypes: [
          GuardService.vipCloseProtection,
          GuardService.residentialProtection,
        ],
        bio: 'Diplomatic dignitary security specialist with international escort certifications and bilingual fluency.',
        isVerified: true,
      ),
      availabilityStatus: 'Available Today',
      tagLabels: ['Close Protection', 'Bilingual'],
    ),
    CustomerBodyguardItem(
      model: BodyGuardModel(
        id: 'guard_david_vance',
        user: UserModel(
          id: 'usr_david_vance',
          name: 'David Vance',
          profileImageUrl: Assets.images.profilePicture2.path,
          role: UserRole.guard,
        ),
        hourlyRate: 65.0,
        currency: 'USD',
        rating: 4.88,
        reviewCount: 76,
        experienceYears: 4,
        serviceTypes: [
          GuardService.vipCloseProtection,
          GuardService.eventSecurity,
        ],
        bio: 'Experienced corporate convoy specialist with defensive driving and medical first-response qualifications.',
        isVerified: true,
      ),
      availabilityStatus: 'Available Tomorrow',
      tagLabels: ['Tactical Driver', 'First Responder'],
    ),
  ];
}
