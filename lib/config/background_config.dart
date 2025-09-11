import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';

enum BackgroundType { color, image }

class BackgroundConfigDialog extends StatefulWidget {
  final Color? initialBackgroundColor;
  final String? initialImagePath;
  final Color initialTextColor;
  final BackgroundType initialBackgroundType;
  final Function(Color? backgroundColor, String? imagePath, Color textColor, BackgroundType backgroundType) onSave;
  final Function() onDefaults;

  const BackgroundConfigDialog({
    super.key,
    this.initialBackgroundColor,
    this.initialImagePath,
    required this.initialTextColor,
    required this.initialBackgroundType,
    required this.onSave,
    required this.onDefaults,
  });

  @override
  State<BackgroundConfigDialog> createState() => _BackgroundConfigDialogState();
}

class _BackgroundConfigDialogState extends State<BackgroundConfigDialog> {
  late BackgroundType _selectedBackgroundType;
  late Color _selectedBackgroundColor;
  late Color _selectedTextColor;
  String? _selectedImagePath;
  Uint8List? _imageData;
  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _selectedBackgroundType = widget.initialBackgroundType;
    _selectedBackgroundColor = widget.initialBackgroundColor ?? Colors.black;
    _selectedTextColor = widget.initialTextColor;
    _selectedImagePath = widget.initialImagePath;
    if (_selectedImagePath != null) {
      _loadImageFromPath(_selectedImagePath!);
    }
  }

  bool _hasChanges() {
    return _selectedBackgroundType != widget.initialBackgroundType ||
           _selectedBackgroundColor != (widget.initialBackgroundColor ?? Colors.black) ||
           _selectedTextColor != widget.initialTextColor ||
           _selectedImagePath != widget.initialImagePath;
  }

  Future<void> _loadImageFromPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageData = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageData = bytes;
          _selectedImagePath = image.path;
          _selectedBackgroundType = BackgroundType.image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Pick background color',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedBackgroundColor,
              onColorChanged: (Color color) {
                _selectedBackgroundColor = color;
              },
              colorPickerWidth: 300.0,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsl,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedBackgroundType = BackgroundType.color;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  void _showTextColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Pick text color',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedTextColor,
              onColorChanged: (Color color) {
                _selectedTextColor = color;
              },
              colorPickerWidth: 300.0,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsl,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  void _showImageCropper() {
    if (_imageData == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 600,
            child: Column(
              children: [
                const Text(
                  'Crop Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Crop(
                    image: _imageData!,
                    controller: _cropController,
                    onCropped: (result) {
                      if (result is CropSuccess) {
                        // Save the cropped image data
                        setState(() {
                          _imageData = result.croppedImage;
                        });
                        Navigator.of(context).pop();
                      } else if (result is CropFailure) {
                        debugPrint('Crop failed');
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cropController.crop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Crop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundPreview() {
    if (_selectedBackgroundType == BackgroundType.color) {
      return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: _selectedBackgroundColor,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.color_lens,
          color: Colors.white,
          size: 24,
        ),
      );
    } else if (_imageData != null) {
      return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            _imageData!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image,
          color: Colors.white,
          size: 24,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Background Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              // Background Type Selection
              const Text(
                'Background Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Radio<BackgroundType>(
                        value: BackgroundType.color,
                        groupValue: _selectedBackgroundType,
                        onChanged: (BackgroundType? value) {
                          setState(() {
                            _selectedBackgroundType = value!;
                          });
                        },
                        activeColor: Colors.white,
                      ),
                      const Text(
                        'Color',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Radio<BackgroundType>(
                        value: BackgroundType.image,
                        groupValue: _selectedBackgroundType,
                        onChanged: (BackgroundType? value) {
                          setState(() {
                            _selectedBackgroundType = value!;
                          });
                        },
                        activeColor: Colors.white,
                      ),
                      const Text(
                        'Image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Background Configuration
              if (_selectedBackgroundType == BackgroundType.color) ...[
                const Text(
                  'Background Color',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showBackgroundColorPicker,
                  child: _buildBackgroundPreview(),
                ),
              ] else ...[
                const Text(
                  'Background Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: _buildBackgroundPreview(),
                ),
                if (_imageData != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showImageCropper,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Crop & Position'),
                  ),
                ],
              ],

              const SizedBox(height: 25),

              // Text Color
              const Text(
                'Text Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showTextColorPicker,
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedTextColor,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.text_fields,
                    color: _selectedTextColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await widget.onDefaults();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Defaults'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: BorderSide(color: Colors.grey[600]!, width: 1),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _hasChanges() ? () {
                      Color? backgroundColor = _selectedBackgroundType == BackgroundType.color ? _selectedBackgroundColor : null;
                      String? imagePath = _selectedBackgroundType == BackgroundType.image ? _selectedImagePath : null;

                      widget.onSave(backgroundColor, imagePath, _selectedTextColor, _selectedBackgroundType);
                      Navigator.of(context).pop();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges() ? Colors.green[600] : Colors.grey[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}