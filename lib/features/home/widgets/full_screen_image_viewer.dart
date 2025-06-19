import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
        leading: IconButton( // Custom back button to ensure it's always visible
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained * 0.8, // Start slightly zoomed out
            maxScale: PhotoViewComputedScale.covered * 2.5, // Max zoom factor
            enableRotation: false, // Typically not needed for venue images
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null || event.expectedTotalBytes == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                color: Colors.white,
              ),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white60, size: 60),
            ),
          ),
        ),
      ),
    );
  }
}