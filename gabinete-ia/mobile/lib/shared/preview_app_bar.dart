import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/contatos/novo_contato_screen.dart';
import '../features/registros/meus_registros_screen.dart';
import '../features/sync/sync_screen.dart';
import 'app_logo_mark.dart';

enum PreviewMenuAction {
  home,
  contato,
  agenda,
  registros,
  sync,
  logout,
}

class PreviewAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool replaceOnNavigate;
  final bool showWordmark;

  const PreviewAppBar({
    super.key,
    required this.title,
    this.bottom,
    this.actions,
    this.replaceOnNavigate = false,
    this.showWordmark = true,
  });

  static const double _shortcutHeight = 48;

  @override
  Size get preferredSize {
    const bottomHeight = AppConstants.previewMode ? _shortcutHeight : 0;
    final extraBottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight + extraBottomHeight);
  }

  Future<void> _openDestination(BuildContext context, PreviewMenuAction action) async {
    if (action == PreviewMenuAction.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final Widget? destination = switch (action) {
      PreviewMenuAction.contato => const NovoContatoScreen(),
      PreviewMenuAction.agenda => const AgendaScreen(),
      PreviewMenuAction.registros => const MeusRegistrosScreen(),
      PreviewMenuAction.sync => const SyncScreen(),
      _ => null,
    };

    if (destination == null) {
      return;
    }

    final route = MaterialPageRoute<void>(builder: (_) => destination);
    if (replaceOnNavigate) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }

    await Navigator.of(context).push(route);
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, PreviewMenuAction action) async {
    if (action == PreviewMenuAction.logout) {
      await ref.read(authProvider.notifier).logout();
      return;
    }

    await _openDestination(context, action);
  }

  Widget _buildShortcuts(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TopShortcutChip(
              label: 'Contato',
              onTap: () => _handleAction(context, ref, PreviewMenuAction.contato),
            ),
            _TopShortcutChip(
              label: 'Agenda',
              onTap: () => _handleAction(context, ref, PreviewMenuAction.agenda),
            ),
            _TopShortcutChip(
              label: 'Registros',
              onTap: () => _handleAction(context, ref, PreviewMenuAction.registros),
            ),
            _TopShortcutChip(
              label: 'Sync',
              onTap: () => _handleAction(context, ref, PreviewMenuAction.sync),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBottom = <Widget>[
      if (AppConstants.previewMode)
        PreferredSize(
          preferredSize: const Size.fromHeight(_shortcutHeight),
          child: _buildShortcuts(context, ref),
        ),
      if (bottom != null) bottom!,
    ];

    return AppBar(
      centerTitle: !showWordmark,
      leadingWidth: showWordmark ? 132 : 60,
      leading: Padding(
        padding: EdgeInsets.only(left: 10, top: showWordmark ? 10 : 8, bottom: showWordmark ? 10 : 8),
        child: PopupMenuButton<PreviewMenuAction>(
          tooltip: 'Menu',
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: PreviewMenuAction.home,
              child: Text('Início'),
            ),
            PopupMenuItem(
              value: PreviewMenuAction.contato,
              child: Text('Novo Contato'),
            ),
            PopupMenuItem(
              value: PreviewMenuAction.agenda,
              child: Text('Agenda'),
            ),
            PopupMenuItem(
              value: PreviewMenuAction.registros,
              child: Text('Meus Registros'),
            ),
            PopupMenuItem(
              value: PreviewMenuAction.sync,
              child: Text('Sincronização'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: PreviewMenuAction.logout,
              child: Text('Sair'),
            ),
          ],
          child: Center(
            child: AppLogoMark(
              size: showWordmark ? 34 : 28,
              showHalo: false,
              variant: showWordmark ? AppLogoVariant.wordmark : AppLogoVariant.symbol,
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: Text(title),
      actions: actions,
      bottom: effectiveBottom.isEmpty
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                (AppConstants.previewMode ? _shortcutHeight : 0) + (bottom?.preferredSize.height ?? 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: effectiveBottom,
              ),
            ),
    );
  }
}

class _TopShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TopShortcutChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}