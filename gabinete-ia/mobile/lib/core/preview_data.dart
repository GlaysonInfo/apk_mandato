class PreviewData {
  static const userName = 'Marina Costa';
  static const userRole = 'COLABORADOR_EXTERNO';
  static const gabineteId = 'preview-gabinete';
  static const territoryName = 'Regional Centro-Norte';

  static final jornada = {
    'titulo': 'Roteiro de campo ativo',
    'descricao': 'Bairros Central, Boa Vista e Vila Esperanca com foco em zeladoria e saude.',
    'periodo': '08:30 - 17:30',
    'responsavel': 'Equipe Territorio 03',
  };

  static final agenda = [
    {
      'id': 'agenda-1',
      'titulo': 'Visita ao Bairro Central',
      'descricao': 'Reunião com moradores sobre iluminação pública.',
      'local': 'Associacao de Moradores do Centro',
      'data_hora_inicio': DateTime.now()
          .copyWith(hour: 9, minute: 0, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'data_hora_fim': DateTime.now()
          .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'status': 'CONFIRMADO',
    },
    {
      'id': 'agenda-2',
      'titulo': 'Atendimento itinerante',
      'descricao': 'Triagem de demandas de saúde e mobilidade.',
      'local': 'Praca da Boa Vista',
      'data_hora_inicio': DateTime.now()
          .copyWith(hour: 14, minute: 30, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'data_hora_fim': DateTime.now()
          .copyWith(hour: 16, minute: 0, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'status': 'AGENDADO',
    },
    {
      'id': 'agenda-3',
      'titulo': 'Retorno com unidade de obras',
      'descricao': 'Validar cronograma para tapa-buracos nas ruas 7 e 9.',
      'local': 'Vila Esperanca',
      'data_hora_inicio': DateTime.now()
          .copyWith(hour: 17, minute: 0, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'data_hora_fim': DateTime.now()
          .copyWith(hour: 17, minute: 40, second: 0, millisecond: 0, microsecond: 0)
          .toIso8601String(),
      'status': 'PENDENTE',
    },
  ];

  static final contatos = [
    {
      'id': 'contato-1',
      'nome': 'João Pereira',
      'bairro': 'Centro',
      'canal_origem': 'Mutirao de atendimento',
      'telefone': '(11) 99811-2201',
      'sync_status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 'contato-2',
      'nome': 'Luciana Alves',
      'bairro': 'Boa Vista',
      'canal_origem': 'WhatsApp do gabinete',
      'telefone': '(11) 99777-1040',
      'sync_status': 'PENDENTE',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'contato-3',
      'nome': 'Carlos Henrique',
      'bairro': 'Vila Esperanca',
      'canal_origem': 'Visita domiciliar',
      'telefone': '(11) 99125-8841',
      'sync_status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(days: 2, hours: 4)).toIso8601String(),
    },
    {
      'id': 'contato-4',
      'nome': 'Ana Beatriz Souza',
      'bairro': 'Jardim das Flores',
      'canal_origem': 'Encaminhamento da escola',
      'telefone': '(11) 99441-6723',
      'sync_status': 'ERRO',
      'created_at': DateTime.now().subtract(const Duration(days: 3, hours: 1)).toIso8601String(),
    },
  ];

  static final demandas = [
    {
      'id': 'demanda-1',
      'titulo': 'Poda de árvore em frente à escola',
      'area': 'Zeladoria',
      'prioridade': 'ALTA',
      'bairro': 'Centro',
      'sync_status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': 'demanda-2',
      'titulo': 'Solicitação de consulta pediátrica',
      'area': 'Saude',
      'prioridade': 'MEDIA',
      'bairro': 'Boa Vista',
      'sync_status': 'ERRO',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'demanda-3',
      'titulo': 'Troca de lâmpadas na Rua dos Jasmins',
      'area': 'Iluminacao',
      'prioridade': 'ALTA',
      'bairro': 'Jardim das Flores',
      'sync_status': 'PENDENTE',
      'created_at': DateTime.now().subtract(const Duration(hours: 18)).toIso8601String(),
    },
    {
      'id': 'demanda-4',
      'titulo': 'Cadastro para transporte social',
      'area': 'Assistencia Social',
      'prioridade': 'BAIXA',
      'bairro': 'Vila Esperanca',
      'sync_status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    },
  ];

  static final visitas = [
    {
      'id': 'visita-1',
      'tipo': 'VISITA_DOMICILIAR',
      'local': 'Rua das Palmeiras, 140',
      'bairro': 'Centro',
      'sync_status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'id': 'visita-2',
      'tipo': 'REUNIAO_COMUNITARIA',
      'local': 'Centro Comunitario Boa Vista',
      'bairro': 'Boa Vista',
      'sync_status': 'PENDENTE',
      'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
    },
    {
      'id': 'visita-3',
      'tipo': 'FISCALIZACAO_PONTO_CRITICO',
      'local': 'Canal da Vila Esperanca',
      'bairro': 'Vila Esperanca',
      'sync_status': 'ERRO',
      'created_at': DateTime.now().subtract(const Duration(hours: 9)).toIso8601String(),
    },
  ];

  static final syncQueue = [
    {
      'id': 'sync-1',
      'client_generated_id': 'sync-1',
      'entidade': 'contato',
      'descricao': 'Novo cadastro de João Pereira',
      'status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 'sync-2',
      'client_generated_id': 'sync-2',
      'entidade': 'demanda',
      'descricao': 'Poda de arvore em frente a escola',
      'status': 'PENDENTE',
      'created_at': DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
    },
    {
      'id': 'sync-3',
      'client_generated_id': 'sync-3',
      'entidade': 'visita',
      'descricao': 'Fiscalizacao do canal da Vila Esperanca',
      'status': 'ERRO',
      'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
    },
    {
      'id': 'sync-4',
      'client_generated_id': 'sync-4',
      'entidade': 'demanda',
      'descricao': 'Troca de lampadas na Rua dos Jasmins',
      'status': 'ENVIADO',
      'created_at': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
    },
  ];

  static List<Map<String, dynamic>> get dashboardMetrics => [
        {
          'label': 'Contatos ativos',
          'value': contatos.length.toString(),
          'accent': 'blue',
        },
        {
          'label': 'Demandas altas',
          'value': demandas.where((item) => item['prioridade'] == 'ALTA').length.toString(),
          'accent': 'amber',
        },
        {
          'label': 'Agenda hoje',
          'value': agenda.length.toString(),
          'accent': 'green',
        },
        {
          'label': 'Fila offline',
          'value': syncQueue.where((item) => item['status'] != 'ENVIADO').length.toString(),
          'accent': 'rose',
        },
      ];

  static List<Map<String, dynamic>> get destaques => [
        {
          'titulo': 'Demanda critica',
          'descricao': 'Troca de lampadas na Rua dos Jasmins aguardando despacho.',
          'tag': 'ILUMINACAO',
        },
        {
          'titulo': 'Lideranca acompanhada',
          'descricao': 'Luciana Alves pediu retorno sobre consulta pediatrica ate 16h.',
          'tag': 'SAUDE',
        },
        {
          'titulo': 'Risco mapeado',
          'descricao': 'Canal da Vila Esperanca voltou a registrar descarte irregular.',
          'tag': 'FISCALIZACAO',
        },
      ];
}