import 'package:flutter/foundation.dart';

import '../models/checklist_model.dart';
import '../services/api_service.dart';
import '../services/checklist_service.dart';

class ChecklistProvider extends ChangeNotifier {
  ChecklistProvider({required ChecklistService checklistService})
      : _checklistService = checklistService;

  final ChecklistService _checklistService;

  List<ChecklistModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ChecklistModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get progress {
    if (_items.isEmpty) {
      return 0;
    }
    final takenCount = _items.where((item) => item.taken).length;
    return takenCount / _items.length;
  }

  int get takenCount => _items.where((item) => item.taken).length;

  Future<void> fetchTodayChecklist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _checklistService.fetchTodayChecklist();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to load today checklist';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsTaken(String medicineId) async {
    _error = null;
    notifyListeners();

    try {
      await _checklistService.markMedicineTaken(medicineId);
      _items = _items
          .map((item) => item.medicineId == medicineId
              ? item.copyWith(taken: true)
              : item)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to mark medicine as taken';
    }

    notifyListeners();
    return false;
  }
}
