import 'package:flutter/material.dart';
import 'dart:ui';

class FrostedCardResponsive extends StatelessWidget {
  final String title;
  final String value;
  final Color primaryText;
  final Color secondaryText;
  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;
  final IconData? leadingIcon; // optional icon
  final Color? iconColor; // optional color for icon

  const FrostedCardResponsive({
    required this.title,
    required this.value,
    required this.primaryText,
    required this.secondaryText,
    required this.gradientStart,
    required this.gradientEnd,
    required this.borderColor,
    this.leadingIcon,
    this.iconColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double cardWidth = (screenW * 0.38).clamp(96.0, 220.0);

    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: leadingIcon == null
          // No icon: center text
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
          // With icon: Row layout
              : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                leadingIcon,
                color: iconColor ?? primaryText,
                size: 28, // fixed for consistency
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
