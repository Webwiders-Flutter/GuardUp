import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTag;

  CustomImageViewer({
    super.key,
    required String imageUrl,
    required this.heroTag,
  }) : imageUrls = [imageUrl],
       initialIndex = 0;

  const CustomImageViewer.gallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.heroTag,
  });

  @override
  State<CustomImageViewer> createState() => _CustomImageViewerState();
}

class _CustomImageViewerState extends State<CustomImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error, color: Colors.white, size: 50),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error, color: Colors.white, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCounter = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: showCounter
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: '${widget.heroTag}_$_currentIndex',
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: _buildImageWidget(widget.imageUrls[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}
