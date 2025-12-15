import 'package:flutter/material.dart';

class FrostedCardResponsive extends StatelessWidget {
  final String title;
  final String value;
  final Color primaryText;
  final Color secondaryText;
  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;
  final IconData? leadingIcon;
  final Color? iconColor;

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

    // Scale based on screen size
    final double cardWidth = screenW < 360
        ? (screenW * 0.44)
        : (screenW * 0.38).clamp(110.0, 240.0);

    final double titleSize = screenW < 360 ? 10 : 11;
    final double valueSize = screenW < 360 ? 14 : 16;
    final double iconSize = screenW < 360 ? 24 : 28;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),

      /// Replaced gradient + blur with a ultra-light background
      decoration: BoxDecoration(
        color: gradientStart.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(2, 2),
          )
        ],
      ),

      /// No more BackdropFilter → MUCH faster
      child: leadingIcon == null
          ? _buildCenterLayout(titleSize, valueSize)
          : _buildRowLayout(titleSize, valueSize, iconSize),
    );
  }

  // Center layout (no icon)
  Widget _buildCenterLayout(double titleSize, double valueSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Row layout (with icon)
  Widget _buildRowLayout(double titleSize, double valueSize, double iconSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          leadingIcon,
          color: iconColor ?? primaryText,
          size: iconSize,
        ),
        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}
