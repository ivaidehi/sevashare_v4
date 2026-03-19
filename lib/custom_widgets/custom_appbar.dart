import 'package:flutter/material.dart';
import 'package:sevashare_v4/styles/appstyles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback? onMenuPressed;
  final IconData? actionIcon; // New parameter for the right-side icon
  final Color? appBarColor;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.onMenuPressed,
    this.actionIcon, // Pass this if you want something other than the menu
    this.appBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80.0,
      backgroundColor: appBarColor ?? AppStyles.bgColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,

      // Back Button
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 25),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: onBackPressed,
          color: AppStyles.primaryColor,
        ),
      ),

      // Title
      title: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppStyles.primaryColor,
          ),
        ),
      ),

      // Action Icon at the top right (Dynamic)
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 25),
          child: IconButton(
            // Uses actionIcon if provided, otherwise defaults to menu_rounded
            icon: Icon(
              actionIcon ?? Icons.menu_rounded,
              size: 28,
              color: AppStyles.primaryColor,
            ),
            onPressed: onMenuPressed ?? () {
              // Default logic to open drawer
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}