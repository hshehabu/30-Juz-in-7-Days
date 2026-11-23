import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/locale_keys.g.dart';
import '../../core/theme/app_colors.dart';
import '../challenge/presentation/notifiers/challenge_providers.dart';

/// Manual backup: save progress as a small JSON file through the system share
/// sheet (Drive, Telegram, email, Files…) and restore it from a file or text.
class BackupActions {
  BackupActions._();

  static String fileName(DateTime now) =>
      'thirty-juz-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';

  /// Opens the share sheet with the backup file attached.
  static Future<void> saveBackupFile(BuildContext context, WidgetRef ref) async {
    final json = ref.read(challengeStateProvider.notifier).exportBackup();
    final now = DateTime.now();
    final name = fileName(now);

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(json),
            name: name,
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [name],
        subject: LocaleKeys.settings.backup_subject.tr(),
        sharePositionOrigin: origin,
      ));
      if (result.status != ShareResultStatus.dismissed) {
        await ref.read(challengeStateProvider.notifier).markBackupSaved(now);
      }
    } catch (_) {
      if (context.mounted) _snack(context, LocaleKeys.errors.generic.tr());
    }
  }

  /// Lets the user choose between restoring from a file or pasted text.
  static Future<void> showRestoreOptions(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.settings.import_backup.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.signalBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.settings.import_warning.tr(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.terracotta),
                ),
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('restore_from_file'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_open_rounded,
                      color: AppColors.ink),
                  title: Text(LocaleKeys.settings.restore_from_file.tr()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    restoreFromFile(context, ref);
                  },
                ),
                ListTile(
                  key: const Key('restore_from_text'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_paste_rounded,
                      color: AppColors.ink),
                  title: Text(LocaleKeys.settings.restore_from_text.tr()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    restoreFromText(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> restoreFromFile(BuildContext context, WidgetRef ref) async {
    String? raw;
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty) return;
      raw = utf8.decode(await files.first.readAsBytes());
    } catch (_) {
      if (context.mounted) {
        _snack(context, LocaleKeys.settings.import_failed.tr());
      }
      return;
    }
    if (!context.mounted) return;
    await _restore(context, ref, raw);
  }

  static Future<void> restoreFromText(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleKeys.settings.restore_from_text.tr()),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText: LocaleKeys.settings.import_hint.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocaleKeys.common.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(LocaleKeys.settings.import_confirm.tr()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty || !context.mounted) return;
    await _restore(context, ref, raw);
  }

  static Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    String raw,
  ) async {
    final ok =
        await ref.read(challengeStateProvider.notifier).importBackup(raw);
    if (!context.mounted) return;
    _snack(
      context,
      ok
          ? LocaleKeys.settings.import_done.tr()
          : LocaleKeys.settings.import_failed.tr(),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }
}
