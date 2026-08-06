import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/services/listing_image_storage_service.dart';

class ListingPhotoSection extends StatelessWidget {
  const ListingPhotoSection({
    super.key,
    required this.photoUrls,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onReplacePhoto,
  });

  final List<String> photoUrls;
  final bool isUploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<String> onReplacePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _AddPhotoTile(
                isUploading: isUploading,
                onTap: onAddPhoto,
              ),
              for (final url in photoUrls) ...[
                const SizedBox(width: 12),
                _PhotoTile(
                  url: url,
                  onRemove: () => onRemovePhoto(url),
                  onReplace: () => onReplacePhoto(url),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.isUploading,
    required this.onTap,
  });

  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              isUploading ? 'Uploading...' : 'Add photo',
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.onRemove,
    required this.onReplace,
  });

  final String url;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 110,
            height: 110,
            color: AppColors.softGreen,
            child: _PhotoPreview(url: url),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
            ),
            onPressed: onReplace,
            icon: const Icon(Icons.swap_horiz, size: 16),
          ),
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (isLocalPlaceholderUrl(url)) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.primary, size: 40),
          SizedBox(height: 4),
          Text(
            'Local preview',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: 110,
      height: 110,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textMuted,
        size: 40,
      ),
    );
  }
}
