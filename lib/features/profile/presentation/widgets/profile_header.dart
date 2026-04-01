import 'dart:developer' as developer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Profile header with avatar, display name, and member-since date.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, super.key});

  final UserEntity user;

  Future<void> _showImagePicker(BuildContext context) async {
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
      developer.log(
        'Avatar image selected: ${image.path}',
        name: 'ProfileHeader',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.photoSelected'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberSince = '${user.createdAt.month}/${user.createdAt.year}';

    return Column(
      children: [
        DeelAvatar(
          displayName: user.displayName,
          imageUrl: user.avatarUrl,
          size: DeelAvatarSize.large,
          showEditOverlay: true,
          onEditTap: () => _showImagePicker(context),
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
