import '../models/appointment_model.dart';
import '../models/appointment_slot_model.dart';
import 'api_service.dart';

class AppointmentService {
  AppointmentService(this._apiService);

  final ApiService _apiService;

  Future<List<AppointmentSlotModel>> fetchSpecialistSlots(
    String specialistId, {
    bool availableOnly = true,
  }) async {
    final query = Uri(
      queryParameters: {
        'specialist_id': specialistId,
        'available_only': availableOnly.toString(),
      },
    ).query;

    final response = await _apiService.get('/appointments/slots?$query');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected appointment slots response');
    }

    final items = response['items'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => AppointmentSlotModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AppointmentSlotModel>> fetchMySlots() async {
    final response = await _apiService.get('/appointments/slots/mine');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected slot response');
    }

    final items = response['items'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => AppointmentSlotModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createSlot({
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    await _apiService.post(
      '/appointments/slots',
      body: {
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> bookAppointment({
    required String slotId,
    String notes = '',
  }) async {
    await _apiService.post(
      '/appointments/book',
      body: {
        'slot_id': slotId,
        'notes': notes,
      },
    );
  }

  Future<List<AppointmentModel>> fetchMyAppointments() async {
    final response = await _apiService.get('/appointments/mine');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected appointments response');
    }

    final items = response['items'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => AppointmentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
