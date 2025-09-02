import 'dart:async';
import 'package:flutter/material.dart';
import './wrapper.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

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

    _scaleController = AnimationController(
      duration: const Duration(seconds: 1), // Scale animation duration
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut, // Smooth scale out
      ),
    );

    _scaleController.forward(); // Start the scale animation

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => Wrapper(),
      ));
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _shakeAnimation.value,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}