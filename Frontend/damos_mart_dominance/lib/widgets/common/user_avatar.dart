import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'loading_shimmer.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.radius,
    this.backgroundColor = const Color(0xFFF2F2F2),
    this.iconColor = const Color(0xFF6B7280),
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.person, color: iconColor, size: iconSize),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: ApiConfig.imageUrl(avatarUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ClipOval(
          child: LoadingShimmer(
            width: size,
            height: size,
            borderRadius: radius,
          ),
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: Icon(Icons.person, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
