import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';

class DiabloAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLogo;
  final bool showBack;

  const DiabloAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLogo = true,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DiabloColors.red,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBack,
      title: showLogo
          ? Image.network(
              'https://missionfootball.com/wp-content/uploads/2024/09/MV_FB_LOGO_WLACES.png',
              height: 44,
              errorBuilder: (context, error, stackTrace) => Text(
                title ?? 'MVHS FOOTBALL',
                style: const TextStyle(
                  color: DiabloColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            )
          : Text(
              title?.toUpperCase() ?? '',
              style: const TextStyle(
                color: DiabloColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
      actions: actions,
    );
  }
}
