import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'properties_api.dart';

class SavedSearchItem {
  final String id;
  final String title;
  final PropertyQuery query;
  final DateTime savedAt;

  SavedSearchItem({
    required this.id,
    required this.title,
    required this.query,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'query': query.toMap(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedSearchItem.fromJson(Map<String, dynamic> j) {
    final qMap = j['query'] is Map ? Map<String, dynamic>.from(j['query']) : <String, dynamic>{};
    return SavedSearchItem(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? 'Saved Search',
      query: PropertyQuery(
        keyword: qMap['keyword']?.toString(),
        listingType: qMap['listingType']?.toString(),
        cityId: qMap['cityId']?.toString(),
        city: qMap['city']?.toString(),
        localityId: qMap['localityId']?.toString(),
        locality: qMap['locality']?.toString(),
        type: qMap['type']?.toString(),
        minPrice: qMap['minPrice'] != null ? (qMap['minPrice'] as num).toDouble() : null,
        maxPrice: qMap['maxPrice'] != null ? (qMap['maxPrice'] as num).toDouble() : null,
        minArea: qMap['minArea'] != null ? (qMap['minArea'] as num).toDouble() : null,
        maxArea: qMap['maxArea'] != null ? (qMap['maxArea'] as num).toDouble() : null,
        beds: qMap['beds'] != null ? (qMap['beds'] as num).toInt() : null,
        baths: qMap['baths'] != null ? (qMap['baths'] as num).toInt() : null,
        furnishing: qMap['furnishing']?.toString(),
        facing: qMap['facing']?.toString(),
        postedWithinDays: qMap['postedWithinDays'] != null ? (qMap['postedWithinDays'] as num).toInt() : null,
        sort: qMap['sort']?.toString() ?? 'newest',
      ),
      savedAt: DateTime.tryParse(j['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

const _recentKey = 'recent_searches_v1';
const _savedKey = 'saved_searches_v1';
const _storage = FlutterSecureStorage();

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _recentKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> addSearch(String query) async {
    final term = query.trim();
    if (term.isEmpty) return;
    final updated = [term, ...state.where((s) => s.toLowerCase() != term.toLowerCase())];
    final trimmed = updated.take(10).toList();
    state = trimmed;
    try {
      await _storage.write(key: _recentKey, value: jsonEncode(trimmed));
    } catch (_) {}
  }

  Future<void> removeSearch(String query) async {
    final updated = state.where((s) => s != query).toList();
    state = updated;
    try {
      await _storage.write(key: _recentKey, value: jsonEncode(updated));
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = const [];
    try {
      await _storage.delete(key: _recentKey);
    } catch (_) {}
  }
}

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class SavedSearchesNotifier extends StateNotifier<List<SavedSearchItem>> {
  SavedSearchesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _savedKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((j) => SavedSearchItem.fromJson(j as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> saveSearch(String title, PropertyQuery query) async {
    final newItem = SavedSearchItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Saved Search' : title.trim(),
      query: query,
      savedAt: DateTime.now(),
    );
    final updated = [newItem, ...state];
    state = updated;
    await _saveToStorage(updated);
  }

  Future<void> removeSavedSearch(String id) async {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    await _saveToStorage(updated);
  }

  Future<void> _saveToStorage(List<SavedSearchItem> items) async {
    try {
      final raw = jsonEncode(items.map((i) => i.toJson()).toList());
      await _storage.write(key: _savedKey, value: raw);
    } catch (_) {}
  }
}

final savedSearchesProvider = StateNotifierProvider<SavedSearchesNotifier, List<SavedSearchItem>>((ref) {
  return SavedSearchesNotifier();
});
