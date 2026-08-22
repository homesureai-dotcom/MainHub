
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../data/onboarding_data.dart';
import '../../widgets/onboarding/onboarding_page_widget.dart';
import 'how_it_works_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  final PageController _controller = PageController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(

        child: Column(

          children: [

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: TextButton(
                  onPressed: () {

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HowItWorksScreen(),
                      ),
                    );

                  },
                  child: const Text("Skip"),
                ),
              ),
            ),

            Expanded(

              child: PageView.builder(

                controller: _controller,

                itemCount: onboardingPages.length,

                onPageChanged: (index) {

                  setState(() {

                    currentPage = index;

                  });

                },

                itemBuilder: (_, index) {

                  return OnboardingPageWidget(
                    page: onboardingPages[index],
                  );

                },

              ),

            ),

            SmoothPageIndicator(

              controller: _controller,

              count: onboardingPages.length,

              effect: const ExpandingDotsEffect(
                dotHeight: 10,
                dotWidth: 10,
                expansionFactor: 4,
              ),

            ),

            const SizedBox(height: 40),

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: SizedBox(

                width: double.infinity,

                height: 56,

                child: FilledButton(

                  onPressed: () {

                    if (currentPage == onboardingPages.length - 1) {

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HowItWorksScreen(),
                        ),
                      );

                    } else {

                      _controller.nextPage(

                        duration: const Duration(milliseconds: 400),

                        curve: Curves.easeInOut,

                      );

                    }

                  },

                  child: Text(
                    currentPage == onboardingPages.length - 1
                        ? "Get Started"
                        : "Next",
                  ),

                ),

              ),

            ),

            const SizedBox(height: 30),

          ],

        ),

      ),

    );

  }

}