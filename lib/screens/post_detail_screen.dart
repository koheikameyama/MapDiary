import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 投稿を削除
  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('思い出を削除'),
        content: const Text('この思い出を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                // 複数画像を全て削除
                await _storageService.deleteImages(widget.post.imageUrls);
                // Firestoreの投稿を削除
                await _firestoreService.deletePost(widget.post.id);
                if (mounted) {
                  navigator.pop(); // ダイアログを閉じる
                  navigator.pop(); // 詳細画面を閉じる
                  messenger.showSnackBar(
                    const SnackBar(content: Text('思い出を削除しました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwnPost = authProvider.user?.uid == widget.post.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('思い出の詳細'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (isOwnPost) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(post: widget.post),
                  ),
                );
                // 更新された場合は画面を再読み込み
                if (result == true && mounted) {
                  navigator.pop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 画像ギャラリー（複数画像対応）
            SizedBox(
              height: 400,
              child: widget.post.imageUrls.length == 1
                  ? CachedNetworkImage(
                      imageUrl: widget.post.imageUrls.first,
                      height: 400,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 400,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 400,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, size: 64),
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: widget.post.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: widget.post.imageUrls[index],
                              height: 400,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 400,
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 400,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error, size: 64),
                              ),
                            );
                          },
                        ),
                        // ページインジケーター（改善版）
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ドット表示
                                  ...List.generate(
                                    widget.post.imageUrls.length,
                                    (index) => Container(
                                      width: index == _currentPage ? 8 : 6,
                                      height: index == _currentPage ? 8 : 6,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: index == _currentPage
                                            ? Colors.white
                                            : Colors.white60,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ページ番号表示
                                  Text(
                                    '${_currentPage + 1}/${widget.post.imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日時
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm')
                        .format(widget.post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // カテゴリ
                  Builder(
                    builder: (context) {
                      final category = PostCategoryExtension.fromString(
                          widget.post.category);
                      return Chip(
                        avatar: Icon(category.icon,
                            size: 18, color: category.markerColor),
                        label: Text(category.displayName),
                        backgroundColor: category.markerColor.withOpacity(0.2),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // キャプション
                  if (widget.post.caption != null &&
                      widget.post.caption!.isNotEmpty) ...[
                    Text(
                      widget.post.caption!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 位置情報
                  if (widget.post.locationName != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.post.locationName!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
