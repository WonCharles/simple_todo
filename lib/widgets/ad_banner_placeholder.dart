import 'package:flutter/material.dart';

class AdBannerPlaceholder extends StatelessWidget {
  // 배너 크기 정보 (애드몹 기준)
  // BANNER: 320x50
  // LARGE_BANNER: 320x100
  final BannerSize size;
  
  const AdBannerPlaceholder({
    Key? key, 
    this.size = BannerSize.banner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size == BannerSize.banner ? 320 : 320,
      height: size == BannerSize.banner ? 50 : 100,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ads_click, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              '광고 영역 (${size == BannerSize.banner ? '320x50' : '320x100'})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BannerSize {
  banner,      // 320x50
  largeBanner, // 320x100
}