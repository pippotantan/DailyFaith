import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/background_source.dart';
import 'package:zane_bible_lockscreen/core/services/local_gallery_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/utils/background_keywords.dart';
import 'package:zane_bible_lockscreen/core/utils/bible_topics.dart';
import 'package:zane_bible_lockscreen/core/utils/external_links.dart';

class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key});

  @override
  State<WallpaperSettingsScreen> createState() =>
      _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  WallpaperTarget selectedTarget = WallpaperTarget.both;
  String selectedVerseTopic = BibleTopics.all;
  String selectedBackgroundKeyword = BackgroundKeywords.all;
  BackgroundSource selectedBackgroundSource = BackgroundSource.pexels;
  List<String> localImagePaths = [];
  bool isLoading = true;
  bool _isSaving = false;
  bool _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final target = await SettingsService.getWallpaperTarget();
      final topic = await SettingsService.getVerseTopic();
      final keyword = await SettingsService.getBackgroundKeyword();
      final source = await SettingsService.getBackgroundSource();
      final paths = await LocalGalleryService.getStoredPaths();
      if (mounted) {
        setState(() {
          selectedTarget = target;
          selectedVerseTopic = topic;
          selectedBackgroundKeyword = keyword;
          selectedBackgroundSource = source;
          localImagePaths = paths;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          selectedTarget = WallpaperTarget.both;
          selectedVerseTopic = BibleTopics.all;
          selectedBackgroundKeyword = BackgroundKeywords.all;
          selectedBackgroundSource = BackgroundSource.pexels;
          localImagePaths = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveBackgroundSource(BackgroundSource source) async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.setBackgroundSource(source);
      if (mounted) {
        setState(() {
          selectedBackgroundSource = source;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background source updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _pickAndAddImages() async {
    setState(() => _isPickingImages = true);
    try {
      final added = await LocalGalleryService.pickAndAddImages();
      final paths = await LocalGalleryService.getStoredPaths();
      if (mounted) {
        setState(() {
          localImagePaths = paths;
          _isPickingImages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added > 0
                  ? 'Added $added image${added == 1 ? '' : 's'}'
                  : 'No images selected',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add images: $e')),
        );
      }
    }
  }

  Future<void> _removeLocalImage(String path) async {
    await LocalGalleryService.removePath(path);
    final paths = await LocalGalleryService.getStoredPaths();
    if (mounted) setState(() => localImagePaths = paths);
  }

  Future<void> _clearAllLocalImages() async {
    await LocalGalleryService.clearAll(deleteFiles: true);
    if (mounted) {
      setState(() => localImagePaths = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local images removed')),
      );
    }
  }

  Future<void> _saveBackgroundKeyword(String keywordId) async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.setBackgroundKeyword(keywordId);
      if (mounted) {
        setState(() {
          selectedBackgroundKeyword = keywordId;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background keyword updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update keyword: $e')),
        );
      }
    }
  }

  Future<void> _saveVerseTopic(String topicId) async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.setVerseTopic(topicId);
      if (mounted) {
        setState(() {
          selectedVerseTopic = topicId;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verse topic updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update topic: $e')),
        );
      }
    }
  }

  Future<void> _saveWallpaperTarget(WallpaperTarget target) async {
    setState(() => _isSaving = true);

    try {
      await SettingsService.setWallpaperTarget(target);
      if (mounted) {
        setState(() {
          selectedTarget = target;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper target updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update target: $e')),
        );
      }
    }
  }

  Future<void> _openSupportPage() async {
    final launched = await ExternalLinks.launchBuyMeACoffee();
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the support page. Please try again.'),
        ),
      );
    }
  }

  Widget _buildRadioCard({
    required String title,
    required String subtitle,
    required WallpaperTarget value,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: RadioListTile<WallpaperTarget>(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: icon != null ? Icon(icon, color: Colors.blue) : null,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallpaper Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose Pexels (online) or your device gallery (works offline).',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioGroup<BackgroundSource>(
                      groupValue: selectedBackgroundSource,
                      onChanged: _isSaving
                          ? (_) {}
                          : (source) {
                              if (source != null) {
                                _saveBackgroundSource(source);
                              }
                            },
                      child: Column(
                        children: BackgroundSource.values.map((source) {
                          return RadioListTile<BackgroundSource>(
                            title: Text(source.displayName),
                            value: source,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (selectedBackgroundSource == BackgroundSource.localGallery) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Local gallery images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select images from your device. One will be chosen randomly for each background.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isPickingImages ? null : _pickAndAddImages,
                          icon: _isPickingImages
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate),
                          label: Text(
                            _isPickingImages ? 'Selecting...' : 'Add from gallery',
                          ),
                        ),
                        if (localImagePaths.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _isSaving ? null : _clearAllLocalImages,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('Clear all'),
                          ),
                        ],
                      ],
                    ),
                    if (localImagePaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: localImagePaths.length,
                          itemBuilder: (context, i) {
                            final path = localImagePaths[i];
                            final file = File(path);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 80,
                                      height: 100,
                                      child: file.existsSync()
                                          ? Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeLocalImage(path),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${localImagePaths.length} image${localImagePaths.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No images yet. Tap "Add from gallery" to select images.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                  if (selectedBackgroundSource == BackgroundSource.pexels) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Background image by keyword',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Filter background images by topic (Nature, Christian, Animals, etc.). Default: All (varied).',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: BackgroundKeywords.keywordIds
                                  .contains(selectedBackgroundKeyword)
                              ? selectedBackgroundKeyword
                              : BackgroundKeywords.all,
                          underline: const SizedBox(),
                          items: BackgroundKeywords.keywordIds.map((id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(BackgroundKeywords.labelFor(id)),
                            );
                          }).toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _saveBackgroundKeyword(value);
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Verse by topic or keyword',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Filter which verses appear on manual and automatic wallpapers. Default: all 66 books.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: BibleTopics.topicIds.contains(selectedVerseTopic)
                            ? selectedVerseTopic
                            : BibleTopics.all,
                        underline: const SizedBox(),
                        items: BibleTopics.topicIds.map((id) {
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(BibleTopics.labelFor(id)),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) _saveVerseTopic(value);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Apply Background Updates To:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<WallpaperTarget>(
                    groupValue: selectedTarget,
                    onChanged: _isSaving
                        ? (_) {}
                        : (target) {
                            if (target != null) {
                              _saveWallpaperTarget(target);
                            }
                          },
                    child: Column(
                      children: [
                        _buildRadioCard(
                          title: 'Lock Screen Only',
                          subtitle: 'Update only the lock screen background',
                          value: WallpaperTarget.lockScreenOnly,
                          icon: Icons.lock,
                        ),
                        _buildRadioCard(
                          title: 'Home Screen Only',
                          subtitle: 'Update only the home screen background',
                          value: WallpaperTarget.homeScreenOnly,
                          icon: Icons.home,
                        ),
                        _buildRadioCard(
                          title: 'Both',
                          subtitle:
                              'Update both lock screen and home screen backgrounds',
                          value: WallpaperTarget.both,
                          icon: Icons.smartphone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'This setting applies to both manual wallpaper updates '
                      'and automatic daily wallpaper generation.',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Support the Developer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enjoying the Bible Wallpaper app? Your support helps keep '
                    'it free and allows me to continue improving it.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.coffee_outlined, color: Colors.blue),
                      title: const Text('Buy Me a Coffee'),
                      subtitle: const Text('Zane Daily Faith'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: _openSupportPage,
                    ),
                  ),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }
}
