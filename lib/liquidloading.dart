import 'package:flutter/material.dart';
import 'dart:math' as math;


class LiquidButtonDemo extends StatefulWidget {
  @override
  _LiquidButtonDemoState createState() => _LiquidButtonDemoState();
}

class _LiquidButtonDemoState extends State<LiquidButtonDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Liquid Loading Buttons',
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 60),
            LiquidLoadingButton(
              text: 'Download',
              icon: Icons.download,
              color: Colors.cyan,
              onPressed: () {
                print('Download pressed!');
              },
            ),
            SizedBox(height: 40),
            LiquidLoadingButton(
              text: 'Upload',
              icon: Icons.upload,
              color: Colors.pink,
              onPressed: () {
                print('Upload pressed!');
              },
            ),
            SizedBox(height: 40),
            LiquidLoadingButton(
              text: 'Submit',
              icon: Icons.send,
              color: Colors.orange,
              width: 200,
              onPressed: () {
                print('Submit pressed!');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidLoadingButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const LiquidLoadingButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.width = 160,
    this.height = 50,
  }) : super(key: key);

  @override
  _LiquidLoadingButtonState createState() => _LiquidLoadingButtonState();
}

class _LiquidLoadingButtonState extends State<LiquidLoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _liquidController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  late Animation<double> _liquidAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _liquidController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _liquidAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _liquidController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _waveController.repeat();
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _scaleController.forward();
    await _liquidController.forward();

    // Simulate some work
    await Future.delayed(Duration(milliseconds: 500));

    // Reset
    await _liquidController.reverse();
    _scaleController.reverse();

    setState(() {
      _isLoading = false;
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _liquidAnimation,
          _scaleAnimation,
          _waveAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              child: CustomPaint(
                painter: LiquidButtonPainter(
                  progress: _liquidAnimation.value,
                  wavePhase: _waveAnimation.value,
                  color: widget.color,
                  isLoading: _isLoading,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LiquidButtonPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;
  final bool isLoading;

  LiquidButtonPainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.isLoading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Background (border)
    paint.color = color.withOpacity(0.3);
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(25),
    );
    canvas.drawRRect(borderRect, paint);

    // Liquid fill
    if (progress > 0) {
      final clipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(25),
      );
      canvas.clipRRect(clipRect);

      // Create liquid wave path
      final path = Path();
      final waveHeight = 3.0;
      final fillHeight = size.height * progress;

      path.moveTo(0, size.height);

      // Create wave effect
      for (double x = 0; x <= size.width; x += 2) {
        final waveY = size.height - fillHeight +
            waveHeight * math.sin((x / size.width * 4 * math.pi) + wavePhase);
        path.lineTo(x, waveY);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      // Gradient for liquid effect
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.8),
          color,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }

    // Border
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = color;
    canvas.drawRRect(borderRect, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidButtonPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isLoading != isLoading;
  }
}