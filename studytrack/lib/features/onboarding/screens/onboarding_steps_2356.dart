import 'package:flutter/material.dart';

import 'onboarding_step2_screen.dart';
import 'onboarding_step3_screen.dart';
import 'onboarding_step5_screen.dart';
import 'onboarding_step6_screen.dart';

class OnboardingSteps2356Screen extends StatefulWidget {
  const OnboardingSteps2356Screen({super.key});

  @override
  State<OnboardingSteps2356Screen> createState() =>
      _OnboardingSteps2356ScreenState();
}

class _OnboardingSteps2356ScreenState extends State<OnboardingSteps2356Screen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      OnboardingStep2Screen(),
      OnboardingStep3Screen(),
      OnboardingStep5Screen(),
      OnboardingStep6Screen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: steps.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => steps[index],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            right: 14,
            child: Row(
              children: [
                Text(
                  '${_index + 1}/${steps.length}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _index < steps.length - 1
                      ? () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
