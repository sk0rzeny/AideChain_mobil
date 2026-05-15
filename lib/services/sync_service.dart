import 'package:dio/dio.dart';
import 'api_service.dart';
import 'db_service.dart';

class SyncService {
  static Future<SyncResult> syncPending() async {
    final pending = await DbService.getPendingDistributions();
    int synced = 0;
    int failed = 0;

    for (final row in pending) {
      try {
        await ApiService.distribuerAide(
          beneficiaireId: row['beneficiaire_id'] as int,
          projetAideId: row['projet_aide_id'] as int,
          notes: row['notes'] as String?,
        );
        await DbService.deleteDistribution(row['id'] as int);
        synced++;
      } on DioException catch (e) {
        // 409 doublon détecté côté serveur → supprimer de la file, déjà distribué
        if (e.response?.statusCode == 409) {
          await DbService.deleteDistribution(row['id'] as int);
          synced++;
        } else {
          failed++;
        }
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}
