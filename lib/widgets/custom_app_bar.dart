import 'package:espn_app/widgets/league_selector.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({
    required this.url,
    this.backgroundColor,
    this.onArrowButtonPressed,
    this.iconOrientation = 0, // New parameter for icon orientation
    super.key,
  });

  final String url;
  final Color? backgroundColor;
  final VoidCallback? onArrowButtonPressed;
  final int iconOrientation; // 0: up, 1: right, 2: down, 3: left

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
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
      begin: const Offset(0, -1), // Commence caché au-dessus
      end: const Offset(0, 0), // Arrive à sa position normale
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
      _animationController.reverse().then((_) {
        setState(() {
          isExpanded = false;
        });
      });
    } else {
      setState(() {
        isExpanded = true;
      });
      _animationController.forward();
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
          title: const NavigationDot(),
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

class NavigationDot extends StatefulWidget {
  const NavigationDot({super.key});

  @override
  State<NavigationDot> createState() => _NavigationDotState();
}

class _NavigationDotState extends State<NavigationDot> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        bool isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 7 : 5,
            height: isSelected ? 7 : 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isSelected ? 255 : 128),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
