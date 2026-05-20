import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveformAnimation extends StatefulWidget {
  final bool isRecording;
  final Color activeColor;

  const WaveformAnimation({
    super.key,
    required this.isRecording,
    this.activeColor = Colors.redAccent,
  });

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic_none_rounded,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric pulsing rings
              ...List.generate(3, (index) {
                final double delay = index * 0.33;
                double progress = _controller.value + delay;
                if (progress > 1.0) progress -= 1.0;

                final double scale = 0.4 + (progress * 0.6);
                final double opacity = math.max(0.0, 1.0 - progress);

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity * 0.6,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.activeColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Bouncing wave bars at the bottom/middle
              Positioned(
                bottom: 10,
                child: SizedBox(
                  width: 160,
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(9, (index) {
                      // Calculate height based on sine waves with index offsets
                      final double phase = _controller.value * 2 * math.pi;
                      final double indexFactor = (index - 4).abs() * 0.4;
                      final double val = math.sin(phase - (index * 0.5));
                      final double heightMultiplier = (math.cos(indexFactor) + 1.2) * 12;
                      final double height = 4 + (val.abs() * heightMultiplier);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Recording center dot icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
