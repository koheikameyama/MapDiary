import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'profile_edit_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(35.6812, 139.7671); // 東京駅がデフォルト
  Set<Marker> _markers = {};
  List<Post> _posts = [];
  Set<PostCategory> _selectedCategories = {}; // 選択中のカテゴリ（空の場合は全て表示）

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPosts();
  }

  // 現在位置を取得
  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    }
  }

  // 投稿を読み込む
  void _loadPosts() {
    _firestoreService.getAllPosts().listen((posts) {
      setState(() {
        _posts = posts;
      });
      _updateFilteredPosts();
    });
  }

  // フィルタリングされた投稿を更新
  void _updateFilteredPosts() {
    List<Post> filteredPosts = _posts;

    // カテゴリフィルタを適用
    if (_selectedCategories.isNotEmpty) {
      filteredPosts = _posts.where((post) {
        final category = PostCategoryExtension.fromString(post.category);
        return _selectedCategories.contains(category);
      }).toList();
    }

    // マーカーを更新
    setState(() {
      _markers = filteredPosts.map((post) {
        return Marker(
          markerId: MarkerId(post.id),
          position: LatLng(post.latitude, post.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getCategoryColor(post.category),
          ),
          onTap: () => _showPostDetail(post),
        );
      }).toSet();
    });
  }

  // カテゴリに応じた色を返す
  double _getCategoryColor(String category) {
    final postCategory = PostCategoryExtension.fromString(category);
    return postCategory.markerHue;
  }

  // 投稿詳細を表示
  void _showPostDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  // 投稿作成画面へ移動
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  // カテゴリフィルタダイアログを表示
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリフィルタ'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 全て選択/解除
                  CheckboxListTile(
                    title: const Text(
                      'すべて',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _selectedCategories.isEmpty,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedCategories.clear();
                        } else {
                          _selectedCategories = PostCategory.values.toSet();
                        }
                      });
                    },
                  ),
                  const Divider(),
                  // 各カテゴリ
                  ...PostCategory.values.map((category) {
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(category.icon, size: 20, color: category.markerColor),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
                      value: _selectedCategories.isEmpty || _selectedCategories.contains(category),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCategories.add(category);
                            // 全て選択された場合はクリア（全て表示状態にする）
                            if (_selectedCategories.length == PostCategory.values.length) {
                              _selectedCategories.clear();
                            }
                          } else {
                            // 一度全て選択状態から個別解除する場合
                            if (_selectedCategories.isEmpty) {
                              _selectedCategories = PostCategory.values.toSet();
                            }
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // フィルタを適用
              });
              _updateFilteredPosts();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapMap'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: '現在地に移動',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              } else if (value == 'logout') {
                authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('プロフィール編集'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('ログアウト'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // カテゴリフィルターボタン
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: _showCategoryFilter,
            backgroundColor: _selectedCategories.isEmpty ? Colors.white : Colors.blue,
            child: Icon(
              Icons.filter_list,
              color: _selectedCategories.isEmpty ? Colors.blue : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // 投稿作成ボタン
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _navigateToCreatePost,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
