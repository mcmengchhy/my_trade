import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/app_palette.dart';
import 'dashboard_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _fieldSlide;
  late final Animation<double> _fieldFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  Animation<double> _fade(Interval interval) =>
      CurvedAnimation(parent: _controller, curve: interval);

  Animation<Offset> _slideUp(Interval interval) => Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: interval));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = _fade(const Interval(0.0, 0.45, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _titleFade = _fade(const Interval(0.20, 0.60, curve: Curves.easeOut));
    _titleSlide = _slideUp(const Interval(0.20, 0.60, curve: Curves.easeOut));

    _subtitleFade = _fade(const Interval(0.32, 0.70, curve: Curves.easeOut));
    _subtitleSlide = _slideUp(const Interval(0.32, 0.70, curve: Curves.easeOut));

    _fieldFade = _fade(const Interval(0.45, 0.82, curve: Curves.easeOut));
    _fieldSlide = _slideUp(const Interval(0.45, 0.82, curve: Curves.easeOut));

    _buttonFade = _fade(const Interval(0.60, 1.0, curve: Curves.easeOut));
    _buttonSlide = _slideUp(const Interval(0.60, 1.0, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context.read<ProfileProvider>().setName(name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.candlestick_chart_rounded, size: 46, color: scheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          'Trade Journey',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Text(
                          'Set a start balance, pick a target, and grow it day by day — '
                          'like \$10 to \$1000 in 20 days.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _fieldFade,
                      child: SlideTransition(
                        position: _fieldSlide,
                        child: TextField(
                          key: const Key('welcomeNameField'),
                          controller: _nameCtrl,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'What should we call you?',
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _buttonFade,
                      child: SlideTransition(
                        position: _buttonSlide,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('welcomeGetStartedButton'),
                            onPressed: _nameCtrl.text.trim().isEmpty || _submitting ? null : _submit,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Get started'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
