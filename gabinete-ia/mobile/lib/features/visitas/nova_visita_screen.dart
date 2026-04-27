import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/local_db.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class NovaVisitaScreen extends StatefulWidget {
  const NovaVisitaScreen({super.key});

  @override
  State<NovaVisitaScreen> createState() => _NovaVisitaScreenState();
}

class _NovaVisitaScreenState extends State<NovaVisitaScreen> {
  final _form = GlobalKey<FormState>();
  final _obsCtrl = TextEditingController();
  DateTime _dataHora = DateTime.now();
  String _tipo = 'VISITA_DOMICILIAR';
  String _resultado = 'REALIZADA';
  bool _saving = false;

  final _tipos = ['VISITA_DOMICILIAR', 'REUNIAO_COMUNITARIA', 'EVENTO', 'OUTRO'];
  final _resultados = ['REALIZADA', 'NAO_ENCONTRADO', 'REAGENDADA', 'CANCELADA'];

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (pickedTime == null) return;

    setState(() {
      _dataHora = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
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
            content: Text('Visita salva no modo preview.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
        return;
      }

      final id = const Uuid().v4();
      final db = await LocalDb.instance;

      await db.insert(AppConstants.tVisitas, {
        'id': id,
        'tipo': _tipo,
        'data_hora': _dataHora.toIso8601String(),
        'resultado': _resultado,
        'observacao': _obsCtrl.text.trim(),
        'sync_status': 'PENDENTE',
        'created_at': DateTime.now().toIso8601String(),
      });

      await SyncService.enqueue(
        clientId: id,
        entidade: 'visita',
        payload: {
          'tipo': _tipo,
          'data_hora': _dataHora.toIso8601String(),
          'resultado': _resultado,
          'observacao': _obsCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita registrada com sucesso!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a visita agora.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreviewAppBar(title: 'Nova Visita', replaceOnNavigate: true),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de visita'),
                items: _tipos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                onChanged: (value) => setState(() => _tipo = value!),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data e Hora'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(_dataHora)),
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _resultado,
                decoration: const InputDecoration(labelText: 'Resultado'),
                items: _resultados
                    .map((resultado) => DropdownMenuItem(value: resultado, child: Text(resultado)))
                    .toList(),
                onChanged: (value) => setState(() => _resultado = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _obsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
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
                    : const Text('Salvar Visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
