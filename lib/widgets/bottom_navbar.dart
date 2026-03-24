import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Color _color(int index) {
    return currentIndex == index ? Colors.blue : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: _color(0)),
              onPressed: () => onTap(0),
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: _color(1)),
              onPressed: () => onTap(1),
            ),
            IconButton(
              icon: Icon(Icons.person, color: _color(2)),
              onPressed: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}