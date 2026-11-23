import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/challenge.dart';

/// System share sheet for celebrating a completed khatmah.
class ShareActions {
  ShareActions._();

  static Future<void> shareCompletion(
    BuildContext context,
    Challenge challenge,
  ) async {
    final locale = context.locale.languageCode;
    final message = LocaleKeys.share.completion_message.tr(args: [
      AppDateUtils.formatDate(challenge.startDate, locale),
      AppDateUtils.formatDate(challenge.endDate, locale),
    ]);

    // iPad needs an anchor rectangle for the share popover.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      await SharePlus.instance.share(ShareParams(
        text: message,
        subject: LocaleKeys.share.subject.tr(),
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      // Sharing is optional; ignore platforms without a share sheet.
    }
  }
}
