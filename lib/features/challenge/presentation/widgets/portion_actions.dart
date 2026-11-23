import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../../../core/widgets/countdown_undo_toast.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import 'day_detail_sheet.dart';
import 'reading_plan.dart';
import 'reading_plan_picker.dart';

/// Shared portion interactions (complete, undo, details, reading plan) so the
/// Today and Journey screens behave identically.
class PortionActions {
  PortionActions._();

  /// Marks a portion complete immediately, with a countdown undo toast as the
  /// safety net (no extra confirmation step).
  static Future<void> markCompleted(
    BuildContext context,
    WidgetRef ref,
    int dayNumber,
  ) async {
    final notifier = ref.read(challengeStateProvider.notifier);
    await notifier.markDayCompleted(dayNumber);
    if (!context.mounted) return;
    CountdownUndoToast.show(
      context,
      message:
          '${LocaleKeys.common.alhamdulillah.tr()} • ${LocaleKeys.common.day_number.tr(args: [dayNumber.toString()])} ${LocaleKeys.common.completed.tr()}',
      undoLabel: LocaleKeys.confirmation.undo_action.tr(),
      onUndo: () => notifier.undoDayCompletion(dayNumber),
    );
  }

  /// Asks for confirmation, then undoes a completed portion.
  static Future<void> confirmUndo(
    BuildContext context,
    WidgetRef ref,
    int dayNumber,
  ) async {
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: LocaleKeys.confirmation.undo_title.tr(),
      message: LocaleKeys.confirmation.undo_desc.tr(),
      confirmLabel: LocaleKeys.confirmation.undo_confirm.tr(),
      cancelLabel: LocaleKeys.common.cancel.tr(),
      isDestructive: true,
      icon: Icons.undo_rounded,
    );
    if (confirmed && context.mounted) {
      await ref.read(challengeStateProvider.notifier).undoDayCompletion(dayNumber);
    }
  }

  /// Ticks / unticks one part of a day's reading plan. Ticking the last part
  /// completes the day (with undo), so finishing needs no extra step.
  /// [sheetContext] is closed first when the toggle happens inside a sheet.
  static Future<void> toggleReadingPart(
    BuildContext context,
    WidgetRef ref,
    int dayNumber,
    int partIndex, {
    BuildContext? sheetContext,
  }) async {
    final challenge = ref.read(challengeStateProvider).challenge;
    if (challenge == null) return;
    DayPortion? portion;
    for (final p in challenge.portions) {
      if (p.dayNumber == dayNumber) portion = p;
    }
    if (portion == null || portion.isCompleted) return;

    final next = portion.readParts.toSet();
    if (!next.remove(partIndex)) next.add(partIndex);
    await ref
        .read(challengeStateProvider.notifier)
        .setReadParts(dayNumber, next.toList()..sort());

    final allRead = next.length >= portion.parts.length;
    if (allRead && challenge.canMarkCompleted(portion)) {
      if (sheetContext != null && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
      if (context.mounted) await markCompleted(context, ref, dayNumber);
    }
  }

  /// Opens the day detail sheet. Editing is only offered for the active
  /// challenge; archived cycles are read-only.
  static Future<void> showDetail(
    BuildContext context,
    WidgetRef ref, {
    required Challenge challenge,
    required DayPortion portion,
  }) {
    final active = ref.read(challengeStateProvider).challenge;
    final editable = active != null && active.id == challenge.id;
    final day = challenge.currentDayNumber;
    final displayDay = challenge.isActive
        ? day
        : (challenge.isUpcoming ? 0 : 99);
    final canTrack = editable && challenge.canMarkCompleted(portion);
    final planOn = ref.read(challengeStateProvider).isReadingPlanOn;

    return DayDetailSheet.show(
      context,
      portion: portion,
      portionDate: challenge.dateForDay(portion.dayNumber),
      currentDayNumber: displayDay,
      canMarkToday: editable && challenge.canMarkCompleted(portion),
      allowLateCheckIn: editable && challenge.canLateCheckIn(portion),
      allowUndo: editable && portion.isCompleted && day <= 7,
      rescheduledToDay: challenge.rescheduledToDay(portion),
      showReadingPlan: planOn,
      readingPlan: canTrack
          ? Consumer(
              builder: (sheetContext, sheetRef, _) {
                // Rebuild with live progress as parts are ticked in the sheet
                // (and when the plan is changed or turned off from its header).
                if (!sheetRef.watch(challengeStateProvider).isReadingPlanOn) {
                  return const SizedBox.shrink();
                }
                var live = portion;
                final current = sheetRef.watch(challengeStateProvider).challenge;
                for (final p in current?.portions ?? const <DayPortion>[]) {
                  if (p.dayNumber == portion.dayNumber) live = p;
                }
                return ReadingPlan(
                  portion: live,
                  onToggle: (index) => toggleReadingPart(
                    context,
                    ref,
                    portion.dayNumber,
                    index,
                    sheetContext: sheetContext,
                  ),
                  onCustomize: () =>
                      ReadingPlanPicker.showForDay(sheetContext, ref, live),
                );
              },
            )
          : null,
      onToggleCompletion: () {
        if (portion.isCompleted) {
          confirmUndo(context, ref, portion.dayNumber);
        } else {
          markCompleted(context, ref, portion.dayNumber);
        }
      },
    );
  }
}
