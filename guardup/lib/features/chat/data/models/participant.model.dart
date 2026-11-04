import 'package:guardup/features/auth/auth.dart';

import '/gen/assets.gen.dart';

/// Represents a user or operative participating in a conversation.
class ParticipantModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final UserRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? clearanceLevel;

  const ParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isVerified = false,
    this.role = UserRole.guard,
    this.isOnline = false,
    this.lastSeen,
    this.clearanceLevel,
  });

  ParticipantModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isVerified,
    UserRole? role,
    bool? isOnline,
    DateTime? lastSeen,
    String? clearanceLevel,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
    );
  }

  /// Curated fake participants matching the mockup operative roster.
  static List<ParticipantModel> get fakeParticipants => [
    ParticipantModel(
      id: 'usr_vikram',
      name: 'Vikram Singh',
      avatarUrl: Assets.images.profilePicture2.path,
      isVerified: true,
      role: .guard,
      isOnline: true,
      clearanceLevel: 'Executive VIP Escort',
    ),
    ParticipantModel(
      id: 'usr_david',
      name: 'David Sterling',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Armed Transport',
    ),
    ParticipantModel(
      id: 'usr_marcus',
      name: 'Marcus Sterling',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Close Protection',
    ),
    ParticipantModel(
      id: 'usr_carlos',
      name: 'Carlos Sterling',
      avatarUrl: Assets.images.profilePicture2.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Static Perimeter',
    ),
  ];
}
