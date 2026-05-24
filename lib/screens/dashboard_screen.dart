import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/venta.dart';
import '../providers/inventario_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/ventas_provider.dart';

enum _Rango { hoy, semana, mes }

/// Pantalla 1: Dashboard estilo Power BI con KPIs, gráfico de barras,
/// desglose por método de pago y top productos.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Rango _rango = _Rango.hoy;

  // ── Filtrado ────────────────────────────────────────────────────────────────

  List<Venta> _filtrar(List<Venta> todas) {
    final now = DateTime.now();
    return switch (_rango) {
      _Rango.hoy => todas
          .where((v) =>
              v.fecha.year == now.year &&
              v.fecha.month == now.month &&
              v.fecha.day == now.day)
          .toList(),
      _Rango.semana => todas
          .where((v) => v.fecha.isAfter(
              DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 6))))
          .toList(),
      _Rango.mes => todas
          .where(
              (v) => v.fecha.year == now.year && v.fecha.month == now.month)
          .toList(),
    };
  }

  // ── Datos del gráfico de barras ─────────────────────────────────────────────

  List<_BarDato> _barDatos(List<Venta> ventas) {
    final now = DateTime.now();

    if (_rango == _Rango.hoy) {
      // Agrupar por hora — mostrar las últimas 8 horas activas
      final byHour = <int, double>{};
      for (var h = math.max(0, now.hour - 7); h <= now.hour; h++) {
        byHour[h] = 0;
      }
      for (final v in ventas) {
        if (byHour.containsKey(v.fecha.hour)) {
          byHour[v.fecha.hour] = (byHour[v.fecha.hour] ?? 0) + v.total;
        }
      }
      return byHour.entries
          .map((e) => _BarDato(
                label: '${e.key}h',
                valor: e.value,
                esActivo: e.key == now.hour,
              ))
          .toList();
    }

    if (_rango == _Rango.semana) {
      // Últimos 7 días
      final labels = <String>['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
      final result = <_BarDato>[];
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day - i);
        final total = ventas
            .where((v) =>
                v.fecha.year == d.year &&
                v.fecha.month == d.month &&
                v.fecha.day == d.day)
            .fold(0.0, (s, v) => s + v.total);
        result.add(_BarDato(
          label: i == 0 ? 'Hoy' : labels[d.weekday],
          valor: total,
          esActivo: i == 0,
        ));
      }
      return result;
    }

    // Mes actual — agrupar en semanas S1…S5
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final semanas = <String, double>{};
    for (var d = 1; d <= daysInMonth; d++) {
      final key = 'S${((d - 1) ~/ 7) + 1}';
      semanas[key] = 0;
    }
    for (final v in ventas) {
      final key = 'S${((v.fecha.day - 1) ~/ 7) + 1}';
      semanas[key] = (semanas[key] ?? 0) + v.total;
    }
    final semActual = 'S${((now.day - 1) ~/ 7) + 1}';
    return semanas.entries
        .map((e) => _BarDato(
              label: e.key,
              valor: e.value,
              esActivo: e.key == semActual,
            ))
        .toList();
  }

  // ── Top productos ───────────────────────────────────────────────────────────

  List<MapEntry<String, int>> _topProductos(List<Venta> ventas) {
    final counts = <String, int>{};
    for (final v in ventas) {
      for (final l in v.lineas) {
        counts[l.nombre] = (counts[l.nombre] ?? 0) + l.cantidad;
      }
    }
    return (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();
  }

  // ── Por método de pago ──────────────────────────────────────────────────────

  Map<String, double> _porMetodo(List<Venta> ventas) {
    final m = <String, double>{};
    for (final v in ventas) {
      m[v.metodoPago] = (m[v.metodoPago] ?? 0) + v.total;
    }
    return Map.fromEntries(
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventarioProvider>();
    context.watch<ClientesProvider>();
    final vp = context.watch<VentasProvider>();
    final ventas = _filtrar(vp.historial);

    final revenue = ventas.fold(0.0, (s, v) => s + v.total);
    final nTickets = ventas.length;
    final avgTicket = nTickets > 0 ? revenue / nTickets : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // ── Selector de rango ──────────────────────────────────────────────
        _SelectorRango(
          actual: _rango,
          onCambio: (r) => setState(() => _rango = r),
        ),
        const SizedBox(height: 18),

        // ── KPI cards ─────────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _KpiCard(
              icon: Icons.euro_rounded,
              label: 'Revenue',
              valor: formatEuro(revenue),
              sub: '$nTickets tickets',
              color: AppColors.accentBright,
            ),
            _KpiCard(
              icon: Icons.show_chart_rounded,
              label: 'Ticket medio',
              valor: formatEuro(avgTicket),
              sub: nTickets == 0 ? 'sin datos' : 'por venta',
              color: AppColors.green,
            ),
            _KpiCard(
              icon: Icons.inventory_2_outlined,
              label: 'Inventario',
              valor: formatEuro(inv.valorInventario),
              sub: '${inv.productos.length} productos',
              color: AppColors.amber,
            ),
            _KpiCard(
              icon: inv.productosBajoStock.isEmpty
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              label: 'Stock bajo',
              valor: '${inv.productosBajoStock.length}',
              sub: 'por reponer',
              color: inv.productosBajoStock.isEmpty
                  ? AppColors.green
                  : AppColors.red,
              alerta: inv.productosBajoStock.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Alertas de stock bajo ──────────────────────────────────────────
        if (inv.productosBajoStock.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.amber),
                    const SizedBox(width: 7),
                    Text(
                      '${inv.productosBajoStock.length} producto${inv.productosBajoStock.length == 1 ? '' : 's'} por reponer',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                          letterSpacing: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...inv.productosBajoStock.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Text(p.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (p.stock == 0
                                      ? AppColors.red
                                      : AppColors.amber)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.stock == 0
                                  ? 'Agotado'
                                  : '${p.stock}/${p.stockMinimo} ud.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.stock == 0
                                    ? AppColors.red
                                    : AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Gráfico de barras ──────────────────────────────────────────────
        _Panel(
          titulo: 'Revenue',
          badge: _rangoHint,
          child: ventas.isEmpty
              ? const _SinDatos()
              : _BarChart(datos: _barDatos(ventas), total: revenue),
        ),
        const SizedBox(height: 14),

        // ── Métodos de pago ────────────────────────────────────────────────
        _Panel(
          titulo: 'Método de pago',
          child: ventas.isEmpty
              ? const _SinDatos()
              : _MetodosPago(
                  porMetodo: _porMetodo(ventas), total: revenue),
        ),
        const SizedBox(height: 14),

        // ── Top productos ──────────────────────────────────────────────────
        _Panel(
          titulo: 'Top productos',
          badge: 'más vendidos',
          child: ventas.isEmpty
              ? const _SinDatos()
              : _TopProductos(items: _topProductos(ventas)),
        ),
        const SizedBox(height: 14),

        // ── Últimas transacciones ──────────────────────────────────────────
        _Panel(
          titulo: 'Últimas ventas',
          badge: 'recientes',
          child: vp.historial.isEmpty
              ? const _SinDatos()
              : Column(
                  children: vp.historial
                      .take(6)
                      .map((v) => _FilaVenta(v: v))
                      .toList(),
                ),
        ),
      ],
    );
  }

  String get _rangoHint => switch (_rango) {
        _Rango.hoy => 'por hora',
        _Rango.semana => 'últimos 7 días',
        _Rango.mes => 'por semana',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// SELECTOR DE RANGO
// ═══════════════════════════════════════════════════════════════════════════

class _SelectorRango extends StatelessWidget {
  final _Rango actual;
  final ValueChanged<_Rango> onCambio;

  const _SelectorRango({required this.actual, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: _Rango.values.map((r) {
          final sel = r == actual;
          final labels = {
            _Rango.hoy: 'Hoy',
            _Rango.semana: 'Semana',
            _Rango.mes: 'Mes',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onCambio(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[r]!,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textDim,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KPI CARD
// ═══════════════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final String sub;
  final Color color;
  final bool alerta;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.valor,
    required this.sub,
    required this.color,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: alerta ? AppColors.red.withValues(alpha: 0.4) : AppColors.line),
      ),
      child: Stack(
        children: [
          // Fondo degradado sutil
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL GENÉRICO
// ═══════════════════════════════════════════════════════════════════════════

class _Panel extends StatelessWidget {
  final String titulo;
  final String? badge;
  final Widget child;

  const _Panel({required this.titulo, this.badge, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accentBright,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRÁFICO DE BARRAS
// ═══════════════════════════════════════════════════════════════════════════

class _BarDato {
  final String label;
  final double valor;
  final bool esActivo;
  const _BarDato(
      {required this.label, required this.valor, required this.esActivo});
}

class _BarChart extends StatelessWidget {
  final List<_BarDato> datos;
  final double total;
  const _BarChart({required this.datos, required this.total});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        datos.map((d) => d.valor).fold(0.0, (a, b) => math.max(a, b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total grande
        Text(
          formatEuro(total),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        // Barras
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: datos.map((d) {
              final pct = maxVal > 0 ? d.valor / maxVal : 0.0;
              final barH = (pct * 80).clamp(3.0, 80.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // valor encima de la barra activa
                      SizedBox(
                        height: 14,
                        child: d.esActivo && d.valor > 0
                            ? Text(
                                formatEuro(d.valor),
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: AppColors.accentBright,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutQuart,
                        height: barH,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: d.esActivo
                                ? [
                                    AppColors.accentBright,
                                    const Color(0xFF8ED6FF)
                                  ]
                                : [
                                    AppColors.accent.withValues(alpha: 0.5),
                                    AppColors.accent.withValues(alpha: 0.85)
                                  ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: d.esActivo
                              ? AppColors.accentBright
                              : AppColors.textFaint,
                          fontWeight: d.esActivo
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MÉTODOS DE PAGO
// ═══════════════════════════════════════════════════════════════════════════

class _MetodosPago extends StatelessWidget {
  final Map<String, double> porMetodo;
  final double total;

  const _MetodosPago({required this.porMetodo, required this.total});

  static const _iconos = {
    'Efectivo': Icons.payments_outlined,
    'Tarjeta': Icons.credit_card_outlined,
    'Bizum': Icons.smartphone_outlined,
  };

  static const _colores = {
    'Efectivo': AppColors.green,
    'Tarjeta': AppColors.accentBright,
    'Bizum': AppColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: porMetodo.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        final color =
            _colores[e.key] ?? AppColors.textDim;
        final icon = _iconos[e.key] ?? Icons.payments_outlined;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(formatEuro(e.value),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.panel2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP PRODUCTOS
// ═══════════════════════════════════════════════════════════════════════════

class _TopProductos extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  const _TopProductos({required this.items});

  static const _medallas = ['🥇', '🥈', '🥉', '4°', '5°'];

  @override
  Widget build(BuildContext context) {
    final maxQty = items.isEmpty ? 1 : items.first.value;
    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final pct = maxQty > 0 ? item.value / maxQty : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(_medallas[i],
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.key,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.value} uds.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: AppColors.panel2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          [
                            AppColors.amber,
                            AppColors.textDim,
                            AppColors.textFaint,
                            AppColors.line,
                            AppColors.line,
                          ][i],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILA DE VENTA RECIENTE
// ═══════════════════════════════════════════════════════════════════════════

class _FilaVenta extends StatelessWidget {
  final Venta v;
  const _FilaVenta({required this.v});

  static const _metodosIcono = {
    'Efectivo': Icons.payments_outlined,
    'Tarjeta': Icons.credit_card_outlined,
    'Bizum': Icons.smartphone_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.panel2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(
              _metodosIcono[v.metodoPago] ?? Icons.receipt_outlined,
              size: 17,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.clienteNombre == 'Sin cliente'
                      ? 'Venta ${v.id.substring(0, 6).toUpperCase()}'
                      : v.clienteNombre,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM · HH:mm', 'es').format(v.fecha),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          Text(
            formatEuro(v.total),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.accentBright,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIN DATOS
// ═══════════════════════════════════════════════════════════════════════════

class _SinDatos extends StatelessWidget {
  const _SinDatos();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text('Sin datos en este periodo',
            style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
      ),
    );
  }
}
