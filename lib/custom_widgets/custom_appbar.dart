import 'package:flutter/material.dart';
import 'package:sevashare_v4/styles/appstyles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBackPressed;
  final VoidCallback? onSubtitlePressed; // New parameter for subtitle click
  final VoidCallback? onMenuPressed;
  final IconData? actionIcon;
  final Color? appBarColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onSubtitlePressed, // Initialize new parameter
    required this.onBackPressed,
    this.onMenuPressed,
    this.actionIcon,
    this.appBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 90.0,
      backgroundColor: appBarColor ?? AppStyles.bgColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,

      // Back Button
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 15),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: onBackPressed,
          color: AppStyles.primaryColor,
        ),
      ),

      // Title and Subtitle
      title: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppStyles.primaryColor,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              GestureDetector(
                onTap: onSubtitlePressed, // Trigger the callback here
                behavior: HitTestBehavior.opaque, // Makes the whole row clickable
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 15),
          child: IconButton(
            icon: Icon(
              actionIcon ?? Icons.menu_rounded,
              size: 28,
              color: AppStyles.primaryColor,
            ),
            onPressed: onMenuPressed ?? () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90.0);
}