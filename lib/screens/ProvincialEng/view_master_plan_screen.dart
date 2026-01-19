import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewMasterPlanScreen extends StatelessWidget {
  final String? imageUrl; // URL from Firebase or your server
  final String? localAssetPath; // Local asset path as fallback
  final bool isFromFirebase; // Flag to indicate source

  const ViewMasterPlanScreen({
    super.key,
    this.imageUrl,
    this.localAssetPath = 'assets/master_plan.jpg',
    this.isFromFirebase = true,
  });

  static const Color kTextColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _buildImageWidget(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Priority 1: Display image from URL (Firebase or your server)
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          // Fallback to local asset if URL fails
          return _buildLocalImage();
        },
      );
    }
    
    // Priority 2: Display local asset
    return _buildLocalImage();
  }

  Widget _buildLocalImage() {
    if (localAssetPath != null && localAssetPath!.isNotEmpty) {
      return Image.asset(
        localAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImageWidget();
        },
      );
    }
    
    return _buildNoImageWidget();
  }

  Widget _buildNoImageWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 60,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Master plan image not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              imageUrl != null 
                ? 'Failed to load from: ${isFromFirebase ? 'Firebase' : 'Server'}\n$imageUrl'
                : 'No image URL provided',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'View Master Plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                SizedBox(height: 4),
                if (imageUrl != null)
                  Text(
                    isFromFirebase ? 'From Firebase' : 'From Server',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}