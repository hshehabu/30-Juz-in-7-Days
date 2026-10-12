import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Floating toast with a real-time countdown timer and an Undo action.
class CountdownUndoToast {
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
    String undoLabel = 'Undo',
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: _CountdownToastContent(
          message: message,
          duration: duration,
          undoLabel: undoLabel,
          onUndo: () {
            messenger.hideCurrentSnackBar();
            onUndo();
          },
        ),
      ),
    );
  }
}

class _CountdownToastContent extends StatefulWidget {
  final String message;
  final Duration duration;
  final String undoLabel;
  final VoidCallback onUndo;

  const _CountdownToastContent({
    required this.message,
    required this.duration,
    required this.undoLabel,
    required this.onUndo,
  });

  @override
  State<_CountdownToastContent> createState() => _CountdownToastContentState();
}

class _CountdownToastContentState extends State<_CountdownToastContent> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(
          color: AppColors.dustyGreen.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkmark Icon
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.dustyGreen,
            size: 20,
          ),
          const SizedBox(width: 12),

          // Message
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),

          // Undo button with active countdown badge
          GestureDetector(
            key: const ValueKey('countdown_undo_button'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.onUndo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.undo_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.undoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.dustyGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${_remainingSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
