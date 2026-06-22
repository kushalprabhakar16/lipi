import 'package:flutter/material.dart';

class SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color titleColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool isProminent;
  final bool isDarkMode;
  final List<Widget> children;

  const SectionContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.titleColor,
    required this.backgroundColor,
    required this.borderColor,
    this.isProminent = false,
    required this.isDarkMode,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isProminent ? 1.2 : 0.8,
        ),
        boxShadow: isProminent && !isDarkMode
            ? [
                BoxShadow(
                  color: titleColor.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: titleColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: isProminent ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              if (isProminent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: titleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Focus',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: titleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
