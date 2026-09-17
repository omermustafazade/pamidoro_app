// File: services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FocusSession {
  final String? id;
  final DateTime date;
  final int durationMinutes;
  final String technique;
  final String folderName;
  final String taskName;

  FocusSession({
    this.id,
    required this.date,
    required this.durationMinutes,
    required this.technique,
    required this.folderName,
    required this.taskName,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'durationMinutes': durationMinutes,
    'technique': technique,
    'folderName': folderName,
    'taskName': taskName,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json, String docId) => FocusSession(
    id: docId,
    date: (json['date'] as Timestamp).toDate(),
    durationMinutes: json['durationMinutes'] as int,
    technique: json['technique'] ?? '',
    folderName: json['folderName'] ?? 'Genel Çalışma',
    taskName: json['taskName'] ?? '',
  );
}

// YENİLENDİ: Alt Görevler (Subtasks) ve Sıralama (OrderIndex) eklendi
class AgendaTask {
  final String? id;
  final String title;
  final String folderName;
  final bool isCompleted;
  final bool isPinned;
  final DateTime createdAt;
  final List<Map<String, dynamic>> subtasks; // Mini checklist için
  final int orderIndex; // Sürükle-bırak sıralaması için

  AgendaTask({
    this.id,
    required this.title,
    required this.folderName,
    this.isCompleted = false,
    this.isPinned = false,
    required this.createdAt,
    this.subtasks = const [],
    this.orderIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'folderName': folderName,
    'isCompleted': isCompleted,
    'isPinned': isPinned,
    'createdAt': Timestamp.fromDate(createdAt),
    'subtasks': subtasks,
    'orderIndex': orderIndex,
  };

  factory AgendaTask.fromJson(Map<String, dynamic> json, String docId) => AgendaTask(
    id: docId,
    title: json['title'] ?? '',
    folderName: json['folderName'] ?? 'Genel Çalışma',
    isCompleted: json['isCompleted'] ?? false,
    isPinned: json['isPinned'] ?? false,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    subtasks: (json['subtasks'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    orderIndex: json['orderIndex'] ?? 0,
  );
}

abstract class IDatabaseService {
  Future<void> init();
  Future<void> saveSession(FocusSession session);
  Future<List<FocusSession>> getTodaySessions();
  Future<Map<DateTime, int>> getHeatmapData({required int days});
  Future<List<FocusSession>> getSessionsByDate(DateTime date);
  Future<List<FocusSession>> getSessionsForDateRange(DateTime start, DateTime end);
  Future<Map<String, int>> getFolderStats();
  Future<void> createNewFolder(String folderName);
  Future<void> renameFolder(String oldName, String newName);
  Future<void> deleteFolder(String folderName, {bool moveToGeneral = true});
  Future<List<String>> getAllFolders();
  Future<List<String>> getTasksForFolder(String folderName);
  Future<List<FocusSession>> getSessionsForFolder(String folderName);
  Future<void> deleteSession(FocusSession session);
  Future<int> getDailyGoal();
  Future<void> setDailyGoal(int minutes);
  Future<void> clearAllData();
  Future<bool> getSetting(String key, bool defaultValue);
  Future<void> saveSetting(String key, bool value);

  Future<void> addAgendaTask(AgendaTask task);
  Future<List<AgendaTask>> getAgendaTasks();
  Future<void> updateAgendaTask(AgendaTask task);
  Future<void> deleteAgendaTask(String taskId);
  Future<List<String>> getPendingAgendaTaskNames(String folderName);
  Future<void> updateTaskOrders(List<AgendaTask> tasks); // YENİ EKLENDİ
}

class LocalDatabaseService implements IDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Oturum açık değil.");
    return user.uid;
  }

  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);
  CollectionReference get _sessionsCol => _userDoc.collection('sessions');
  CollectionReference get _tasksCol => _userDoc.collection('agendaTasks');

  @override
  Future<void> init() async {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint("Firestore Settings Error: $e");
    }
  }

  Future<void> _ensureUserDocExists() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) {
        await _userDoc.set({
          'dailyGoal': 240,
          'folders': ['Genel Çalışma'],
          'settings': {
            'darkMode': false,
            'notifications': true,
            'keepScreenAwake': true,
            'autoStartBreaks': false,
            'haptics': true,
          },
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Kullanıcı Doküman Oluşturma Hatası: $e");
    }
  }

  @override
  Future<void> saveSession(FocusSession session) async {
    try {
      await _ensureUserDocExists();
      await _sessionsCol.add(session.toJson());
    } catch (e) {
      debugPrint("Seans Kaydetme Hatası: $e");
    }
  }

  @override
  Future<List<FocusSession>> getTodaySessions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _sessionsCol
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint("Bugün Seansları Çekme Hatası: $e");
      return [];
    }
  }

  @override
  Future<Map<DateTime, int>> getHeatmapData({required int days}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days - 1));
      final startOfRange = DateTime(startDate.year, startDate.month, startDate.day);
      final snapshot = await _sessionsCol
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
          .get();
      final Map<DateTime, int> heatmap = {};
      for (int i = 0; i < days; i++) {
        final d = startOfRange.add(Duration(days: i));
        heatmap[DateTime(d.year, d.month, d.day)] = 0;
      }
      for (var doc in snapshot.docs) {
        final session = FocusSession.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        final cleanDate = DateTime(session.date.year, session.date.month, session.date.day);
        if (heatmap.containsKey(cleanDate)) {
          heatmap[cleanDate] = heatmap[cleanDate]! + session.durationMinutes;
        }
      }
      return heatmap;
    } catch (e) {
      debugPrint("Heatmap Verisi Çekme Hatası: $e");
      return {};
    }
  }

  @override
  Future<List<FocusSession>> getSessionsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _sessionsCol
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint("Tarihe Göre Seans Çekme Hatası: $e");
      return [];
    }
  }

  @override
  Future<List<FocusSession>> getSessionsForDateRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _sessionsCol
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint("Tarih Aralığı Seans Çekme Hatası: $e");
      return [];
    }
  }

  @override
  Future<Map<String, int>> getFolderStats() async {
    try {
      await _ensureUserDocExists();
      final doc = await _userDoc.get(const GetOptions(source: Source.serverAndCache));
      final List<dynamic> folders = (doc.data() as Map<String, dynamic>)['folders'] ?? [];
      final Map<String, int> stats = {};
      for (var f in folders) stats[f.toString()] = 0;
      final snapshot = await _sessionsCol.get();
      for (var sDoc in snapshot.docs) {
        final session = FocusSession.fromJson(sDoc.data() as Map<String, dynamic>, sDoc.id);
        if (stats.containsKey(session.folderName)) {
          stats[session.folderName] = (stats[session.folderName] ?? 0) + 1;
        } else {
          stats[session.folderName] = 1;
        }
      }
      return stats;
    } catch (e) {
      debugPrint("Klasör İstatistikleri Hatası: $e");
      return {};
    }
  }

  @override
  Future<void> createNewFolder(String folderName) async {
    try {
      await _ensureUserDocExists();
      await _userDoc.update({
        'folders': FieldValue.arrayUnion([folderName])
      });
    } catch (e) {
      debugPrint("Klasör Oluşturma Hatası: $e");
    }
  }

  @override
  Future<void> renameFolder(String oldName, String newName) async {
    try {
      await _ensureUserDocExists();
      final doc = await _userDoc.get();
      List<dynamic> folders = (doc.data() as Map<String, dynamic>)['folders'] ?? [];
      if (folders.contains(oldName)) {
        folders.remove(oldName);
        folders.add(newName);
        await _userDoc.update({'folders': folders});
        final snapshot = await _sessionsCol.where('folderName', isEqualTo: oldName).get();
        final batch = _firestore.batch();
        for (var sDoc in snapshot.docs) {
          batch.update(sDoc.reference, {'folderName': newName});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Klasör Yeniden Adlandırma Hatası: $e");
    }
  }

  @override
  Future<void> deleteFolder(String folderName, {bool moveToGeneral = true}) async {
    if (folderName == 'Genel Çalışma') return;
    try {
      await _ensureUserDocExists();
      await _userDoc.update({
        'folders': FieldValue.arrayRemove([folderName])
      });
      final snapshot = await _sessionsCol.where('folderName', isEqualTo: folderName).get();
      final batch = _firestore.batch();
      for (var sDoc in snapshot.docs) {
        if (moveToGeneral) {
          batch.update(sDoc.reference, {'folderName': 'Genel Çalışma'});
        } else {
          batch.delete(sDoc.reference);
        }
      }

      final taskSnap = await _tasksCol.where('folderName', isEqualTo: folderName).get();
      for (var tDoc in taskSnap.docs) {
        if (moveToGeneral) {
          batch.update(tDoc.reference, {'folderName': 'Genel Çalışma'});
        } else {
          batch.delete(tDoc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Klasör Silme Hatası: $e");
    }
  }

  @override
  Future<List<String>> getAllFolders() async {
    try {
      await _ensureUserDocExists();
      final doc = await _userDoc.get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return ['Genel Çalışma'];
      final data = doc.data() as Map<String, dynamic>;
      final folders = data['folders'] as List<dynamic>?;
      if (folders == null || folders.isEmpty) return ['Genel Çalışma'];
      return folders.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("Klasörleri Getirme Hatası: $e");
      return ['Genel Çalışma'];
    }
  }

  @override
  Future<List<String>> getTasksForFolder(String folderName) async {
    try {
      final snapshot = await _sessionsCol.where('folderName', isEqualTo: folderName).get();
      final Set<String> tasks = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['taskName'] != null && data['taskName'].toString().isNotEmpty) {
          tasks.add(data['taskName'].toString());
        }
      }
      return tasks.toList();
    } catch (e) {
      debugPrint("Görevleri Getirme Hatası: $e");
      return [];
    }
  }

  @override
  Future<List<FocusSession>> getSessionsForFolder(String folderName) async {
    try {
      final snapshot = await _sessionsCol
          .where('folderName', isEqualTo: folderName)
          .get();
      List<FocusSession> sessions = snapshot.docs
          .map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    } catch (e) {
      debugPrint("Klasör Seansları Getirme Hatası: $e");
      return [];
    }
  }

  @override
  Future<void> deleteSession(FocusSession session) async {
    try {
      if (session.id != null) {
        await _sessionsCol.doc(session.id).delete();
      }
    } catch (e) {
      debugPrint("Seans Silme Hatası: $e");
    }
  }

  @override
  Future<int> getDailyGoal() async {
    try {
      await _ensureUserDocExists();
      final doc = await _userDoc.get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['dailyGoal'] ?? 240;
      }
      return 240;
    } catch (e) {
      return 240;
    }
  }

  @override
  Future<void> setDailyGoal(int minutes) async {
    try {
      await _ensureUserDocExists();
      await _userDoc.update({'dailyGoal': minutes});
    } catch (e) {
      debugPrint("Günlük Hedef Belirleme Hatası: $e");
    }
  }

  @override
  Future<bool> getSetting(String key, bool defaultValue) async {
    try {
      await _ensureUserDocExists();
      final doc = await _userDoc.get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['settings'] != null && data['settings'][key] != null) {
          return data['settings'][key] as bool;
        }
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Future<void> saveSetting(String key, bool value) async {
    try {
      await _ensureUserDocExists();
      await _userDoc.update({
        'settings.$key': value
      });
    } catch (e) {
      debugPrint("Ayar Kaydetme Hatası: $e");
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      final snapshot = await _sessionsCol.get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      final tasksSnapshot = await _tasksCol.get();
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _userDoc.set({
        'dailyGoal': 240,
        'folders': ['Genel Çalışma'],
        'settings': {
          'darkMode': false,
          'notifications': true,
          'keepScreenAwake': true,
          'autoStartBreaks': false,
          'haptics': true,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Verileri Temizleme Hatası: $e");
    }
  }

  // --- AJANDA GÖREV (TASK) YÖNETİMİ ---

  @override
  Future<void> addAgendaTask(AgendaTask task) async {
    try {
      await _ensureUserDocExists();
      await _tasksCol.add(task.toJson());
    } catch (e) {
      debugPrint("Görev Ekleme Hatası: $e");
    }
  }

  @override
  Future<List<AgendaTask>> getAgendaTasks() async {
    try {
      final snapshot = await _tasksCol.get();
      List<AgendaTask> tasks = snapshot.docs.map((doc) => AgendaTask.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();

      // Görevleri sıralama: Pinned > OrderIndex (Sürükle bırak sıralaması)
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.orderIndex.compareTo(b.orderIndex); // Yeni sürükle bırak sıralamasına göre
      });

      return tasks;
    } catch (e) {
      debugPrint("Görevleri Çekme Hatası: $e");
      return [];
    }
  }

  @override
  Future<void> updateAgendaTask(AgendaTask task) async {
    try {
      if (task.id != null) {
        await _tasksCol.doc(task.id).update(task.toJson());
      }
    } catch (e) {
      debugPrint("Görev Güncelleme Hatası: $e");
    }
  }

  @override
  Future<void> deleteAgendaTask(String taskId) async {
    try {
      await _tasksCol.doc(taskId).delete();
    } catch (e) {
      debugPrint("Görev Silme Hatası: $e");
    }
  }

  @override
  Future<List<String>> getPendingAgendaTaskNames(String folderName) async {
    try {
      final snapshot = await _tasksCol
          .where('folderName', isEqualTo: folderName)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['title'].toString()).toList();
    } catch (e) {
      debugPrint("Bekleyen görevleri çekme hatası: $e");
      return [];
    }
  }

  // YENİ EKLENDİ: Sürükle-bırak (Drag & Drop) sonrası toplu sıra kaydetme
  @override
  Future<void> updateTaskOrders(List<AgendaTask> tasks) async {
    try {
      final batch = _firestore.batch();
      for (var task in tasks) {
        if (task.id != null) {
          batch.update(_tasksCol.doc(task.id), {'orderIndex': task.orderIndex});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Sıralama Güncelleme Hatası: $e");
    }
  }
}