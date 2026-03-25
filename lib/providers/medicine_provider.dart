import 'package:flutter/foundation.dart';

import '../models/medicine_model.dart';
import '../services/api_service.dart';
import '../services/medicine_service.dart';

class MedicineProvider extends ChangeNotifier {
  MedicineProvider({required MedicineService medicineService})
      : _medicineService = medicineService;

  final MedicineService _medicineService;

  List<MedicineModel> _medicines = [];
  bool _isLoading = false;
  String? _error;

  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMedicines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicines = await _medicineService.fetchMedicines();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to fetch medicines';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMedicine(MedicineModel medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _medicineService.addMedicine(medicine);
      _medicines = [created, ..._medicines];
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to add medicine';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateMedicine(MedicineModel medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _medicineService.updateMedicine(medicine);
      _medicines = _medicines
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to update medicine';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteMedicine(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicineService.deleteMedicine(id);
      _medicines = _medicines.where((item) => item.id != id).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to delete medicine';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
