import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/avatars.dart';

/// ProfileAvatar - Reusable widget showing user avatar (predefined icon) or initials.
/// Supports tap action and animated border.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? avatarId;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.avatarId,
    required this.name,
    this.size = 100,
    this.onTap,
    this.showEditIcon = false,
    this.showBorder = true,
  });

  bool get _hasAvatar => avatarId != null && avatarId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final innerSize =
        showBorder ? size - 6 : size; // account for border padding

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Outer border container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: showBorder ? AppTheme.primaryGradient : null,
              boxShadow: showBorder
                  ? AppTheme.neonGlow(AppTheme.primaryColor, intensity: 0.15)
                  : null,
            ),
            padding: showBorder ? const EdgeInsets.all(3) : null,
            child: _hasAvatar
                ? _buildAvatarIcon(innerSize)
                : _buildInitials(innerSize),
          ),

          // Camera edit icon
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: size * 0.16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon(double diameter) {
    final avatar = Avatars.getById(avatarId);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatar.backgroundColor,
      ),
      child: Center(
        child: Icon(
          avatar.icon,
          color: avatar.iconColor,
          size: diameter * 0.48,
        ),
      ),
    );
  }

  Widget _buildInitials(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: diameter * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
