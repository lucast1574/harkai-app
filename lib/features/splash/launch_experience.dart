import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// A short brand entrance over the already-mounted map, independent of the API.
class LaunchExperience extends StatefulWidget {
  final Widget child;
  const LaunchExperience({super.key, required this.child});
  @override
  State<LaunchExperience> createState() => _LaunchExperienceState();
}

class _LaunchExperienceState extends State<LaunchExperience>
    with SingleTickerProviderStateMixin {
  late final entrance =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1700),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => visible = false);
        }
      });
  bool started = false, visible = true, reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (!started) {
      started = true;
      if (reducedMotion) entrance.duration = const Duration(milliseconds: 450);
      entrance.forward();
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: visible,
        child: IgnorePointer(ignoring: visible, child: widget.child),
      ),
      if (visible)
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: navy,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: navy,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: AnimatedBuilder(
            animation: entrance,
            builder: (context, _) {
              final reveal = const Interval(
                0,
                .45,
                curve: Curves.easeOutCubic,
              ).transform(entrance.value);
              final title = const Interval(
                .16,
                .55,
                curve: Curves.easeOutCubic,
              ).transform(entrance.value);
              final exit = const Interval(
                .8,
                1,
                curve: Curves.easeOutCubic,
              ).transform(entrance.value);
              return Opacity(
                opacity: 1 - exit,
                child: Material(
                  color: navy,
                  child: SafeArea(
                    child: Center(
                      child: Semantics(
                        label: 'Harkai. Tu comunidad, cerca.',
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: reducedMotion ? 1 : reveal,
                                child: Transform.scale(
                                  scale: reducedMotion ? 1 : .94 + reveal * .06,
                                  child: Image.asset(
                                    'assets/logo/harkai_logo.png',
                                    width: 200,
                                    height: 200,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.shield_outlined,
                                      color: green,
                                      size: 112,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: reducedMotion ? 1 : title,
                                child: const Column(
                                  children: [
                                    Text(
                                      'harkai',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.3,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tu comunidad, cerca.',
                                      style: TextStyle(
                                        color: Color(0xffb5c7d6),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}
