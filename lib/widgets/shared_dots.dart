import 'package:flutter/material.dart';

class SharedDotsIndicator extends StatelessWidget {
  final int currentIndex; // 0 = Onboarding1, 1 = Onboarding2
  const SharedDotsIndicator({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Directionality( // نخليها LTR بس للمؤشر
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(currentIndex == 0),
          const SizedBox(width: 6),
          _dot(currentIndex == 1),
        ],
      ),
    );
  }

  Widget _dot(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    width: active ? 22 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: active ? const Color(0xFFFACC15) : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
