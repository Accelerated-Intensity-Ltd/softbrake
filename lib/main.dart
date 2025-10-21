import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/text_config.dart';
import 'config/background_config.dart';
import 'config/speed_config.dart';

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
  int _baseScrollDuration = 100;
  String _displayText = 'slow down';
  Color _backgroundColor = Colors.black;
  double _backgroundOpacity = 1.0;
  Color _textColor = Colors.white;
  BackgroundType _backgroundType = BackgroundType.color;
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      _backgroundOpacity = _textOpacity;
      _scrollDuration = _baseScrollDuration + (_swipeCount * _baseScrollDuration);
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
      _backgroundOpacity = 1.0;
      _scrollDuration = _baseScrollDuration;
      _isAnimating = false;
    });
    _animationController.duration = Duration(milliseconds: _baseScrollDuration);
    _animationController.reset();
  }


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDuration = prefs.getInt('scroll_duration') ?? 100;
    final savedText = prefs.getString('display_text') ?? 'slow down';
    final savedColorValue = prefs.getInt('background_color') ?? Colors.black.value;
    final savedTextColorValue = prefs.getInt('text_color') ?? Colors.white.value;
    final savedBackgroundType = prefs.getString('background_type') ?? 'color';
    final savedImagePath = prefs.getString('background_image_path');

    setState(() {
      _baseScrollDuration = savedDuration;
      _scrollDuration = savedDuration;
      _displayText = savedText;
      _backgroundColor = Color(savedColorValue);
      _textColor = Color(savedTextColorValue);
      _backgroundType = savedBackgroundType == 'image' ? BackgroundType.image : BackgroundType.color;
      _backgroundImagePath = savedImagePath;
    });
    _animationController.duration = Duration(milliseconds: _baseScrollDuration);
  }

  Future<void> _saveTextSettings(String text, Color textColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_text', text);
    await prefs.setInt('text_color', textColor.value);
    setState(() {
      _displayText = text;
      _textColor = textColor;
    });
  }

  Future<void> _saveBackgroundSettings(Color? backgroundColor, String? imagePath, Color textColor, BackgroundType backgroundType) async {
    final prefs = await SharedPreferences.getInstance();

    // Save background type
    await prefs.setString('background_type', backgroundType == BackgroundType.image ? 'image' : 'color');

    // Save background color if it's a color background
    if (backgroundType == BackgroundType.color && backgroundColor != null) {
      await prefs.setInt('background_color', backgroundColor.value);
      await prefs.remove('background_image_path');
    }

    // Save image path if it's an image background
    if (backgroundType == BackgroundType.image && imagePath != null) {
      await prefs.setString('background_image_path', imagePath);
    } else {
      await prefs.remove('background_image_path');
    }

    // Always save text color
    await prefs.setInt('text_color', textColor.value);

    setState(() {
      _backgroundType = backgroundType;
      if (backgroundColor != null) _backgroundColor = backgroundColor;
      _backgroundImagePath = imagePath;
      _textColor = textColor;
    });
  }

  Future<void> _saveSpeedSettings(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scroll_duration', duration);
    setState(() {
      _baseScrollDuration = duration;
      _scrollDuration = duration;
    });
    _animationController.duration = Duration(milliseconds: duration);
  }

  Future<void> _resetTextToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('display_text');
    await prefs.remove('text_color');
    setState(() {
      _displayText = 'slow down';
      _textColor = Colors.white;
    });
  }

  Future<void> _resetBackgroundToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_color');
    await prefs.remove('background_type');
    await prefs.remove('background_image_path');
    await prefs.remove('text_color');
    setState(() {
      _backgroundColor = Colors.black;
      _backgroundType = BackgroundType.color;
      _backgroundImagePath = null;
      _textColor = Colors.white;
    });
  }

  Future<void> _resetSpeedToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scroll_duration');
    setState(() {
      _baseScrollDuration = 100;
      _scrollDuration = 100;
    });
    _animationController.duration = const Duration(milliseconds: 100);
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

  Widget _buildBackground() {
    if (_backgroundType == BackgroundType.image && _backgroundImagePath != null) {
      return Opacity(
        opacity: _backgroundOpacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(File(_backgroundImagePath!)),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: _backgroundColor.withOpacity(_backgroundOpacity),
      );
    }
  }


  void _showTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TextConfigDialog(
          initialText: _displayText,
          initialTextColor: _textColor,
          onSave: _saveTextSettings,
          onDefaults: _resetTextToDefaults,
        );
      },
    );
  }

  void _showBackgroundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackgroundConfigDialog(
          initialBackgroundColor: _backgroundType == BackgroundType.color ? _backgroundColor : null,
          initialImagePath: _backgroundImagePath,
          initialTextColor: _textColor,
          initialBackgroundType: _backgroundType,
          onSave: _saveBackgroundSettings,
          onDefaults: _resetBackgroundToDefaults,
        );
      },
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SpeedConfigDialog(
          initialDuration: _baseScrollDuration,
          onSave: _saveSpeedSettings,
          onDefaults: _resetSpeedToDefaults,
        );
      },
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
      backgroundColor: _backgroundType == BackgroundType.image ? Colors.transparent : _backgroundColor.withOpacity(_backgroundOpacity),
      body: Stack(
        children: [
          // Background layer
          _buildBackground(),
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
            child: AnimatedContainer(
              duration: Duration(milliseconds: _scrollDuration),
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Stack(
                children: [
                  SlideTransition(
                    position: _slideOutAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.125,
                            vertical: constraints.maxHeight * 0.125,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: _textOpacity,
                              child: Text(
                                _displayText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 32,
                                  fontFamily: 'sans-serif',
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SlideTransition(
                    position: _slideInAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.125,
                            vertical: constraints.maxHeight * 0.125,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: _textOpacity,
                              child: Text(
                                _displayText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 32,
                                  fontFamily: 'sans-serif',
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'text') {
                      _showTextDialog();
                    } else if (value == 'background') {
                      _showBackgroundDialog();
                    } else if (value == 'speed') {
                      _showSpeedDialog();
                    } else if (value == 'about') {
                      _showAboutDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                            semanticLabel: 'Configure settings',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Configure',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'text',
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Icon(
                            Icons.text_fields,
                            color: Colors.white,
                            size: 18,
                            semanticLabel: 'Text settings',
                          ),
                          SizedBox(width: 12),
                          Text('Text'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'background',
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 18,
                            semanticLabel: 'Background settings',
                          ),
                          SizedBox(width: 12),
                          Text('Background'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'speed',
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 18,
                            semanticLabel: 'Speed settings',
                          ),
                          SizedBox(width: 12),
                          Text('Speed'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      enabled: false,
                      height: 1,
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'about',
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                            semanticLabel: 'About information',
                          ),
                          SizedBox(width: 12),
                          Text('About'),
                        ],
                      ),
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
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _resetApp,
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
