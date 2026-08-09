import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/exercise.dart';
import '../../domain/exercise_catalog.dart';
import '../../domain/repdb_exercise_mapping.dart';

class ExerciseMediaView extends StatefulWidget {
  const ExerciseMediaView({
    super.key,
    required this.exercise,
    this.fit = BoxFit.contain,
    this.showPoseLabel = false,
    this.placeholderBuilder,
    this.poseDuration = const Duration(milliseconds: 1400),
    this.transitionDuration = const Duration(milliseconds: 420),
  });

  final Exercise exercise;
  final BoxFit fit;
  final bool showPoseLabel;
  final WidgetBuilder? placeholderBuilder;
  final Duration poseDuration;
  final Duration transitionDuration;

  @override
  State<ExerciseMediaView> createState() => _ExerciseMediaViewState();
}

class _ExerciseMediaViewState extends State<ExerciseMediaView> {
  Timer? _poseTimer;
  bool _showPeak = false;
  bool _animationsEnabled = true;

  RepDbExerciseMedia? get _repDbMedia =>
      ExerciseCatalog.repDbMediaFor(widget.exercise);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (_animationsEnabled != enabled || _poseTimer == null) {
      _animationsEnabled = enabled;
      _syncPoseTimer();
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id ||
        oldWidget.exercise.name != widget.exercise.name ||
        oldWidget.poseDuration != widget.poseDuration) {
      _showPeak = false;
      _syncPoseTimer();
    }
  }

  @override
  void dispose() {
    _poseTimer?.cancel();
    super.dispose();
  }

  void _syncPoseTimer() {
    _poseTimer?.cancel();
    _poseTimer = null;

    if (!_animationsEnabled || _repDbMedia?.hasPosePair != true) {
      _showPeak = false;
      return;
    }

    _poseTimer = Timer.periodic(widget.poseDuration, (_) {
      if (mounted) {
        setState(() => _showPeak = !_showPeak);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repDbMedia = _repDbMedia;
    final isPosePair = repDbMedia?.hasPosePair == true;
    final assetPath = switch (repDbMedia) {
      RepDbExerciseMedia(:final mainAssetPath?) => mainAssetPath,
      RepDbExerciseMedia(:final startAssetPath?, :final peakAssetPath?) =>
        _showPeak ? peakAssetPath : startAssetPath,
      _ => ExerciseCatalog.mediaPathFor(widget.exercise),
    };
    final poseLabel = isPosePair ? (_showPeak ? 'Final' : 'Início') : null;

    return Semantics(
      image: true,
      label: poseLabel == null
          ? 'Demonstração de ${widget.exercise.name}'
          : 'Demonstração de ${widget.exercise.name}, posição $poseLabel',
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedSwitcher(
            duration: widget.transitionDuration,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: <Widget>[...previousChildren, ?currentChild],
            ),
            child: Image.asset(
              assetPath,
              key: ValueKey<String>('exercise-media-$assetPath'),
              fit: widget.fit,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) =>
                  widget.placeholderBuilder?.call(context) ??
                  const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 30),
                  ),
            ),
          ),
          if (widget.showPoseLabel && poseLabel != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  child: Text(
                    poseLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
