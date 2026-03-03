import 'package:flutter/material.dart';

/// Predefined avatar data for profile selection.
class AvatarData {
  final String id;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String label;

  const AvatarData({
    required this.id,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.label,
  });
}

/// Collection of predefined avatars users can choose from.
class Avatars {
  Avatars._();

  static const List<AvatarData> all = [
    AvatarData(
      id: 'avatar_ninja',
      icon: Icons.psychology_rounded,
      backgroundColor: Color(0xFF6C63FF),
      iconColor: Colors.white,
      label: 'Ninja',
    ),
    AvatarData(
      id: 'avatar_astronaut',
      icon: Icons.rocket_launch_rounded,
      backgroundColor: Color(0xFF00BCD4),
      iconColor: Colors.white,
      label: 'Astronaut',
    ),
    AvatarData(
      id: 'avatar_wizard',
      icon: Icons.auto_fix_high_rounded,
      backgroundColor: Color(0xFF9C27B0),
      iconColor: Colors.white,
      label: 'Wizard',
    ),
    AvatarData(
      id: 'avatar_artist',
      icon: Icons.palette_rounded,
      backgroundColor: Color(0xFFFF9100),
      iconColor: Colors.white,
      label: 'Artist',
    ),
    AvatarData(
      id: 'avatar_explorer',
      icon: Icons.explore_rounded,
      backgroundColor: Color(0xFF4CAF50),
      iconColor: Colors.white,
      label: 'Explorer',
    ),
    AvatarData(
      id: 'avatar_coder',
      icon: Icons.code_rounded,
      backgroundColor: Color(0xFF1E88E5),
      iconColor: Colors.white,
      label: 'Coder',
    ),
    AvatarData(
      id: 'avatar_music',
      icon: Icons.music_note_rounded,
      backgroundColor: Color(0xFFE91E63),
      iconColor: Colors.white,
      label: 'Musician',
    ),
    AvatarData(
      id: 'avatar_gamer',
      icon: Icons.sports_esports_rounded,
      backgroundColor: Color(0xFF00E676),
      iconColor: Colors.white,
      label: 'Gamer',
    ),
    AvatarData(
      id: 'avatar_chef',
      icon: Icons.restaurant_rounded,
      backgroundColor: Color(0xFFFF5722),
      iconColor: Colors.white,
      label: 'Chef',
    ),
    AvatarData(
      id: 'avatar_athlete',
      icon: Icons.fitness_center_rounded,
      backgroundColor: Color(0xFFFF6D00),
      iconColor: Colors.white,
      label: 'Athlete',
    ),
    AvatarData(
      id: 'avatar_reader',
      icon: Icons.menu_book_rounded,
      backgroundColor: Color(0xFF5C6BC0),
      iconColor: Colors.white,
      label: 'Reader',
    ),
    AvatarData(
      id: 'avatar_nature',
      icon: Icons.eco_rounded,
      backgroundColor: Color(0xFF2E7D32),
      iconColor: Colors.white,
      label: 'Nature',
    ),
    AvatarData(
      id: 'avatar_star',
      icon: Icons.star_rounded,
      backgroundColor: Color(0xFFFFC107),
      iconColor: Colors.white,
      label: 'Star',
    ),
    AvatarData(
      id: 'avatar_crown',
      icon: Icons.workspace_premium_rounded,
      backgroundColor: Color(0xFFD4AF37),
      iconColor: Colors.white,
      label: 'Royal',
    ),
    AvatarData(
      id: 'avatar_heart',
      icon: Icons.favorite_rounded,
      backgroundColor: Color(0xFFF44336),
      iconColor: Colors.white,
      label: 'Heart',
    ),
    AvatarData(
      id: 'avatar_diamond',
      icon: Icons.diamond_rounded,
      backgroundColor: Color(0xFF00ACC1),
      iconColor: Colors.white,
      label: 'Diamond',
    ),
  ];

  /// Get avatar by ID. Returns first avatar as fallback.
  static AvatarData getById(String? id) {
    if (id == null || id.isEmpty) return all.first;
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => all.first,
    );
  }
}
