import 'package:flutter/material.dart';
import 'package:sevashare_v4/styles/appstyles.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final Color? appBarColor;
  const CustomAppBar({
    super.key,
    required this.title,
    required this.onBackPressed, this.appBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(20.0),
      child: AppBar(
        toolbarHeight: 80.0,
        backgroundColor: appBarColor ?? AppStyles.bgColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,

        // Back Button with top padding
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 25),
          child: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: onBackPressed,
            color: AppStyles.primaryColor, // Replace with AppStyles.primaryColor
          ),
        ),

        // Title with matching top padding
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(
            title,
            style:  TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppStyles.primaryColor, // Replace with AppStyles.primaryColor
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}