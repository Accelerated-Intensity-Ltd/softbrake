import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SoftBrakeApp());
}

class SoftBrakeApp extends StatelessWidget {
  const SoftBrakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'soft brake',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SoftBrakeScreen(),
    );
  }
}

class SoftBrakeScreen extends StatefulWidget {
  const SoftBrakeScreen({super.key});

  @override
  State<SoftBrakeScreen> createState() => _SoftBrakeScreenState();
}

class _SoftBrakeScreenState extends State<SoftBrakeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<Offset> _slideInAnimation;
  
  int _swipeCount = 0;
  double _textOpacity = 1.0;
  int _scrollDuration = 100;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: _scrollDuration),
      vsync: this,
    );
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideInAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwipe(DismissDirection direction) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _swipeCount++;
      _textOpacity = (1.0 - (_swipeCount * 0.02)).clamp(0.0, 1.0);
      _scrollDuration = 100 + (_swipeCount * 100);
    });

    _animationController.duration = Duration(milliseconds: _scrollDuration);
    
    switch (direction) {
      case DismissDirection.startToEnd:
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        break;
      case DismissDirection.endToStart:
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        break;
      case DismissDirection.up:
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -1.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        break;
      case DismissDirection.down:
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, 1.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        break;
      default:
        break;
    }

    _animationController.forward().then((_) {
      _animationController.reset();
      setState(() {
        _isAnimating = false;
      });
    });
  }

  void _resetApp() {
    setState(() {
      _swipeCount = 0;
      _textOpacity = 1.0;
      _scrollDuration = 100;
      _isAnimating = false;
    });
    _animationController.duration = Duration(milliseconds: _scrollDuration);
    _animationController.reset();
  }

  Future<String> _loadVersion() async {
    try {
      final version = await rootBundle.loadString('VERSION.txt');
      return version.trim();
    } catch (e) {
      return 'v0.0.1'; // fallback version
    }
  }

  Widget _buildLogo() {
    return SvgPicture.asset(
      'assets/images/ai-logo-icon-white-clean.svg',
      height: 64,
      width: 64,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'soft brake',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                FutureBuilder<String>(
                  future: _loadVersion(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'v0.0.1',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                const Text(
                  '© Accelerated Intensity Ltd 2025',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse('https://accelerated-intensity.io');
                    if (!await launchUrl(url)) {
                      debugPrint('Could not launch $url');
                    }
                  },
                  child: const Text(
                    'https://accelerated-intensity.io',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Opacity(
                  opacity: 0.5,
                  child: _buildLogo(),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onPanEnd: (details) {
              if (_isAnimating) return;
              
              final velocity = details.velocity.pixelsPerSecond;
              if (velocity.dx.abs() > velocity.dy.abs()) {
                if (velocity.dx > 0) {
                  _handleSwipe(DismissDirection.startToEnd);
                } else {
                  _handleSwipe(DismissDirection.endToStart);
                }
              } else {
                if (velocity.dy > 0) {
                  _handleSwipe(DismissDirection.down);
                } else {
                  _handleSwipe(DismissDirection.up);
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  SlideTransition(
                    position: _slideOutAnimation,
                    child: Center(
                      child: Opacity(
                        opacity: _textOpacity,
                        child: const Text(
                          'slow down',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontFamily: 'sans-serif',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _slideInAnimation,
                    child: Center(
                      child: Opacity(
                        opacity: _textOpacity,
                        child: const Text(
                          'slow down',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontFamily: 'sans-serif',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reset') {
                  _resetApp();
                } else if (value == 'about') {
                  _showAboutDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'reset',
                  child: Text('Reset'),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: Text('About'),
                ),
              ],
              child: Opacity(
                opacity: 0.8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 24,
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
