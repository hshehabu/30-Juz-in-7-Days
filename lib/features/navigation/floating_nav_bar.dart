import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class FloatingNavItem {
  final IconData icon;
  final String label;

  const FloatingNavItem({required this.icon, required this.label});
}

/// A floating capsule navigation bar with a highlight that slides to the
/// selected tab. Direction-aware, so it mirrors correctly in Arabic.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _height = 64;
  static const double _inset = 5;
  static const Duration _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    final x = count <= 1 ? 0.0 : -1.0 + 2.0 * currentIndex / (count - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(color: AppColors.mistGray),
            boxShadow: [
              BoxShadow(
                color: AppColors.dustyGreenDark.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(_inset),
          child: Stack(
            children: [
              // Sliding highlight behind the selected item.
              AnimatedAlign(
                alignment: AlignmentDirectional(x, 0),
                duration: _duration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryNeutral,
                      borderRadius:
                          BorderRadius.circular((_height - _inset * 2) / 2),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () {
                          if (i != currentIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onTap(i);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.dustyGreenDark : AppColors.secondaryText;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: FloatingNavBar._duration,
                builder: (_, c, _) => Icon(item.icon, size: 22, color: c),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: FloatingNavBar._duration,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                  child: Text(item.label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
