import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final List<String> imageUrls; // 複数画像対応
  final String? caption;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String category;
  final List<String> tags;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrls,
    this.caption,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.category,
    required this.tags,
    required this.createdAt,
  });

  // 最初の画像URLを返す（便利メソッド）
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // Firestoreドキュメントから変換
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 複数画像対応（既存データとの互換性を保つ）
    List<String> imageUrls;
    if (data['imageUrls'] != null) {
      // 新形式: imageUrls配列
      imageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null && data['imageUrl'] != '') {
      // 旧形式: 単一imageUrl
      imageUrls = [data['imageUrl']];
    } else {
      imageUrls = [];
    }

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      imageUrls: imageUrls,
      caption: data['caption'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      locationName: data['locationName'],
      category: data['category'] ?? 'その他',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'imageUrls': imageUrls,
      'caption': caption,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'category': category,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
