class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8010',
  );
  static const bool previewMode = bool.fromEnvironment(
    'PREVIEW_MODE',
    defaultValue: false,
  );
  static const String dbName = 'gabinete_ia_local.db';
  static const int dbVersion = 2;

  static const String tContatos = 'contatos_local';
  static const String tDemandas = 'demandas_local';
  static const String tVisitas = 'visitas_local';
  static const String tSyncQueue = 'sync_queue';
}
