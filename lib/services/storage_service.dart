import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 画像をアップロード
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // ファイル名を生成（タイムスタンプ + ユーザーID + 元のファイル名）
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = '${userId}_$timestamp$extension';

      // ストレージ参照を作成
      Reference ref = _storage.ref().child('posts').child(fileName);

      // ファイルをアップロード
      UploadTask uploadTask = ref.putFile(imageFile);

      // アップロード完了を待つ
      TaskSnapshot snapshot = await uploadTask;

      // ダウンロードURLを取得
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      developer.log('画像アップロードエラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // 複数の画像をアップロード
  Future<List<String>> uploadImages(
      List<File> imageFiles, String userId) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String extension = path.extension(imageFiles[i].path);
        String fileName = '${userId}_${timestamp}_$i$extension';

        Reference ref = _storage.ref().child('posts').child(fileName);
        UploadTask uploadTask = ref.putFile(imageFiles[i]);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);

        // 次のファイル名が重複しないように1msだけ待つ
        await Future.delayed(const Duration(milliseconds: 1));
      }

      return downloadUrls;
    } catch (e) {
      developer.log('複数画像アップロードエラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // プロフィール画像をアップロード
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // ファイル名を生成（ユーザーID + タイムスタンプ）
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = '${userId}_$timestamp$extension';

      // ストレージ参照を作成（profile_imagesフォルダ）
      Reference ref = _storage.ref().child('profile_images').child(fileName);

      // ファイルをアップロード
      UploadTask uploadTask = ref.putFile(imageFile);

      // アップロード完了を待つ
      TaskSnapshot snapshot = await uploadTask;

      // ダウンロードURLを取得
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      developer.log('プロフィール画像アップロードエラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      developer.log('画像削除エラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // 複数の画像を削除
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (String imageUrl in imageUrls) {
        try {
          Reference ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          // 個別のエラーはログに記録して続行
          developer.log('画像削除エラー: $imageUrl', error: e, name: 'StorageService');
        }
      }
    } catch (e) {
      developer.log('複数画像削除エラー', error: e, name: 'StorageService');
      rethrow;
    }
  }
}
