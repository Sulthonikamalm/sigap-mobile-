import '../../domain/entities/kasus_item.dart';

/// Data statis mock untuk development — menggantikan hardcoded data di dalam
/// widget ui. Saat integrasi API asli, mock data ini cukup di-disable tanpa
/// merombak apapun di layer atas.
class MockKasusData {
  MockKasusData._();

  /// Data antrean kasus untuk Admin.
  static List<KasusItem> getAdminQueue() {
    return const [
      KasusItem(
        id: 1,
        kode: 'KAS-9921',
        status: KasusStatus.darurat,
        info: 'Mahasiswa melaporkan ancaman fisik dengan bukti foto.',
        waktu: '2 mnt lalu',
        urgency: KasusUrgency.darurat,
      ),
      KasusItem(
        id: 2,
        kode: 'KAS-9920',
        status: KasusStatus.dispute,
        info: 'Banding terhadap putusan sanksi tingkat 2.',
        waktu: '1 jam lalu',
        urgency: KasusUrgency.normal,
      ),
      KasusItem(
        id: 3,
        kode: 'KAS-9915',
        status: KasusStatus.pending,
        info: 'Laporan pelecehan verbal melalui chat, menunggu proses.',
        waktu: '3 jam lalu',
        urgency: KasusUrgency.normal,
      ),
    ];
  }

  /// Data jadwal konsultasi untuk Psikolog.
  static List<KasusItem> getPsikologSchedule() {
    return const [
      KasusItem(
        id: 101,
        kode: 'KSL-8841',
        status: KasusStatus.terjadwal,
        info: 'Konseling kecemasan akademik (Virtual)',
        waktu: 'Hari ini, 14:00',
        urgency: KasusUrgency.normal,
      ),
      KasusItem(
        id: 102,
        kode: 'KSL-8842',
        status: KasusStatus.dispute,
        info: 'Rekomendasi cuti akademik ditolak prodi.',
        waktu: 'Besok, 09:00',
        urgency: KasusUrgency.darurat,
      ),
    ];
  }
}
