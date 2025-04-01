import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationDots extends ConsumerWidget {
  const NavigationDots({super.key});

  static const double _baseDotSize = 7.0;
  static const double _selectedDotSize = 10.0;
  static const double _dotHorizontalMargin = 5.0;
  static const int _animationDurationMs = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    final theme = Theme.of(context);
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = theme.colorScheme.primary.withValues(
      alpha: 0.4,
    );

    return SizedBox(
      width: 160,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final bool isSelected = index == pageIndex;

            final double dotSize = isSelected ? _selectedDotSize : _baseDotSize;
            final Color dotColor = isSelected ? activeColor : inactiveColor;

            return GestureDetector(
              onTap: () {
                final pageController = ref.read(pageControllerProvider);
                if (pageController != null && pageController.hasClients) {
                  pageController.animateToPage(
                    index,
                    duration: const Duration(
                      milliseconds: _animationDurationMs,
                    ),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: _animationDurationMs),
                margin: const EdgeInsets.symmetric(
                  horizontal: _dotHorizontalMargin,
                ),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ]
                          : [],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
