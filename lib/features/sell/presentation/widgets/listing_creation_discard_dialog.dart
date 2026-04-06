import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows the "discard unsaved changes?" confirmation dialog.
///
/// Returns `true` when the user chooses to discard, `false` otherwise.
Future<bool> showDiscardDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('sell.discardTitle'.tr()),
          content: Text('sell.discardMessage'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('sell.keepEditing'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('sell.discard'.tr()),
            ),
          ],
        ),
  );
  return result ?? false;
}
