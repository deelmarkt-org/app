import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Profile header with avatar, display name, and member-since date.
///
/// Tapping the avatar edit overlay opens an image picker and uploads
/// the selected image via [ProfileNotifier.uploadAvatar].
///
/// Reference: docs/screens/07-profile/01-own-profile.md
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({required this.user, super.key});

  final UserEntity user;

  Future<void> _showImagePicker(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.s4),
                child: Semantics(
                  header: true,
                  child: Text(
                    'profile.pickPhoto'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(PhosphorIcons.camera()),
                title: Text('profile.takePhoto'.tr()),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(PhosphorIcons.images()),
                title: Text('profile.chooseFromGallery'.tr()),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: Spacing.s2),
            ],
          ),
        );
      },
    );

    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null && context.mounted) {
      try {
        await ref
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(image.path);
      } on Object catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('profile.avatarUploadFailed'.tr())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final memberSince = DateFormat.yMMM(locale).format(user.createdAt);
    final profileState = ref.watch(profileNotifierProvider);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            DeelAvatar(
              displayName: user.displayName,
              imageUrl: user.avatarUrl,
              size: DeelAvatarSize.large,
              showEditOverlay: true,
              onEditTap: () => _showImagePicker(context, ref),
            ),
            if (profileState.isUploadingAvatar)
              Semantics(
                label: 'profile.avatarUploading'.tr(),
                child: const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.s3),
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          '${'profile.memberSince'.tr()} $memberSince',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
