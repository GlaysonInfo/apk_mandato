import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/preview_data.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';
import '../../shared/app_logo_mark.dart';
import '../agenda/agenda_screen.dart';
import '../auth/auth_provider.dart';
import '../contatos/novo_contato_screen.dart';
import '../demandas/nova_demanda_screen.dart';
import '../registros/meus_registros_screen.dart';
import '../sync/sync_screen.dart';
import '../visitas/nova_visita_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isOnline = true;
  Map<String, int> _syncResult = {};

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _handleMenuAction(_PreviewMenuAction action) async {
    switch (action) {
      case _PreviewMenuAction.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case _PreviewMenuAction.contato:
        await _openScreen(const NovoContatoScreen());
        break;
      case _PreviewMenuAction.agenda:
        await _openScreen(const AgendaScreen());
        break;
      case _PreviewMenuAction.registros:
        await _openScreen(const MeusRegistrosScreen());
        break;
      case _PreviewMenuAction.sync:
        await _openScreen(const SyncScreen());
        break;
      case _PreviewMenuAction.logout:
        await ref.read(authProvider.notifier).logout();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = result.any((item) => item != ConnectivityResult.none);
      setState(() => _isOnline = hasConnection);
      if (_isOnline) {
        _autoSync();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final hasConnection = result.any((item) => item != ConnectivityResult.none);
    if (mounted) {
      setState(() => _isOnline = hasConnection);
    }
  }

  Future<void> _autoSync() async {
    if (AppConstants.previewMode) {
      return;
    }

    final result = await SyncService.syncAll();
    if (mounted) {
      setState(() => _syncResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 132,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: PopupMenuButton<_PreviewMenuAction>(
            tooltip: 'Menu',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PreviewMenuAction.home,
                child: Text('Início'),
              ),
              PopupMenuItem(
                value: _PreviewMenuAction.contato,
                child: Text('Novo Contato'),
              ),
              PopupMenuItem(
                value: _PreviewMenuAction.agenda,
                child: Text('Agenda'),
              ),
              PopupMenuItem(
                value: _PreviewMenuAction.registros,
                child: Text('Meus Registros'),
              ),
              PopupMenuItem(
                value: _PreviewMenuAction.sync,
                child: Text('Sincronização'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _PreviewMenuAction.logout,
                child: Text('Sair'),
              ),
            ],
            child: const Center(
              child: AppLogoMark(
                size: 34,
                showHalo: false,
                variant: AppLogoVariant.wordmark,
              ),
            ),
          ),
        ),
        title: const Text('Cadastro de Campo'),
        bottom: AppConstants.previewMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TopShortcutChip(
                          label: 'Contato',
                          onTap: () => _handleMenuAction(_PreviewMenuAction.contato),
                        ),
                        _TopShortcutChip(
                          label: 'Agenda',
                          onTap: () => _handleMenuAction(_PreviewMenuAction.agenda),
                        ),
                        _TopShortcutChip(
                          label: 'Registros',
                          onTap: () => _handleMenuAction(_PreviewMenuAction.registros),
                        ),
                        _TopShortcutChip(
                          label: 'Sync',
                          onTap: () => _handleMenuAction(_PreviewMenuAction.sync),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.greenAccent : Colors.white54,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleMenuAction(_PreviewMenuAction.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _autoSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${auth.nome ?? "Colaborador"}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            auth.perfil ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (AppConstants.previewMode)
                            const Text(
                              PreviewData.territoryName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (AppConstants.previewMode) ...[
                const SizedBox(height: 16),
                _PreviewJourneyCard(data: PreviewData.jornada),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: PreviewData.dashboardMetrics.map((metric) {
                    final label = metric['label']?.toString() ?? '';
                    return _PreviewMetricCard(
                      metric: metric,
                      onTap: () {
                        if (label.contains('Contatos')) {
                          _openScreen(const MeusRegistrosScreen(initialTab: 0, initialStatusFilter: 'ATIVO'));
                        } else if (label.contains('Demandas')) {
                          _openScreen(const MeusRegistrosScreen(initialTab: 1));
                        } else if (label.contains('Agenda')) {
                          _openScreen(const AgendaScreen());
                        } else {
                          _openScreen(const SyncScreen());
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              if (_syncResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Sincronizado: ${_syncResult['success']} enviados, ${_syncResult['errors']} erros',
                        style: const TextStyle(color: AppTheme.success, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              Text(
                'Cadastros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(
                    icon: Icons.person_add_outlined,
                    label: 'Novo Contato',
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NovoContatoScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.assignment_outlined,
                    label: 'Nova Demanda',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NovaDemandaScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.directions_walk,
                    label: 'Nova Visita',
                    color: const Color(0xFF059669),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NovaVisitaScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.sync,
                    label: 'Sincronizar',
                    color: const Color(0xFFD97706),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SyncScreen()),
                    ),
                  ),
                ],
              ),
              if (AppConstants.previewMode) ...[
                const SizedBox(height: 20),
                ...PreviewData.destaques.map(
                  (item) => _PreviewHighlightCard(item: item),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Consulta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.calendar_today_outlined,
                label: 'Agenda e Compromissos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgendaScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.list_alt_outlined,
                label: 'Contatos, Demandas e Visitas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeusRegistrosScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.people_alt_outlined,
                label: 'Contatos ativos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeusRegistrosScreen(initialTab: 0, initialStatusFilter: 'ATIVO')),
                ),
              ),
              _MenuTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Demandas abertas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeusRegistrosScreen(initialTab: 1, initialStatusFilter: 'ABERTA')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PreviewMenuAction {
  home,
  contato,
  agenda,
  registros,
  sync,
  logout,
}

class _TopShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TopShortcutChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: Color(0xFFD6E4FF)),
      ),
    );
  }
}

class _PreviewJourneyCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PreviewJourneyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E4FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['titulo']?.toString() ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(data['periodo']?.toString() ?? '', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                data['responsavel']?.toString() ?? '',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMetricCard extends StatelessWidget {
  final Map<String, dynamic> metric;
  final VoidCallback onTap;

  const _PreviewMetricCard({required this.metric, required this.onTap});

  Color _accentColor() {
    switch (metric['accent']) {
      case 'amber':
        return AppTheme.warning;
      case 'green':
        return AppTheme.success;
      case 'rose':
        return const Color(0xFFE11D48);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric['value']?.toString() ?? '',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                metric['label']?.toString() ?? '',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewHighlightCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PreviewHighlightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['titulo']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item['tag']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item['tag']?.toString() ?? '', style: const TextStyle(color: AppTheme.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
