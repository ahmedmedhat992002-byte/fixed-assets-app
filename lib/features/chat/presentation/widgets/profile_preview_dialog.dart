import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/profile/models/profile_model.dart';
import '../../../../features/profile/presentation/profile_screen.dart';

class ProfilePreviewDialog extends StatelessWidget {
  const ProfilePreviewDialog({
    super.key,
    required this.profile,
    required this.onChatTap,
  });

  final ProfileModel profile;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        children: [
          Hero(
            tag: 'avatar_${profile.uid}',
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(0),
              ),
              child: profile.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profile.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 100,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 150,
                      color: AppColors.textMuted,
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black26,
              child: Text(
                profile.fullName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.chat, color: theme.colorScheme.primary),
                    onPressed: () {
                      Navigator.pop(context);
                      onChatTap();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: profile.uid),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
