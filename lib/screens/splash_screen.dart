import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _scaleXAnimation;
  late Animation<double> _scaleYAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _shockwaveScale;
  late Animation<double> _shockwaveOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1. Chute (0.0 -> 0.2)
    _dropAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: -800.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 80),
    ]).animate(_controller);

    // 2. Squash & Stretch X
    _scaleXAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 0.8).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.5).chain(CurveTween(curve: Curves.easeOut)), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 35),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);

    // 3. Squash & Stretch Y
    _scaleYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 2.0, end: 1.2).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.5).chain(CurveTween(curve: Curves.easeOut)), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 35),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);

    // 4. Onde de choc à l'impact (0.2 -> 0.4)
    _shockwaveScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 10.0).chain(CurveTween(curve: Curves.easeOutQuart)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(10.0), weight: 60),
    ]).animate(_controller);

    _shockwaveOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
    ]).animate(_controller);

    // 5. Rotation Z shuriken (0.7 -> 1.0)
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: math.pi * 4).chain(CurveTween(curve: Curves.easeInExpo)), weight: 30),
    ]).animate(_controller);

    // 6. Zoom massif (0.7 -> 1.0)
    _zoomAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 70),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 50.0).chain(CurveTween(curve: Curves.easeInExpo)), weight: 30),
    ]).animate(_controller);

    // 7. Opacité finale
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 90),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    ]).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.logoBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Onde de choc
                if (_shockwaveOpacity.value > 0)
                  Transform.scale(
                    scale: _shockwaveScale.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.textPrimary.withOpacity(_shockwaveOpacity.value),
                          width: 4,
                        ),
                      ),
                    ),
                  ),

                // Logo principal
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _dropAnimation.value),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(_rotationAnimation.value)
                        ..scale(
                          _scaleXAnimation.value * _zoomAnimation.value,
                          _scaleYAnimation.value * _zoomAnimation.value,
                        ),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          child: SvgPicture.asset(
            'assets/images/STAS_LOGOMACA1_VECT.svg',
            width: 250,
            height: 250,
          ),
        ),
      ),
    );
  }
}
