import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets.dart';

class CustomAppBar extends ConsumerStatefulWidget {
  const CustomAppBar({
    required this.url,
    this.backgroundColor,
    this.onArrowButtonPressed,
    this.iconOrientation = 0,
    super.key,
  });

  final String url;
  final Color? backgroundColor;
  final VoidCallback? onArrowButtonPressed;
  final int iconOrientation;

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _toggleExpansion() {
    if (widget.onArrowButtonPressed != null) {
      widget.onArrowButtonPressed!();
      return;
    }

    if (isExpanded) {
      _animationController.reverse();
      setState(() {
        isExpanded = false;
        ref.read(leagueSelectorVisibilityProvider.notifier).closeNavBar();
      });
    } else {
      setState(() {
        isExpanded = true;
      });
      _animationController.forward();
      setState(() {
        ref.read(leagueSelectorVisibilityProvider.notifier).openNavBar();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getOrientedIcon() {
    switch (widget.iconOrientation) {
      case 0:
        return Icons.keyboard_double_arrow_up;
      case 1:
        return Icons.keyboard_double_arrow_right;
      case 2:
        return Icons.keyboard_double_arrow_down;
      case 3:
        return Icons.keyboard_double_arrow_left;
      default:
        return Icons.keyboard_double_arrow_down;
    }
  }

  double _getRotationValue() {
    if (!isExpanded) return 0;

    switch (widget.iconOrientation) {
      case 0:
        return 0.5;
      case 1:
        return 0.5;
      case 2:
        return 0.5;
      case 3:
        return 0.5;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        AppBar(
          backgroundColor: widget.backgroundColor,
          leading: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: Center(
                child: Image.network(
                  widget.url,
                  width: 35,
                  height: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: const NavigationDots(),
          actions: [
            IconButton(
              icon: AnimatedRotation(
                turns: _getRotationValue(),
                duration: const Duration(milliseconds: 300),
                child: Icon(_getOrientedIcon()),
              ),
              onPressed: _toggleExpansion,
            ),
          ],
        ),
        if (widget.onArrowButtonPressed == null)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ClipRect(
              child: Align(
                heightFactor: isExpanded ? 1.0 : 0.0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const LeagueSelector(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
