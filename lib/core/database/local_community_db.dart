import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/community/models/post_model.dart';

class LocalCommunityDatabase {
	static const String _dbName = 'community_cache.db';
	static const String _tableName = 'own_posts_cache';
	static const int _dbVersion = 1;

	static const String colPostId = 'post_id';
	static const String colUserId = 'user_id';
	static const String colContent = 'content';
	static const String colMediaUrl = 'media_url';
	static const String colCreatedAt = 'created_at';
	static const String colUpdatedAt = 'updated_at';
	static const String colLocationName = 'location_name';
	static const String colLocationLat = 'location_lat';
	static const String colLocationLng = 'location_lng';
	static const String colActivityId = 'activity_id';
	static const String colActivityType = 'activity_type';
	static const String colActivityTitle = 'activity_title';
	static const String colActivityDurationSeconds = 'activity_duration_seconds';
	static const String colActivityDistance = 'activity_distance';
	static const String colAuthorName = 'author_name';
	static const String colAuthorAvatarUrl = 'author_avatar_url';
	static const String colLikesCount = 'likes_count';
	static const String colCommentsCount = 'comments_count';
	static const String colIsLikedByMe = 'is_liked_by_me';
	static const String colIsFavouritedByMe = 'is_favourited_by_me';
	static const String colCachedAt = 'cached_at';

	static Database? _database;

	static Future<Database> getDatabase() async {
		_database ??= await _initDatabase();
		return _database!;
	}

	static Future<Database> _initDatabase() async {
		final dbPath = await getDatabasesPath();
		final path = join(dbPath, _dbName);

		return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
	}

	static Future<void> _onCreate(Database db, int version) async {
		await db.execute('''
			CREATE TABLE $_tableName (
				$colPostId TEXT PRIMARY KEY,
				$colUserId TEXT NOT NULL,
				$colContent TEXT NOT NULL,
				$colMediaUrl TEXT,
				$colCreatedAt TEXT NOT NULL,
				$colUpdatedAt TEXT,
				$colLocationName TEXT,
				$colLocationLat REAL,
				$colLocationLng REAL,
				$colActivityId TEXT,
				$colActivityType TEXT,
				$colActivityTitle TEXT,
				$colActivityDurationSeconds INTEGER,
				$colActivityDistance REAL,
				$colAuthorName TEXT,
				$colAuthorAvatarUrl TEXT,
				$colLikesCount INTEGER NOT NULL DEFAULT 0,
				$colCommentsCount INTEGER NOT NULL DEFAULT 0,
				$colIsLikedByMe INTEGER NOT NULL DEFAULT 0,
				$colIsFavouritedByMe INTEGER NOT NULL DEFAULT 0,
				$colCachedAt TEXT NOT NULL
			)
		''');

		await db.execute(
			'CREATE INDEX idx_own_posts_user_date ON $_tableName($colUserId, $colCreatedAt)',
		);
	}

	static Future<void> saveOwnPosts({
		required String userId,
		required List<PostModel> posts,
	}) async {
		final db = await getDatabase();
		final now = DateTime.now().toUtc().toIso8601String();

		await db.transaction((txn) async {
			await txn.delete(
				_tableName,
				where: '$colUserId = ?',
				whereArgs: [userId],
			);

			for (final post in posts) {
				await txn.insert(
					_tableName,
					{
						colPostId: post.id,
						colUserId: userId,
						colContent: post.content,
						colMediaUrl: post.mediaUrl,
						colCreatedAt: post.createdAt.toIso8601String(),
						colUpdatedAt: post.updatedAt?.toIso8601String(),
						colLocationName: post.locationName,
						colLocationLat: post.locationLat,
						colLocationLng: post.locationLng,
						colActivityId: post.activityId,
						colActivityType: post.activityType,
						colActivityTitle: post.activityTitle,
						colActivityDurationSeconds: post.activityDurationSeconds,
						colActivityDistance: post.activityDistance,
						colAuthorName: post.authorName,
						colAuthorAvatarUrl: post.authorAvatarUrl,
						colLikesCount: post.likesCount,
						colCommentsCount: post.commentsCount,
						colIsLikedByMe: post.isLikedByMe ? 1 : 0,
						colIsFavouritedByMe: post.isFavouritedByMe ? 1 : 0,
						colCachedAt: now,
					},
					conflictAlgorithm: ConflictAlgorithm.replace,
				);
			}
		});
	}

	static Future<void> upsertOwnPost(PostModel post) async {
		final db = await getDatabase();
		final now = DateTime.now().toUtc().toIso8601String();

		await db.insert(
			_tableName,
			{
				colPostId: post.id,
				colUserId: post.userId,
				colContent: post.content,
				colMediaUrl: post.mediaUrl,
				colCreatedAt: post.createdAt.toIso8601String(),
				colUpdatedAt: post.updatedAt?.toIso8601String(),
				colLocationName: post.locationName,
				colLocationLat: post.locationLat,
				colLocationLng: post.locationLng,
				colActivityId: post.activityId,
				colActivityType: post.activityType,
				colActivityTitle: post.activityTitle,
				colActivityDurationSeconds: post.activityDurationSeconds,
				colActivityDistance: post.activityDistance,
				colAuthorName: post.authorName,
				colAuthorAvatarUrl: post.authorAvatarUrl,
				colLikesCount: post.likesCount,
				colCommentsCount: post.commentsCount,
				colIsLikedByMe: post.isLikedByMe ? 1 : 0,
				colIsFavouritedByMe: post.isFavouritedByMe ? 1 : 0,
				colCachedAt: now,
			},
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	static Future<List<PostModel>> getOwnCachedPosts(String userId) async {
		final db = await getDatabase();
		final rows = await db.query(
			_tableName,
			where: '$colUserId = ?',
			whereArgs: [userId],
			orderBy: '$colCreatedAt DESC',
		);

		return rows.map((row) {
			return PostModel(
				id: row[colPostId] as String,
				userId: row[colUserId] as String,
				content: row[colContent] as String,
				mediaUrl: row[colMediaUrl] as String?,
				createdAt: DateTime.parse(row[colCreatedAt] as String),
				updatedAt: row[colUpdatedAt] != null
						? DateTime.parse(row[colUpdatedAt] as String)
						: null,
				locationName: row[colLocationName] as String?,
				locationLat: (row[colLocationLat] as num?)?.toDouble(),
				locationLng: (row[colLocationLng] as num?)?.toDouble(),
				activityId: row[colActivityId] as String?,
				activityType: row[colActivityType] as String?,
				activityTitle: row[colActivityTitle] as String?,
				activityDurationSeconds: row[colActivityDurationSeconds] as int?,
				activityDistance: (row[colActivityDistance] as num?)?.toDouble(),
				authorName: (row[colAuthorName] as String?) ?? 'You',
				authorAvatarUrl: row[colAuthorAvatarUrl] as String?,
				likesCount: row[colLikesCount] as int? ?? 0,
				commentsCount: row[colCommentsCount] as int? ?? 0,
				isLikedByMe: (row[colIsLikedByMe] as int? ?? 0) == 1,
				isFavouritedByMe: (row[colIsFavouritedByMe] as int? ?? 0) == 1,
			);
		}).toList();
	}

	static Future<void> deleteCachedPost(String postId, String userId) async {
		final db = await getDatabase();
		await db.delete(
			_tableName,
			where: '$colPostId = ? AND $colUserId = ?',
			whereArgs: [postId, userId],
		);
	}
}
