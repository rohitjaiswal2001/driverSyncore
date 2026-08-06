import 'package:flutter/material.dart';

/// Circular user avatar that degrades gracefully.
///
/// A plain `CircleAvatar(backgroundImage: NetworkImage(...))` renders an empty
/// circle when the request fails or is still in flight. This widget shows the
/// user's initials instead, so the avatar is never blank.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor = const Color.fromARGB(255, 103, 99, 205),
    this.foregroundColor = Colors.white,
    this.border,
  });

  /// First uppercase letter for [name], falling back to `D` for driver.
  static String initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    return trimmed[0].toUpperCase();
  }

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasImage
          ? Image.network(
              imageUrl!.trim(),
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _initials(),
              errorBuilder: (context, error, stack) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.72,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
