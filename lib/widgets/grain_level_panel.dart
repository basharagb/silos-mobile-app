import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class GrainLevelPanel extends StatefulWidget {
  final int selectedSilo;
  final bool isReading;
  final VoidCallback? onRefresh;

  const GrainLevelPanel({
    super.key,
    required this.selectedSilo,
    this.isReading = false,
    this.onRefresh,
  });

  @override
  State<GrainLevelPanel> createState() => _GrainLevelPanelState();
}

class _GrainLevelPanelState extends State<GrainLevelPanel>
    with TickerProviderStateMixin {
  double? _fillPercent;
  bool _isLoading = false;
  late AnimationController _fillController;
  late AnimationController _pouringController;
  late Animation<double> _fillAnimation;
  late Animation<double> _pouringAnimation;
  int _currentLevel = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchLevelData();
  }

  @override
  void didUpdateWidget(GrainLevelPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSilo != widget.selectedSilo) {
      _fetchLevelData();
    }
    if (oldWidget.isReading != widget.isReading && widget.isReading) {
      _startPouringAnimation();
    }
  }

  void _initAnimations() {
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pouringController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));

    _pouringAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pouringController,
      curve: Curves.easeInOut,
    ));

    _pouringController.repeat(reverse: true);
  }

  void _startPouringAnimation() {
    setState(() {
      _currentLevel = 0;
    });
    
    // Animate filling levels during reading
    for (int i = 0; i <= 8; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted && widget.isReading) {
          setState(() {
            _currentLevel = i;
          });
        }
      });
    }
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
          // Calculate current level from fill percent
          if (level != null) {
            _currentLevel = (level / 12.5).floor().clamp(0, 8);
            _fillController.forward();
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

  Color _getLevelColor(int levelIndex, bool isFilled, bool isPouring) {
    if (widget.isReading && isPouring) {
      return Colors.yellow.shade600;
    } else if (isFilled) {
      return Colors.yellow.shade400;
    } else {
      return Colors.grey.shade200;
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _pouringController.dispose();
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
                ? 'Level: $_currentLevel/8'
                : 'Level: ${(_fillPercent != null ? (_fillPercent! / 12.5).floor().clamp(0, 8) : 0)}/8',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: widget.isReading ? Colors.blue : Colors.grey.shade700,
            ),
          ),

          SizedBox(height: 16.h),

          // Grain level cylinder
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(),
              ),
            )
          else
            _buildGrainCylinder(),
        ],
      ),
    );
  }

  Widget _buildGrainCylinder() {
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
                final isFilled = widget.isReading 
                    ? levelIndex < _currentLevel
                    : levelIndex < ((_fillPercent ?? 0) / 12.5).floor().clamp(0, 8);
                final isPouring = widget.isReading && levelIndex == _currentLevel - 1;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _getLevelColor(levelIndex, isFilled, isPouring),
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
                              color: isFilled ? Colors.yellow.shade900 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        // Pouring animation
                        if (isPouring)
                          AnimatedBuilder(
                            animation: _pouringAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.yellow.shade300.withOpacity(_pouringAnimation.value),
                                      Colors.yellow.shade600.withOpacity(_pouringAnimation.value),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              );
                            },
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
