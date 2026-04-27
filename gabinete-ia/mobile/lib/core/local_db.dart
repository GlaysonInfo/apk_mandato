import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'constants.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return databaseFactory.openDatabase(
        AppConstants.dbName,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final ffiPath = join(
        await databaseFactory.getDatabasesPath(),
        AppConstants.dbName,
      );
      return databaseFactory.openDatabase(
        ffiPath,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tContatos} (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefone_principal TEXT,
        email TEXT,
        cpf TEXT,
        bairro TEXT,
        cidade TEXT,
        territorio_id TEXT,
        nivel_relacionamento TEXT DEFAULT 'CONTATO',
        engajamento TEXT DEFAULT 'FRIO',
        eh_lideranca INTEGER DEFAULT 0,
        eh_apoiador INTEGER DEFAULT 0,
        eh_beneficiario INTEGER DEFAULT 0,
        eh_parceria INTEGER DEFAULT 0,
        beneficiario_polo INTEGER DEFAULT 0,
        polo_nome TEXT,
        codigo_revisa TEXT,
        revisa_sync_status TEXT DEFAULT 'NAO_ENVIADO',
        foto_base64 TEXT,
        consentimento_registrado INTEGER DEFAULT 0,
        canal_permitido TEXT,
        observacoes TEXT,
        status TEXT DEFAULT 'ATIVO',
        sync_status TEXT DEFAULT 'PENDENTE',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tDemandas} (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        categoria TEXT,
        prioridade TEXT DEFAULT 'MEDIA',
        cidadao_id TEXT,
        territorio_id TEXT,
        status TEXT DEFAULT 'ABERTA',
        sync_status TEXT DEFAULT 'PENDENTE',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tVisitas} (
        id TEXT PRIMARY KEY,
        tipo TEXT DEFAULT 'VISITA_DOMICILIAR',
        data_hora TEXT NOT NULL,
        resultado TEXT DEFAULT 'REALIZADA',
        observacao TEXT,
        cidadao_id TEXT,
        territorio_id TEXT,
        sync_status TEXT DEFAULT 'PENDENTE',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tSyncQueue} (
        id TEXT PRIMARY KEY,
        client_generated_id TEXT NOT NULL UNIQUE,
        entidade TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'PENDENTE',
        tentativas INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN nivel_relacionamento TEXT DEFAULT ''CONTATO''',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN engajamento TEXT DEFAULT ''FRIO''',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN eh_lideranca INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN eh_apoiador INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN eh_beneficiario INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN eh_parceria INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN beneficiario_polo INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN polo_nome TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN codigo_revisa TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN revisa_sync_status TEXT DEFAULT ''NAO_ENVIADO''',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tContatos} ADD COLUMN foto_base64 TEXT',
      );
    }
  }
}
