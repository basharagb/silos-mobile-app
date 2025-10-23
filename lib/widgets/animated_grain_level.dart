import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../services/api_service.dart';

class AnimatedGrainLevel extends StatefulWidget {
  final int selectedSilo;
  final bool isReading;
  final VoidCallback? onRefresh;

  const AnimatedGrainLevel({
    super.key,
    required this.selectedSilo,
    this.isReading = false,
    this.onRefresh,
  });

  @override
  State<AnimatedGrainLevel> createState() => _AnimatedGrainLevelState();
}

class _AnimatedGrainLevelState extends State<AnimatedGrainLevel>
    with TickerProviderStateMixin {
  double? _fillPercent;
  bool _isLoading = false;
  int _pouringLevel = 0;
  bool _isPouring = false;
  Timer? _pouringTimer;
  Timer? _refreshTimer;

  late AnimationController _pouringController;
  late Animation<double> _pouringAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchLevelData();
    _startPeriodicRefresh();
  }

  @override
  void didUpdateWidget(AnimatedGrainLevel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSilo != widget.selectedSilo) {
      _fetchLevelData();
    }
    if (oldWidget.isReading != widget.isReading) {
      if (widget.isReading) {
        _startPouringAnimation();
      } else {
        _stopPouringAnimation();
      }
    }
  }

  void _initAnimations() {
    _pouringController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pouringAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pouringController,
      curve: Curves.easeInOut,
    ));

    _pouringController.repeat(reverse: true);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !widget.isReading) {
        _fetchLevelData();
      }
    });
  }

  Future<void> _fetchLevelData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final level = await ApiService.getSiloLevelEstimate(widget.selectedSilo);
      if (mounted) {
        setState(() {
          _fillPercent = level;
          _isLoading = false;
          if (!widget.isReading) {
            // Update pouring level based on fill percent when not reading
            _pouringLevel = _getLevelsFromFillPercent(level ?? 0.0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getLevelsFromFillPercent(double fillPercent) {
    if (fillPercent >= 100) return 8;
    return (fillPercent / 12.5).floor().clamp(0, 8);
  }

  void _startPouringAnimation() {
    setState(() {
      _isPouring = true;
      _pouringLevel = 0;
    });

    _pouringTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted || !widget.isReading) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_pouringLevel >= 8) {
          _pouringLevel = 8;
          _isPouring = false;
          timer.cancel();
        } else {
          _pouringLevel++;
        }
      });
    });
  }

  void _stopPouringAnimation() {
    _pouringTimer?.cancel();
    setState(() {
      _isPouring = false;
      _pouringLevel = _getLevelsFromFillPercent(_fillPercent ?? 0.0);
    });
  }

  // Get level color matching React implementation
  Color _getLevelColor(int levelIndex, bool isFilled, bool isPouringLevel) {
    if (widget.isReading && isPouringLevel) {
      return const Color(0xFFFFC107); // Yellow for pouring (temp-yellow)
    } else if (isFilled) {
      return const Color(0xFFFFC107); // Yellow for filled levels
    } else {
      return Colors.grey.shade200; // Gray for empty levels
    }
  }

  // Get gradient for level background (matching React CSS gradients)
  LinearGradient _getLevelGradient(int levelIndex, bool isFilled, bool isPouringLevel) {
    if (widget.isReading && isPouringLevel) {
      // Animated pouring gradient (matching React yellow gradient)
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFC107), Color(0xFFe0a800)], // temp-yellow gradient
      );
    } else if (isFilled) {
      // Filled level gradient
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFC107), Color(0xFFe0a800)], // temp-yellow gradient
      );
    } else {
      // Empty level - light gray
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade200, Colors.grey.shade300],
      );
    }
  }

  @override
  void dispose() {
    _pouringController.dispose();
    _pouringTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Grain Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (widget.isReading)
                    AnimatedBuilder(
                      animation: _pouringAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + (_pouringAnimation.value * 0.4),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'FILLING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              // Refresh button
              GestureDetector(
                onTap: () {
                  _fetchLevelData();
                  widget.onRefresh?.call();
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 20.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Silo info and fill percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Silo ${widget.selectedSilo}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  _fillPercent != null 
                      ? 'Fill: ${_fillPercent!.toStringAsFixed(1)}%'
                      : 'Fill: ---%',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Level indicator
          Text(
            widget.isReading 
                ? 'Level: $_pouringLevel/8'
                : 'Level: ${_getLevelsFromFillPercent(_fillPercent ?? 0.0)}/8',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: widget.isReading ? Colors.blue : Colors.grey.shade700,
            ),
          ),

          SizedBox(height: 16.h),

          // Animated grain level cylinder
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(),
              ),
            )
          else
            _buildAnimatedGrainCylinder(),
        ],
      ),
    );
  }

  Widget _buildAnimatedGrainCylinder() {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        children: [
          // Levels (L8 to L1, top to bottom)
          Expanded(
            child: Column(
              children: List.generate(8, (index) {
                final levelNumber = 8 - index; // L8 at top, L1 at bottom
                final levelIndex = levelNumber - 1;
                final isFilled = levelIndex < _pouringLevel;
                final isPouringLevel = _isPouring && levelIndex == _pouringLevel - 1;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      gradient: _getLevelGradient(levelIndex, isFilled, isPouringLevel),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Level label
                        Center(
                          child: Text(
                            'L$levelNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: isFilled ? const Color(0xFF92400e) : Colors.grey.shade600, // yellow-900 equivalent
                            ),
                          ),
                        ),
                        // Pouring animation (matching React implementation)
                        if (isPouringLevel)
                          AnimatedBuilder(
                            animation: _pouringAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFFFDE047).withOpacity(_pouringAnimation.value), // yellow-300
                                      const Color(0xFFFFC107).withOpacity(_pouringAnimation.value), // yellow-400
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Center(
                                  child: Text(
                                    'L$levelNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                      color: const Color(0xFF92400e), // yellow-900 equivalent
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        // Blue overlay for reading state (matching React bg-blue-100 bg-opacity-20)
                        if (widget.isReading && isFilled && !isPouringLevel)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFdbeafe).withOpacity(0.2), // bg-blue-100 equivalent
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
