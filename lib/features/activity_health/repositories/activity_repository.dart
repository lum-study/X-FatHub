import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xfathub/core/database/local_activity_db.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../models/activity_location_point.dart';

/// Repository for managing activity data
/// Handles both local and remote (Supabase) persistence
class ActivityRepository {
  final supabase = Supabase.instance.client;

  /// Create a new activity session
  Future<String> createActivity({
    required String userId,
    required String activityType,
    String? title,
    String? description,
  }) async {
    final activityId = const Uuid().v4();
    final now = DateTime.now();

    final activity = ActivityModel(
      id: activityId,
      userId: userId,
      activityType: activityType,
      title: title,
      description: description,
      startTime: now,
      createdAt: now,
    );

    try {
      // Save to local database
      await LocalActivityDatabase.insertActivity(activity.toJson());
      print('✓ Activity created locally: $activityId');
      return activityId;
    } catch (e) {
      print('✗ Error creating activity: $e');
      rethrow;
    }
  }

  /// Add a location point to an ongoing activity
  Future<void> addLocationPoint({
    required String activityId,
    required double latitude,
    required double longitude,
    double? altitude,
    double? accuracy,
    double? speed,
  }) async {
    try {
      final pointId = const Uuid().v4();
      final sequenceNumber =
          await LocalActivityDatabase.getRoutePointCount(activityId);

      final locationPoint = ActivityLocationPoint(
        id: pointId,
        activityId: activityId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        accuracy: accuracy,
        speed: speed,
        timestamp: DateTime.now(),
        sequenceNumber: sequenceNumber,
      );

      await LocalActivityDatabase.insertRoutePoint(locationPoint.toJson());
    } catch (e) {
      print('✗ Error adding location point: $e');
      rethrow;
    }
  }

  /// Update activity metrics
  Future<void> updateActivityMetrics({
    required String activityId,
    required double distanceTraveled,
    required int stepCount,
    required double caloriesBurned,
    required double averagePace,
    double? maxSpeed,
    double? elevationGain,
  }) async {
    try {
      final updates = {
        'distance_traveled': distanceTraveled,
        'step_count': stepCount,
        'calories_burned': caloriesBurned,
        'average_pace': averagePace,
        'max_speed': maxSpeed,
        'elevation_gain': elevationGain,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await LocalActivityDatabase.updateActivity(activityId, updates);
    } catch (e) {
      print('✗ Error updating activity metrics: $e');
      rethrow;
    }
  }

  /// Update activity duration
  Future<void> updateActivityDuration({
    required String activityId,
    required Duration duration,
  }) async {
    try {
      await LocalActivityDatabase.updateActivity(
        activityId,
        {
          'total_duration_seconds': duration.inSeconds,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('✗ Error updating activity duration: $e');
      rethrow;
    }
  }

  /// Update activity status
  Future<void> updateActivityStatus(
    String activityId,
    ActivityStatus status,
  ) async {
    try {
      final updates = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Set end time if completing
      if (status == ActivityStatus.completed) {
        updates['end_time'] = DateTime.now().toIso8601String();
      }

      await LocalActivityDatabase.updateActivity(activityId, updates);
    } catch (e) {
      print('✗ Error updating activity status: $e');
      rethrow;
    }
  }

  /// Get activity by ID with all route points
  Future<ActivityModel?> getActivityById(String activityId) async {
    try {
      final activityData =
          await LocalActivityDatabase.getActivityById(activityId);
      if (activityData == null) return null;

      final routePointsData =
          await LocalActivityDatabase.getRoutePointsByActivity(activityId);
      final routePoints =
          routePointsData.map((p) => ActivityLocationPoint.fromJson(p)).toList();

      final activity = ActivityModel.fromJson(activityData);
      return activity.copyWith(routePoints: routePoints);
    } catch (e) {
      print('✗ Error getting activity: $e');
      rethrow;
    }
  }

  /// Get all activities for a user
  Future<List<ActivityModel>> getActivitiesByUser(String userId) async {
    try {
      final activitiesData =
          await LocalActivityDatabase.getActivitiesByUser(userId);
      final activities = activitiesData
          .map((data) => ActivityModel.fromJson(data))
          .toList();
      return activities;
    } catch (e) {
      print('✗ Error getting activities: $e');
      rethrow;
    }
  }

  /// Get recent completed activities
  Future<List<ActivityModel>> getRecentActivities(
    String userId, [
    int limit = 10,
  ]) async {
    try {
      final activitiesData =
          await LocalActivityDatabase.getRecentActivities(userId, limit);
      final activities = activitiesData
          .map((data) => ActivityModel.fromJson(data))
          .toList();
      return activities;
    } catch (e) {
      print('✗ Error getting recent activities: $e');
      rethrow;
    }
  }

  /// Get route points for an activity
  Future<List<ActivityLocationPoint>> getRoutePoints(String activityId) async {
    try {
      final pointsData =
          await LocalActivityDatabase.getRoutePointsByActivity(activityId);
      return pointsData
          .map((p) => ActivityLocationPoint.fromJson(p))
          .toList();
    } catch (e) {
      print('✗ Error getting route points: $e');
      rethrow;
    }
  }

  /// Save activity to Supabase (sync)
  /// Called when activity is completed
  Future<bool> syncActivityToServer(ActivityModel activity) async {
    try {
      // Upload activity
      await supabase.from('activities').upsert({
        'id': activity.id,
        'user_id': activity.userId,
        'activity_type': activity.activityType,
        'title': activity.title,
        'description': activity.description,
        'start_time': activity.startTime.toIso8601String(),
        'end_time': activity.endTime?.toIso8601String(),
        'total_duration_seconds': activity.totalDuration?.inSeconds,
        'distance_traveled': activity.distanceTraveled,
        'start_latitude': activity.startLatitude,
        'start_longitude': activity.startLongitude,
        'end_latitude': activity.endLatitude,
        'end_longitude': activity.endLongitude,
        'step_count': activity.stepCount,
        'calories_burned': activity.caloriesBurned,
        'average_pace': activity.averagePace,
        'max_speed': activity.maxSpeed,
        'elevation_gain': activity.elevationGain,
        'status': activity.status.name,
        'created_at': activity.createdAt.toIso8601String(),
      });

      // Upload route points
      if (activity.routePoints.isNotEmpty) {
        final routePointsJson =
            activity.routePoints.map((p) => p.toJson()).toList();
        await supabase
            .from('activity_route_points')
            .upsert(routePointsJson);
      }

      // Mark as synced in local database
      await LocalActivityDatabase.updateActivity(activity.id, {
        'is_synced_to_server': 1,
      });

      print('✓ Activity synced to server: ${activity.id}');
      return true;
    } catch (e) {
      print('✗ Error syncing activity to server: $e');
      return false;
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(String activityId) async {
    try {
      // Delete from local database (cascade delete route points)
      await LocalActivityDatabase.deleteActivity(activityId);

      // Try to delete from server if was synced
      try {
        await supabase.from('activities').delete().eq('id', activityId);
      } catch (e) {
        // If not synced, it won't exist on server
        print('Activity not on server or already deleted');
      }

      print('✓ Activity deleted: $activityId');
    } catch (e) {
      print('✗ Error deleting activity: $e');
      rethrow;
    }
  }

  /// Get summary statistics for an activity
  Future<Map<String, dynamic>> getActivitySummary(String activityId) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) return {};

      return {
        'id': activity.id,
        'activityType': activity.activityType,
        'title': activity.title,
        'distance': activity.distanceTraveled,
        'duration': activity.durationString,
        'totalDurationSeconds': activity.totalDuration?.inSeconds,
        'steps': activity.stepCount,
        'calories': activity.caloriesBurned,
        'pace': activity.averagePace,
        'maxSpeed': activity.maxSpeed,
        'startTime': activity.startTime,
        'endTime': activity.endTime,
        'routePoints': activity.routePoints.length,
      };
    } catch (e) {
      print('✗ Error getting activity summary: $e');
      return {};
    }
  }
}
