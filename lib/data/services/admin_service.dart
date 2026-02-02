import 'api_service.dart';

class AdminUser {
  final String uid;
  final String? email;
  final String role;
  final String status;

  const AdminUser({
    required this.uid,
    this.email,
    required this.role,
    required this.status,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'active',
    );
  }
}

class AdminSummary {
  final int usersCount;
  final int transactionsCount;
  final int walletsCount;
  final int budgetsCount;

  const AdminSummary({
    required this.usersCount,
    required this.transactionsCount,
    required this.walletsCount,
    required this.budgetsCount,
  });

  factory AdminSummary.fromMap(Map<String, dynamic> map) {
    return AdminSummary(
      usersCount: (map['usersCount'] as num?)?.toInt() ?? 0,
      transactionsCount: (map['transactionsCount'] as num?)?.toInt() ?? 0,
      walletsCount: (map['walletsCount'] as num?)?.toInt() ?? 0,
      budgetsCount: (map['budgetsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminService {
  final ApiService _apiService = ApiService();

  Future<bool> isAdmin() async {
    try {
      final statusCode = await _apiService.getStatus('/admin/summary');
      return statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AdminSummary> fetchSummary() async {
    final data = await _apiService.get('/admin/summary') as Map;
    return AdminSummary.fromMap(Map<String, dynamic>.from(data));
  }

  Future<List<AdminUser>> fetchUsers() async {
    final data = await _apiService.get('/admin/users');
    if (data is List) {
      return data
          .map((item) => AdminUser.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> updateUserStatus(String uid, String status) async {
    await _apiService.post('/admin/user/$uid/status?status=$status', {});
  }
}
