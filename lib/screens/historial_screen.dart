import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/venta.dart';
import '../providers/ventas_provider.dart';

enum _Filtro { todas, hoy, semana, mes }

/// Pantalla 5: Historial completo de ventas con filtros y detalle.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  _Filtro _filtro = _Filtro.todas;
  String _query = '';

  List<Venta> _filtrar(List<Venta> ventas) {
    final now = DateTime.now();

    var lista = switch (_filtro) {
      _Filtro.todas => ventas,
      _Filtro.hoy => ventas
          .where((v) =>
              v.fecha.year == now.year &&
              v.fecha.month == now.month &&
              v.fecha.day == now.day)
          .toList(),
      _Filtro.semana => ventas
          .where((v) => v.fecha.isAfter(
              DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 6))))
          .toList(),
      _Filtro.mes => ventas
          .where(
              (v) => v.fecha.year == now.year && v.fecha.month == now.month)
          .toList(),
    };

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      lista = lista
          .where((v) =>
              v.clienteNombre.toLowerCase().contains(q) ||
              v.metodoPago.toLowerCase().contains(q) ||
              v.id.toLowerCase().contains(q) ||
              v.lineas.any((l) => l.nombre.toLowerCase().contains(q)))
          .toList();
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VentasProvider>();
    final lista = _filtrar(vp.historial);
    final revenue = lista.fold(0.0, (s, v) => s + v.total);

    return Column(
      children: [
        // ── Stats header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: AppColors.bgSoft,
          child: Row(
            children: [
              _StatChip(
                icon: Icons.receipt_long_outlined,
                label: '${lista.length} ventas',
                color: AppColors.textDim,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.euro_rounded,
                label: formatEuro(revenue),
                color: AppColors.accentBright,
                destacado: true,
              ),
            ],
          ),
        ),

        // ── Filtros ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          color: AppColors.bgSoft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Filtro.values.map((f) {
                const labels = {
                  _Filtro.todas: 'Todas',
                  _Filtro.hoy: 'Hoy',
                  _Filtro.semana: 'Semana',
                  _Filtro.mes: 'Este mes',
                };
                final sel = f == _filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtro = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent
                            : AppColors.panel,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: sel
                                ? AppColors.accent
                                : AppColors.line),
                      ),
                      child: Text(
                        labels[f]!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: sel
                              ? Colors.white
                              : AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Busqueda ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Buscar por cliente, método, producto...',
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textFaint),
            ),
          ),
        ),

        // ── Lista ─────────────────────────────────────────────────────────
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppColors.line),
                      const SizedBox(height: 12),
                      Text(
                        _query.isNotEmpty
                            ? 'Sin resultados para "$_query"'
                            : 'Sin ventas en este periodo',
                        style: const TextStyle(
                            color: AppColors.textFaint),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) =>
                      _VentaTile(venta: lista[i]),
                ),
        ),
      ],
    );
  }
}

// ── Chip de estadística ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool destacado;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: destacado
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: destacado
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Tile de una venta ─────────────────────────────────────────────────────

class _VentaTile extends StatelessWidget {
  final Venta venta;
  const _VentaTile({required this.venta});

  static const _metodosIcono = {
    'Efectivo': Icons.payments_outlined,
    'Tarjeta': Icons.credit_card_outlined,
    'Bizum': Icons.smartphone_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _verDetalle(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icono método
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.panel2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(
                  _metodosIcono[venta.metodoPago] ??
                      Icons.receipt_outlined,
                  size: 19,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venta.clienteNombre == 'Sin cliente'
                          ? 'Ticket #${venta.id.substring(0, 6).toUpperCase()}'
                          : venta.clienteNombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd MMM · HH:mm', 'es')
                              .format(venta.fecha),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textFaint),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.line,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${venta.totalArticulos} art.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textFaint),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.panel2,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            venta.metodoPago,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textDim,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatEuro(venta.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.accentBright,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.line),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetalleVenta(venta: venta),
    );
  }
}

// ── Detalle de una venta ──────────────────────────────────────────────────

class _DetalleVenta extends StatelessWidget {
  final Venta venta;
  const _DetalleVenta({required this.venta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket #${venta.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm', 'es')
                        .format(venta.fecha),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textFaint),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  venta.metodoPago,
                  style: const TextStyle(
                      color: AppColors.accentBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),

          if (venta.clienteNombre != 'Sin cliente') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.textFaint),
                const SizedBox(width: 6),
                Text(venta.clienteNombre,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDim)),
              ],
            ),
          ],

          const SizedBox(height: 18),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 14),

          // Líneas
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: venta.lineas.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.panel2,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text('${l.cantidad}×',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDim)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(l.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(
                                    '${formatEuro(l.precio)} / ud.',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textFaint)),
                              ],
                            ),
                          ),
                          Text(formatEuro(l.subtotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),

          // Totales
          _FilaResumen('Base imponible',
              formatEuro(venta.total / 1.21), false),
          _FilaResumen('IVA (21%)',
              formatEuro(venta.total - venta.total / 1.21), false),
          const SizedBox(height: 6),
          _FilaResumen('TOTAL', formatEuro(venta.total), true),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrita;
  const _FilaResumen(this.label, this.valor, this.negrita);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: negrita ? 15 : 13,
                  color:
                      negrita ? AppColors.text : AppColors.textDim,
                  fontWeight: negrita
                      ? FontWeight.w800
                      : FontWeight.normal)),
          Text(valor,
              style: TextStyle(
                  fontSize: negrita ? 15 : 13,
                  color:
                      negrita ? AppColors.text : AppColors.textDim,
                  fontWeight: negrita
                      ? FontWeight.w800
                      : FontWeight.normal)),
        ],
      ),
    );
  }
}
