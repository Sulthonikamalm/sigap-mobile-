import '../../domain/entities/kasus_item.dart';
import '../../domain/repositories/kasus_repository.dart';
import '../mock/mock_kasus_data.dart';

/// Tipe role satgas yang menentukan sumber data.
enum SatgasRole { admin, psikolog }

/// Implementasi Mock dari [KasusRepository].
///
/// Simulasi operasi asinkron layaknya koneksi ke API. Saat integrasi
/// API asli, cukup buat class baru `ApiKasusRepository implements KasusRepository`
/// tanpa menyentuh UI sedikitpun.
class MockKasusRepository implements KasusRepository {
  final SatgasRole role;

  /// Simulasi "database" lokal — di-manage sebagai state in-memory.
  List<KasusItem> _cachedItems = [];

  MockKasusRepository({required this.role});

  @override
  Future<List<KasusItem>> getKasusList() async {
    // Simulasi network latency
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _cachedItems = switch (role) {
      SatgasRole.admin => MockKasusData.getAdminQueue(),
      SatgasRole.psikolog => MockKasusData.getPsikologSchedule(),
    };

    return List.unmodifiable(_cachedItems);
  }

  @override
  Future<bool> terimaKasus(int kasusId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Simulasi: Selalu berhasil di mock.
    // Di production, ini akan melakukan HTTP POST dan validasi response code.
    _cachedItems = _cachedItems.where((k) => k.id != kasusId).toList();
    return true;
  }

  @override
  Future<bool> tolakKasus(int kasusId, String alasan) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _cachedItems = _cachedItems.where((k) => k.id != kasusId).toList();
    return true;
  }

  @override
  Future<bool> mulaiSesi(int kasusId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> selesaikanSesi(int kasusId, String catatan) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _cachedItems = _cachedItems.where((k) => k.id != kasusId).toList();
    return true;
  }
}
