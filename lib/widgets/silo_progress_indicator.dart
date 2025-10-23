import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

enum SiloProgressState {
  idle,
  scanning,
  completed,
  disconnected,
  retry,
}

class SiloProgressIndicator extends StatefulWidget {
  final int siloNumber;
  final SiloProgressState state;
  final double progress; // 0.0 to 1.0
  final Color? siloColor;
  final bool isSquare;
  final VoidCallback? onTap;

  const SiloProgressIndicator({
    super.key,
    required this.siloNumber,
    required this.state,
    this.progress = 0.0,
    this.siloColor,
    this.isSquare = false,
    this.onTap,
  });

  @override
  State<SiloProgressIndicator> createState() => _SiloProgressIndicatorState();
}

class _SiloProgressIndicatorState extends State<SiloProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Pulse animation for scanning state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for progress indicator
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _updateAnimations();
  }

  void _updateAnimations() {
    switch (widget.state) {
      case SiloProgressState.scanning:
      case SiloProgressState.retry:
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
        break;
      case SiloProgressState.completed:
        _pulseController.stop();
        _rotationController.stop();
        break;
      case SiloProgressState.disconnected:
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case SiloProgressState.idle:
      default:
        _pulseController.stop();
        _rotationController.stop();
        break;
    }
  }

  @override
  void didUpdateWidget(SiloProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  Color _getSiloColor() {
    switch (widget.state) {
      case SiloProgressState.scanning:
        return Colors.blue;
      case SiloProgressState.retry:
        return Colors.orange;
      case SiloProgressState.completed:
        return Colors.green;
      case SiloProgressState.disconnected:
        return Colors.red;
      case SiloProgressState.idle:
      default:
        return widget.siloColor ?? const Color(0xFFF6E2A1);
    }
  }

  Color _getProgressColor() {
    switch (widget.state) {
      case SiloProgressState.scanning:
        return Colors.blue.shade300;
      case SiloProgressState.retry:
        return Colors.orange.shade300;
      case SiloProgressState.completed:
        return Colors.green.shade300;
      case SiloProgressState.disconnected:
        return Colors.red.shade300;
      case SiloProgressState.idle:
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildProgressRing() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(
              widget.isSquare ? 35.w : 50.w,
              widget.isSquare ? 35.w : 50.w,
            ),
            painter: CircularProgressPainter(
              progress: widget.progress,
              progressColor: _getProgressColor(),
              backgroundColor: Colors.grey.shade200,
              strokeWidth: 3.0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiloIcon() {
    Widget icon;
    
    switch (widget.state) {
      case SiloProgressState.completed:
        // Show silo number for completed silos (not check icon)
        icon = Text(
          widget.siloNumber.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: Colors.white,
          ),
        );
        break;
      case SiloProgressState.disconnected:
        icon = Icon(
          Icons.error,
          color: Colors.white,
          size: 16.sp,
        );
        break;
      case SiloProgressState.scanning:
      case SiloProgressState.retry:
        // Show silo number during scanning (like React implementation)
        icon = Text(
          widget.siloNumber.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: Colors.white,
          ),
        );
        break;
      case SiloProgressState.idle:
        icon = Text(
          widget.siloNumber.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: Colors.black87,
          ),
        );
        break;
    }

    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.state == SiloProgressState.scanning ||
                   widget.state == SiloProgressState.retry ||
                   widget.state == SiloProgressState.disconnected
                ? _pulseAnimation.value
                : 1.0,
            child: Container(
              margin: EdgeInsets.all(4.w),
              width: widget.isSquare ? 35.w : 50.w,
              height: widget.isSquare ? 35.w : 50.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring (only show when scanning or in retry)
                  if (widget.state == SiloProgressState.scanning ||
                      widget.state == SiloProgressState.retry)
                    _buildProgressRing(),
                  
                  // Main silo container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: widget.isSquare ? 30.w : 45.w,
                    height: widget.isSquare ? 30.w : 45.w,
                    decoration: BoxDecoration(
                      color: _getSiloColor(),
                      borderRadius: widget.isSquare 
                          ? BorderRadius.circular(6.r) 
                          : BorderRadius.circular(22.5.w), // Make circular for round silos
                      border: widget.state == SiloProgressState.completed
                          ? Border.all(color: Colors.green.shade700, width: 2)
                          : widget.state == SiloProgressState.disconnected
                              ? Border.all(color: Colors.red.shade700, width: 2)
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: _getSiloColor().withOpacity(0.4),
                          blurRadius: widget.state == SiloProgressState.scanning ||
                                     widget.state == SiloProgressState.retry
                              ? 8
                              : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(child: _buildSiloIcon()),
                  ),
                  
                  // Status indicator dot
                  if (widget.state != SiloProgressState.idle)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: widget.state == SiloProgressState.completed
                              ? Colors.green
                              : widget.state == SiloProgressState.disconnected
                                  ? Colors.red
                                  : widget.state == SiloProgressState.retry
                                      ? Colors.orange
                                      : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
