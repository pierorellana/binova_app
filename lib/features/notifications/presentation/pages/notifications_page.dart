import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../domain/notification_link.dart';
import '../../domain/entities/notification.dart';
import '../providers/notifications_controller.dart';

enum _Filter { all, financial, security, informational }


class _Category {
  const _Category(this.label, this.background, this.foreground, this.icon);

  final String label;
  final Color background;
  final Color foreground;
  final String icon;

  static final financial = _Category(
    'Finanzas',
    BnColors.positivoFondo,
    BnColors.positivo,
    bnLine('<path d="M7 7h12l-3-3"/><path d="M17 17H5l3 3"/>', stroke: 1.7),
  );
  static final security = _Category(
    'Seguridad',
    BnColors.precaucionFondo,
    BnColors.precaucion,
    bnLine('<path d="M12 3l7 3v5.5c0 4.5-3 7.8-7 9.5-4-1.7-7-5-7-9.5V6z"/><path d="M12 9v4M12 16h.01"/>', stroke: 1.7),
  );
  static final informational = _Category(
    'Información',
    BnColors.relleno,
    const Color(0xFF3A3936),
    bnLine('<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>', stroke: 1.7),
  );

  static _Category of(NotificationType type) => switch (type) {
        NotificationType.financial => financial,
        NotificationType.security => security,
        NotificationType.informational => informational,
      };
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _Filter _filter = _Filter.all;


  final Set<String> _confirmed = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsController>().load();
    });
  }

  bool _matches(AppNotification n) => switch (_filter) {
        _Filter.all => true,
        _Filter.financial => n.type == NotificationType.financial,
        _Filter.security => n.type == NotificationType.security,
        _Filter.informational => n.type == NotificationType.informational,
      };

  Future<void> _markAll(NotificationsController controller) async {
    BnHaptics.tap();
    try {
      await controller.markAllRead();
    } on Object {
      return;
    }
  }

  bool _onScroll(ScrollNotification n, NotificationsController controller) {
    if (n.metrics.extentAfter < 240 && controller.nextCursor != null && controller.status != NotificationsStatus.loading) {
      controller.loadMore().catchError((Object _) {});
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();
    final loading = controller.status == NotificationsStatus.idle || controller.status == NotificationsStatus.loading;
    final groups = _group(controller.items.where(_matches));

    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _onScroll(n, controller),
      child: BnTabScaffold(
        tab: BnTab.home,
        onRefresh: controller.load,
        slivers: [
          SliverToBoxAdapter(
            child: BnNavBar(
              backLabel: 'Inicio',
              trailing: BnNavTextButton(
                label: 'Marcar leídas',
                onTap: controller.isMarkingAllRead ? null : () => _markAll(controller),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: const Text('Notificaciones', style: BnType.largeTitle)),
                  const SizedBox(height: 16),
                  BnSegmented<_Filter>(
                    value: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                    items: const [
                      (_Filter.all, 'Todas'),
                      (_Filter.financial, 'Finanzas'),
                      (_Filter.security, 'Seguridad'),
                      (_Filter.informational, 'Información'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (controller.status == NotificationsStatus.offlineStale)
            SliverToBoxAdapter(
              child: _NoticeBanner(
                title: 'Sin conexión.',
                body: 'Mostrando la última información disponible.',
                footnote: controller.fetchedAt == null
                    ? null
                    : 'Última actualización: ${BnFormat.time(controller.fetchedAt!.toLocal())}.',
                onRetry: controller.load,
              ),
            ),
          if (controller.items.isEmpty && loading)
            const SliverToBoxAdapter(child: _SkeletonGroup())
          else if (controller.items.isEmpty && controller.status == NotificationsStatus.error)
            SliverToBoxAdapter(
              child: _NoticeBanner(
                title: controller.errorMessage ?? 'No pudimos cargar tus notificaciones.',
                body: 'Revisa tu conexión e inténtalo de nuevo.',
                onRetry: controller.load,
              ),
            )
          else if (groups.isEmpty)
            const SliverToBoxAdapter(child: _EmptyState())
          else
            SliverList.list(
              children: [
                for (var i = 0; i < groups.length; i++)
                  BnRise(
                    key: ValueKey(groups[i].title),
                    delay: BnMotion.staggerEntreFilas * i,
                    duration: const Duration(milliseconds: 300),
                    offset: 6,
                    child: _GroupSection(
                      group: groups[i],
                      confirmed: _confirmed,
                      onConfirm: (n) => _confirm(controller, n),
                      onDeny: (n) => _deny(controller, n),
                      onOpen: (n) => _open(controller, n),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _markRead(NotificationsController controller, AppNotification n) async {
    if (n.read) return;
    try {
      await controller.markRead(n.id);
    } on Object {
      return;
    }
  }

  void _confirm(NotificationsController controller, AppNotification n) {
    BnHaptics.success();
    setState(() => _confirmed.add(n.id));
    _markRead(controller, n);
  }

  void _deny(NotificationsController controller, AppNotification n) {
    _markRead(controller, n);
    Navigator.of(context).pushNamed(AppRoute.profile);
  }

  void _open(NotificationsController controller, AppNotification n) {
    final link = NotificationLink.fromNotification(n);
    if (link == null) return;
    _markRead(controller, n);
    Navigator.of(context).pushNamed(link.route, arguments: link.argument);
  }
}





class _Group {
  _Group(this.title);

  final String title;
  final List<AppNotification> items = <AppNotification>[];
}

const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

int _daysAgo(DateTime d) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
}

List<_Group> _group(Iterable<AppNotification> items) {
  final groups = <_Group>[];
  for (final n in items) {
    final days = _daysAgo(n.createdAt.toLocal());
    final title = switch (days) {
      <= 0 => 'Hoy',
      1 => 'Ayer',
      < 7 => 'Esta semana',
      _ => 'Anteriores',
    };
    final group = groups.where((g) => g.title == title).firstOrNull ?? (groups..add(_Group(title))).last;
    group.items.add(n);
  }


  bool leads(AppNotification n) => n.type == NotificationType.security && !n.read;
  for (final g in groups) {
    final ordered = [...g.items.where(leads), ...g.items.where((n) => !leads(n))];
    g.items
      ..clear()
      ..addAll(ordered);
  }
  return groups;
}

String _timeLabel(DateTime created) {
  final d = created.toLocal();
  final days = _daysAgo(d);
  if (days <= 1) return BnFormat.time(d);
  if (days < 7) return _weekdays[d.weekday - 1];
  return '${d.day} ${BnFormat.monthsShort[d.month - 1]}';
}


bool _asksConfirmation(AppNotification n) =>
    n.type == NotificationType.security && (n.resourceType == 'session' || n.body.contains('¿Fuiste tú?'));


class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.confirmed,
    required this.onConfirm,
    required this.onDeny,
    required this.onOpen,
  });

  final _Group group;
  final Set<String> confirmed;
  final ValueChanged<AppNotification> onConfirm;
  final ValueChanged<AppNotification> onDeny;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                header: true,
                child: Text(
                  group.title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: BnType.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.52,
                    color: BnColors.texto2,
                  ),
                ),
              ),
            ),
            BnCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Column(
                  children: [
                    for (var i = 0; i < group.items.length; i++) ...[
                      if (i > 0) const ColoredBox(color: BnColors.relleno, child: SizedBox(height: 1, width: double.infinity)),
                      _NotificationRow(
                        notification: group.items[i],
                        confirmed: confirmed.contains(group.items[i].id),
                        onConfirm: () => onConfirm(group.items[i]),
                        onDeny: () => onDeny(group.items[i]),
                        onOpen: () => onOpen(group.items[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.confirmed,
    required this.onConfirm,
    required this.onDeny,
    required this.onOpen,
  });

  final AppNotification notification;
  final bool confirmed;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;
  final VoidCallback onOpen;

  static const _fade = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final cat = _Category.of(n.type);
    final unread = !n.read;
    final asks = _asksConfirmation(n);
    final link = NotificationLink.fromNotification(n);

    Widget? footer;
    if (asks && confirmed) {
      footer = const _Resolved(key: ValueKey('resolved'));
    } else if (asks && unread) {
      footer = _SecurityActions(key: const ValueKey('actions'), onConfirm: onConfirm, onDeny: onDeny);
    } else if (link != null) {
      footer = Padding(
        key: const ValueKey('link'),
        padding: const EdgeInsets.only(top: 8),
        child: _LinkButton(label: link.label, onTap: onOpen),
      );
    }

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: cat.background, shape: BoxShape.circle),
              child: BnSvg(cat.icon, size: 19, color: cat.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: cat.foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${_timeLabel(n.createdAt)}',
                        style: const TextStyle(fontFamily: BnType.family, fontSize: 12, color: BnColors.texto3),
                      ),
                      const Spacer(),
                      AnimatedScale(
                        scale: unread ? 1 : 0.4,
                        duration: _fade,
                        curve: BnMotion.entrada,
                        child: AnimatedOpacity(
                          opacity: unread ? 1 : 0,
                          duration: _fade,
                          child: Semantics(
                            label: unread ? 'Sin leer' : null,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: BnColors.brandNaranjaBi, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: _fade,
                    style: TextStyle(
                      fontFamily: BnType.family,
                      fontSize: 16,
                      height: 1.35,
                      color: BnColors.carbon,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(n.title),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.body,
                    style: const TextStyle(fontFamily: BnType.family, fontSize: 14, height: 1.4, color: BnColors.texto2),
                  ),
                  AnimatedSize(
                    duration: _fade,
                    curve: BnMotion.entrada,
                    alignment: Alignment.topLeft,
                    child: AnimatedSwitcher(
                      duration: _fade,
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
                      child: footer ?? const SizedBox.shrink(key: ValueKey('none')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityActions extends StatelessWidget {
  const _SecurityActions({required this.onConfirm, required this.onDeny, super.key});

  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  static const _label = TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            BnPressable(
              onTap: onConfirm,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BnColors.blancoCalido,
                  border: Border.all(color: BnColors.hairline),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Sí, fui yo', style: _label.copyWith(color: BnColors.carbon)),
              ),
            ),
            const SizedBox(width: 8),
            BnPressable(
              onTap: onDeny,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(10)),
                child: Text('No reconozco', style: _label.copyWith(color: BnColors.superficie)),
              ),
            ),
          ],
        ),
      );
}

class _Resolved extends StatelessWidget {
  const _Resolved({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BnSvg(BnGlyphs.check, size: 14, color: BnColors.positivo),
            const SizedBox(width: 6),
            const Text(
              'Confirmaste este acceso',
              style: TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: BnColors.positivo),
            ),
          ],
        ),
      );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static final _chevron = bnLine('<path d="M9 6l6 6-6 6"/>', stroke: 2.2);

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.carbon),
              ),
              const SizedBox(width: 2),
              BnSvg(_chevron, size: 15, color: BnColors.carbon),
            ],
          ),
        ),
      );
}


class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.title, required this.body, required this.onRetry, this.footnote});

  final String title;
  final String body;
  final String? footnote;
  final VoidCallback onRetry;

  static final _offline = bnLine(
    '<path d="M3 3l18 18"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 12.5a10 10 0 0 1 4.2-2.4M19 12.5a10 10 0 0 0-3-2"/>'
    '<path d="M2 8.8A15 15 0 0 1 6.1 6.3M22 8.8A15 15 0 0 0 11 5"/><path d="M12 20h.01"/>',
    stroke: 1.8,
  );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: BnColors.superficie,
              border: Border.all(color: BnColors.hairline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: BnColors.relleno, shape: BoxShape.circle),
                  child: BnSvg(_offline, size: 17, color: BnColors.carbon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                      const SizedBox(height: 2),
                      Text(body, style: const TextStyle(fontFamily: BnType.family, fontSize: 14, height: 1.4, color: BnColors.texto2)),
                      if (footnote != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          footnote!,
                          style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3, fontFeatures: BnType.tabular),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  child: BnPressable(
                    onTap: onRetry,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.superficie),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SkeletonGroup extends StatelessWidget {
  const _SkeletonGroup();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BnSkeleton(width: 48, height: 13),
            const SizedBox(height: 10),
            BnCard(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const BnDivider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BnSkeleton(height: 40, circle: true, width: 40),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BnSkeleton(width: 96, height: 12),
                                SizedBox(height: 10),
                                BnSkeleton(height: 14),
                                SizedBox(height: 8),
                                BnSkeleton(width: 180, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(40, 64, 40, 0),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: BnColors.relleno, shape: BoxShape.circle),
              child: BnSvg(BnGlyphs.bell, size: 24, color: BnColors.texto2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes notificaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: BnType.family, fontSize: 17, fontWeight: FontWeight.w600, color: BnColors.carbon),
            ),
            const SizedBox(height: 4),
            const Text(
              'Te avisaremos aquí cuando haya movimientos o alertas de seguridad.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: BnType.family, fontSize: 14, height: 1.4, color: BnColors.texto2),
            ),
          ],
        ),
      );
}
