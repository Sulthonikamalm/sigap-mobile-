// Domain Entity — representasi data kasus yang bersih dan type-safe.
//
// Entity ini tidak bergantung pada framework apapun (tidak import Flutter).
// Digunakan di seluruh layer: domain, data, dan presentation.

/// Tingkat urgensi kasus.
enum KasusUrgency {
  darurat('darurat'),
  normal('normal');

  final String value;
  const KasusUrgency(this.value);

  bool get isDarurat => this == KasusUrgency.darurat;
}

/// Status proses kasus.
enum KasusStatus {
  darurat('Darurat'),
  dispute('Dispute'),
  pending('Pending'),
  terjadwal('Terjadwal');

  final String label;
  const KasusStatus(this.label);
}

/// Filter yang tersedia untuk daftar kasus.
enum KasusFilter {
  terbaru('Terbaru'),
  mendesak('Mendesak'),
  hariIni('Hari Ini'),
  mingguIni('Minggu Ini'),
  dispute('Status Dispute');

  final String label;
  const KasusFilter(this.label);
}

/// Immutable model yang merepresentasikan satu item kasus laporan.
class KasusItem {
  final int id;
  final String kode;
  final KasusStatus status;
  final String info;
  final String waktu;
  final KasusUrgency urgency;

  const KasusItem({
    required this.id,
    required this.kode,
    required this.status,
    required this.info,
    required this.waktu,
    required this.urgency,
  });

  bool get isDarurat => urgency.isDarurat;

  /// Konversi ke Map legacy (agar backward-compatible dengan widget
  /// yang masih mengonsumsi `Map<String, dynamic>`).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'status': status.label,
      'info': info,
      'waktu': waktu,
      'darurat': urgency.value,
    };
  }

  KasusItem copyWith({
    int? id,
    String? kode,
    KasusStatus? status,
    String? info,
    String? waktu,
    KasusUrgency? urgency,
  }) {
    return KasusItem(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      status: status ?? this.status,
      info: info ?? this.info,
      waktu: waktu ?? this.waktu,
      urgency: urgency ?? this.urgency,
    );
  }
}
