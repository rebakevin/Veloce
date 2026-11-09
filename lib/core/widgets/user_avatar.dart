import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Round avatar: the photo, or the initials on a brand tint.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    super.key,
    this.photoUrl,
    this.radius = 24,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = photoUrl;
    return Semantics(
      label: 'Photo of $name',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.brandTint,
        backgroundImage: url == null ? null : CachedNetworkImageProvider(url),
        child: url == null
            ? Text(
                _initials(name),
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.brandDeep,
                ),
              )
            : null,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
