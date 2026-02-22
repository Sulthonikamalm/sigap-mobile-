import 'package:http/http.dart' as http;
import 'package:sigap_mobile/features/lapor/data/models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<ReportModel> submitReport({
    required String penyintas,
    required String tingkatKekhawatiran,
    required String genderPenyintas,
    required String pelakuKekerasan,
    required DateTime waktuKejadian,
    required String lokasiKategori,
    String? lokasiDetail,
    required String detailKejadian,
    String? emailPenyintas,
    required String usiaPenyintas,
    required bool isDisabilitas,
    String? jenisDisabilitas,
    String? whatsappPenyintas,
    bool isAnonymous = false,
    required String reporterId,
  });

  Future<List<ReportModel>> getReportsByUser(String userId);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final http.Client client;
  final String baseUrl; // Nanti diisi endpoint backend Go

  ReportRemoteDataSourceImpl(
      {required this.client, this.baseUrl = 'http://localhost:8080/api'});

  @override
  Future<ReportModel> submitReport({
    required String penyintas,
    required String tingkatKekhawatiran,
    required String genderPenyintas,
    required String pelakuKekerasan,
    required DateTime waktuKejadian,
    required String lokasiKategori,
    String? lokasiDetail,
    required String detailKejadian,
    String? emailPenyintas,
    required String usiaPenyintas,
    required bool isDisabilitas,
    String? jenisDisabilitas,
    String? whatsappPenyintas,
    bool isAnonymous = false,
    required String reporterId,
  }) async {
    // Simulasi respons untuk sementara tanpa backend aktif
    await Future.delayed(const Duration(seconds: 1)); // Mock network delay
    return ReportModel(
      id: "REP-${DateTime.now().millisecondsSinceEpoch}",
      penyintas: penyintas,
      tingkatKekhawatiran: tingkatKekhawatiran,
      genderPenyintas: genderPenyintas,
      pelakuKekerasan: pelakuKekerasan,
      waktuKejadian: waktuKejadian,
      lokasiKategori: lokasiKategori,
      lokasiDetail: lokasiDetail,
      detailKejadian: detailKejadian,
      emailPenyintas: emailPenyintas,
      usiaPenyintas: usiaPenyintas,
      isDisabilitas: isDisabilitas,
      jenisDisabilitas: jenisDisabilitas,
      whatsappPenyintas: whatsappPenyintas,
      createdAt: DateTime.now(),
      status: 'pending',
      reporterId: reporterId,
      isAnonymous: isAnonymous,
    );
  }

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Mock network delay
    return []; // Mengembalikan list kosong sementara backend belum ada
  }
}
