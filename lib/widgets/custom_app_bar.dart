import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets.dart';

class CustomAppBar extends ConsumerStatefulWidget {
  const CustomAppBar({
    required this.url,
    this.backgroundColor,
    this.onArrowButtonPressed,
    this.iconOrientation = 0, // Parameter for icon orientation
    super.key,
  });

  final String url;
  final Color? backgroundColor;
  final VoidCallback? onArrowButtonPressed;
  final int iconOrientation; // 0: up, 1: right, 2: down, 3: left

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
      begin: const Offset(0, -1), // Start hidden above
      end: const Offset(0, 0), // End at normal position
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _toggleExpansion() {
    // If custom function is provided, use it instead
    if (widget.onArrowButtonPressed != null) {
      widget.onArrowButtonPressed!();
      return;
    }

    // Default behavior - toggle league selector
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

  // Helper method to get the icon based on orientation
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
        return Icons.keyboard_double_arrow_down; // Default fallback
    }
  }

  // Helper method to get the appropriate rotation values based on expanded state and orientation
  double _getRotationValue() {
    if (!isExpanded) return 0;

    // When expanded, rotate to the opposite direction (180 degrees)
    switch (widget.iconOrientation) {
      case 0:
        return 0.5; // Up to Down (0.5 turns = 180 degrees)
      case 1:
        return 0.5; // Right to Left (0.5 turns = 180 degrees)
      case 2:
        return 0.5; // Down to Up (0.5 turns = 180 degrees)
      case 3:
        return 0.5; // Left to Right (0.5 turns = 180 degrees)
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
          // Utilisation du widget NavigationDots isolé
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
        // Only show this if no custom function is provided
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
