import 'package:espn_app/widgets/league_selector.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({required this.url, super.key});

  final String url;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(6.0),
            child: SizedBox(
              child: CircleAvatar(backgroundImage: NetworkImage(widget.url)),
            ),
          ),
          title: const NavigationDot(),
          actions: [
            IconButton(
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0, // Rotation de 180°
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_double_arrow_down),
              ),
              onPressed: _toggleExpansion,
            ),
          ],
        ),
        // Transition fluide avec SlideTransition
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
