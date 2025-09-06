import 'dart:async';
import 'package:flutter/material.dart';
import './wrapper.dart';
import 'package:wetherapp/golden_border_painter.dart'; // New import

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  late AnimationController _glossyController; // New controller for glossy effect
  late Animation<double> _glossyAnimation; // New animation for glossy effect

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500), // Shake animation duration
      vsync: this,
    )..repeat(reverse: true); // Repeat and reverse for continuous shake

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0), // Shake horizontally by a small amount
    ).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut, // Smooth shake
      ),
    );

    

    // Initialize glossy effect animation
    _glossyController = AnimationController(
      duration: const Duration(seconds: 2), // Duration for one full cycle of the glossy effect
      vsync: this,
    )..repeat(); // Repeat indefinitely

    _glossyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glossyController,
        curve: Curves.linear, // Linear movement for the glossy effect
      ),
    );

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => Wrapper(),
      ));
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glossyController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _shakeAnimation.value,
                child: Stack( // Wrap with Stack
                  children: [
                    Image.asset('assets/images/splash.png', fit: BoxFit.cover),
                    Positioned.fill( // Position the CustomPaint to fill the image area
                      child: AnimatedBuilder(
                        animation: _glossyAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: GoldenBorderPainter(
                              animationValue: _glossyAnimation.value,
                              borderRadius: 16.0, // Match the assumed border radius
                              borderWidth: 5.0, // Match the assumed border width
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}