import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/local_db.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';
import '../../shared/app_logo_mark.dart';
import '../../shared/preview_app_bar.dart';

class NovoContatoScreen extends StatefulWidget {
  const NovoContatoScreen({super.key});

  @override
  State<NovoContatoScreen> createState() => _NovoContatoScreenState();
}

class _NovoContatoScreenState extends State<NovoContatoScreen> {
  final _form = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;
  final _picker = ImagePicker();

  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _poloNomeCtrl = TextEditingController();
  final _codigoRevisaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  bool _consentimento = false;
  String _canal = 'WhatsApp';
  String _nivelRelacionamento = 'CONTATO';
  String _engajamento = 'FRIO';
  bool _ehLideranca = false;
  bool _ehApoiador = false;
  bool _ehBeneficiario = false;
  bool _ehParceria = false;
  bool _beneficiarioPolo = false;
  Uint8List? _fotoBytes;
  String? _fotoBase64;

  List<String> get _stepTitles => const [
        'Dados Básicos',
        'Classificação',
        'Consentimento',
      ];

  Future<void> _pickFoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 76,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoBytes = bytes;
      _fotoBase64 = base64Encode(bytes);
    });
  }

  void _removeFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoBase64 = null;
    });
  }

  void _toggleFinalidade(String key, bool value) {
    setState(() {
      switch (key) {
        case 'lideranca':
          _ehLideranca = value;
          break;
        case 'apoiador':
          _ehApoiador = value;
          break;
        case 'beneficiario':
          _ehBeneficiario = value;
          break;
        case 'parceria':
          _ehParceria = value;
          break;
      }
    });
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (kIsWeb && AppConstants.previewMode) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contato salvo no modo preview.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
        return;
      }

      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final db = await LocalDb.instance;

      await db.insert(AppConstants.tContatos, {
        'id': id,
        'nome': _nomeCtrl.text.trim(),
        'telefone_principal': _telefoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'cpf': _cpfCtrl.text.trim(),
        'bairro': _bairroCtrl.text.trim(),
        'cidade': _cidadeCtrl.text.trim(),
        'nivel_relacionamento': _nivelRelacionamento,
        'engajamento': _engajamento,
        'eh_lideranca': _ehLideranca ? 1 : 0,
        'eh_apoiador': _ehApoiador ? 1 : 0,
        'eh_beneficiario': _ehBeneficiario ? 1 : 0,
        'eh_parceria': _ehParceria ? 1 : 0,
        'beneficiario_polo': _beneficiarioPolo ? 1 : 0,
        'polo_nome': _poloNomeCtrl.text.trim(),
        'codigo_revisa': _codigoRevisaCtrl.text.trim(),
        'revisa_sync_status': _beneficiarioPolo ? 'PENDENTE_IMPORTACAO' : 'NAO_APLICAVEL',
        'foto_base64': _fotoBase64,
        'consentimento_registrado': _consentimento ? 1 : 0,
        'canal_permitido': _canal,
        'observacoes': _obsCtrl.text.trim(),
        'status': _consentimento ? 'ATIVO' : 'RESTRITO',
        'sync_status': 'PENDENTE',
        'created_at': now,
      });

      await SyncService.enqueue(
        clientId: id,
        entidade: 'contato',
        payload: {
          'nome': _nomeCtrl.text.trim(),
          'telefone_principal': _telefoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'cpf': _cpfCtrl.text.trim(),
          'bairro': _bairroCtrl.text.trim(),
          'cidade': _cidadeCtrl.text.trim(),
          'tipo_contato': _beneficiarioPolo
              ? 'BENEFICIARIO_POLO'
              : _ehParceria
                  ? 'PARCERIA'
                  : 'CIDADAO',
          'nivel_relacionamento': _nivelRelacionamento,
          'engajamento': _engajamento,
          'eh_lideranca': _ehLideranca,
          'eh_apoiador': _ehApoiador,
          'eh_beneficiario': _ehBeneficiario,
          'eh_parceria': _ehParceria,
          'beneficiario_polo': _beneficiarioPolo,
          'polo_nome': _poloNomeCtrl.text.trim(),
          'codigo_revisa': _codigoRevisaCtrl.text.trim(),
          'revisa_sync_status': _beneficiarioPolo ? 'PENDENTE_IMPORTACAO' : 'NAO_APLICAVEL',
          'foto_base64': _fotoBase64,
          'consentimento_registrado': _consentimento,
          'canal_permitido': _canal,
          'observacoes': _obsCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contato salvo! Será sincronizado em breve.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o contato agora.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreviewAppBar(title: _stepTitles[_step], replaceOnNavigate: true),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              if (_step == 0) _buildDados(),
              if (_step == 1) _buildClassificacao(),
              if (_step == 2) _buildConsentimento(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _step < 2
            ? ElevatedButton(
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    setState(() => _step += 1);
                  }
                },
                child: const Text('Avançar'),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _salvar,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F9FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppLogoMark(size: 56, showHalo: false),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo contato',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              _stepTitles.length,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == _stepTitles.length - 1 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: index <= _step
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${index + 1}. ${_stepTitles[index]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index <= _step ? AppTheme.primary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoPicker(),
        const SizedBox(height: 18),
        _field(_nomeCtrl, 'Nome completo *', required: true),
        _field(_telefoneCtrl, 'Telefone / WhatsApp', type: TextInputType.phone),
        _field(_emailCtrl, 'E-mail', type: TextInputType.emailAddress),
        _field(_cpfCtrl, 'CPF (opcional)', type: TextInputType.number),
        _field(_bairroCtrl, 'Bairro'),
        _field(_cidadeCtrl, 'Cidade'),
        _field(_obsCtrl, 'Observações', maxLines: 3),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto do cadastrado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 84,
                  height: 84,
                  color: const Color(0xFFF1F5F9),
                  child: _fotoBytes != null
                      ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.person_search, color: AppTheme.textSecondary, size: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(_fotoBytes == null ? 'Inserir foto' : 'Trocar foto'),
                    ),
                    if (_fotoBytes != null)
                      TextButton.icon(
                        onPressed: _removeFoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remover'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _nivelRelacionamento,
          decoration: const InputDecoration(labelText: 'Status político / relacionamento'),
          items: const [
            DropdownMenuItem(value: 'CONTATO', child: Text('Contato')), 
            DropdownMenuItem(value: 'LIDERANCA', child: Text('Liderança')), 
            DropdownMenuItem(value: 'APOIADOR', child: Text('Apoiador')), 
            DropdownMenuItem(value: 'BENEFICIARIO', child: Text('Beneficiário')), 
            DropdownMenuItem(value: 'PARCERIA', child: Text('Parceria')), 
          ],
          onChanged: (value) => setState(() => _nivelRelacionamento = value ?? 'CONTATO'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _engajamento,
          decoration: const InputDecoration(labelText: 'Engajamento político'),
          items: const [
            DropdownMenuItem(value: 'FRIO', child: Text('Frio')), 
            DropdownMenuItem(value: 'MORNO', child: Text('Morno')), 
            DropdownMenuItem(value: 'QUENTE', child: Text('Quente')), 
            DropdownMenuItem(value: 'FORTE', child: Text('Forte')), 
          ],
          onChanged: (value) => setState(() => _engajamento = value ?? 'FRIO'),
        ),
        const SizedBox(height: 18),
        const Text(
          'Finalidade',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildFlagTile(
          title: 'Liderança',
          subtitle: 'Referência local com influência comunitária.',
          value: _ehLideranca,
          onChanged: (value) => _toggleFinalidade('lideranca', value),
        ),
        _buildFlagTile(
          title: 'Apoiador',
          subtitle: 'Base de mobilização para ações do mandato.',
          value: _ehApoiador,
          onChanged: (value) => _toggleFinalidade('apoiador', value),
        ),
        _buildFlagTile(
          title: 'Beneficiário',
          subtitle: 'Pessoa vinculada a atendimento, programa ou benefício.',
          value: _ehBeneficiario,
          onChanged: (value) => _toggleFinalidade('beneficiario', value),
        ),
        _buildFlagTile(
          title: 'Parceria',
          subtitle: 'Instituição ou ator-chave para encaminhamento e agenda.',
          value: _ehParceria,
          onChanged: (value) => _toggleFinalidade('parceria', value),
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          value: _beneficiarioPolo,
          onChanged: (value) => setState(() {
            _beneficiarioPolo = value;
            if (value) {
              _ehBeneficiario = true;
              _nivelRelacionamento = 'BENEFICIARIO';
            }
          }),
          title: const Text('Beneficiário de Polo / pronto para REVISA'),
          subtitle: null,
          activeThumbColor: AppTheme.primary,
          contentPadding: EdgeInsets.zero,
        ),
        if (_beneficiarioPolo) ...[
          const SizedBox(height: 8),
          _field(_poloNomeCtrl, 'Nome do Polo *', required: true),
          _field(_codigoRevisaCtrl, 'Código do beneficiário na REVISA (opcional)'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('PENDENTE_IMPORTACAO', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _buildConsentimento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consentimento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            'Resumo: $_nivelRelacionamento • $_engajamento${_beneficiarioPolo ? ' • REVISA/Polo' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          value: _consentimento,
          onChanged: (value) => setState(() => _consentimento = value),
          title: const Text('Consentimento registrado?'),
          subtitle: const Text('Verbal ou escrito'),
          activeThumbColor: AppTheme.primary,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _canal,
          decoration: const InputDecoration(labelText: 'Canal permitido'),
          items: ['WhatsApp', 'Telefone', 'E-mail', 'Todos']
              .map((canal) => DropdownMenuItem(value: canal, child: Text(canal)))
              .toList(),
          onChanged: (value) => setState(() => _canal = value!),
        ),
        if (!_consentimento)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warning, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sem consentimento, o contato terá restrições de uso.',
                    style: TextStyle(color: AppTheme.warning, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFlagTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (checked) => onChanged(checked ?? false),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        activeColor: AppTheme.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}
