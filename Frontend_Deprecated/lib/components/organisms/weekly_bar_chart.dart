import 'package:flutter/material.dart';

// Helper: convert ISO date string to weekday short name (Mon, Tue...)
String _weekdayLabelFromEntry(Map<String, dynamic> d, int idx) {
  try {
    final ds = d['date']?.toString();
    if (ds == null || ds.isEmpty) return 'Day ${idx + 1}';
    final dt = DateTime.parse(ds);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(dt.weekday - 1) % 7];
  } catch (_) {
    return 'Day ${idx + 1}';
  }
}

// Weekly revenue/profit bar chart.
// Expects data: List<Map>{'date': 'yyyy-mm-dd', 'sales': int, 'restock_alerts': int}
// Renders stacked bars where the bottom section is COST (wholesale) and the top
// section is PROFIT. We assume wholesale=$1.00 and sale price=$2.50 for now.
class WeeklyBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double height;

  const WeeklyBarChart({super.key, required this.data, this.height = 180});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  static const double wholesale = 1.0;
  static const double salePrice = 2.5;

  bool _dialogOpen = false;

  void _openExpanded() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ExpandedWeeklyChart(
          data: widget.data,
          wholesale: wholesale,
          salePrice: salePrice,
        ),
      ),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final height = widget.height;
    if (data.isEmpty) return SizedBox(height: height, child: Center(child: Text('No data')));

    // Compute max revenue for scaling
    double maxRevenue = 1.0;
    for (final d in data) {
      final sales = (d['sales'] ?? 0) as int;
      final revenue = sales * salePrice;
      if (revenue > maxRevenue) maxRevenue = revenue;
    }

    // Compact view: two narrow adjacent bars per day (Revenue | Profit)
    return MouseRegion(
      onEnter: (_) => _openExpanded(),
      child: SizedBox(
        height: height + 28,
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: data.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final d = entry.value;
                  final label = _weekdayLabelFromEntry(d, idx);
                  final sales = (d['sales'] ?? 0) as int;
                  final revenue = sales * salePrice;
                  final profit = revenue - (sales * wholesale);
                  final revenueHeight = maxRevenue > 0 ? (revenue / maxRevenue) * (height - 16) : 0.0;
                  final profitHeight = revenueHeight * (profit / (revenue == 0 ? 1 : revenue));

                  return Flexible(
                    fit: FlexFit.tight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Two thin bars side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Revenue bar
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() {}),
                                child: Container(
                                  height: revenueHeight,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[300],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Profit bar
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() {}),
                                child: Container(
                                  height: profitHeight,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[400],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Assumes wholesale = \$1.00, sale = \$2.50 (profit = sale - wholesale).',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Expanded chart dialog widget with hover tooltips
class ExpandedWeeklyChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double wholesale;
  final double salePrice;

  const ExpandedWeeklyChart({super.key, required this.data, required this.wholesale, required this.salePrice});

  @override
  State<ExpandedWeeklyChart> createState() => _ExpandedWeeklyChartState();
}

class _ExpandedWeeklyChartState extends State<ExpandedWeeklyChart> {
  String? _hoverText;
  void _setHoverText(String text) {
    setState(() {
      _hoverText = text;
    });
  }

  void _clearHover() {
    setState(() {
      _hoverText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final size = MediaQuery.of(context).size;
    final chartH = (size.height * 0.5).clamp(240.0, 640.0);

    // compute max revenue
    double maxRevenue = 1.0;
    for (final d in data) {
      final sales = (d['sales'] ?? 0) as int;
      final revenue = sales * widget.salePrice;
      if (revenue > maxRevenue) maxRevenue = revenue;
    }

    // Precompute centered tooltip position below the chart
    double? _tooltipLeft;
    double? _tooltipTop;
    const tooltipW = 160.0;
    const tooltipH = 36.0;
    final screenW = MediaQuery.of(context).size.width;
    final chartBottom = chartH + 48.0; // small offset from chart
    if (_hoverText != null) {
      _tooltipLeft = ((screenW - tooltipW) / 2).clamp(8.0, screenW - tooltipW - 8.0);
      _tooltipTop = chartBottom.clamp(8.0, MediaQuery.of(context).size.height - tooltipH - 8.0);
    }

    return SizedBox(
      width: double.infinity,
      height: chartH + 80,
      child: Stack(
        children: [
          Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Revenue & Profit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              // Chart area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final d = entry.value;
                      final sales = (d['sales'] ?? 0) as int;
                      final revenue = sales * widget.salePrice;
                      final cost = sales * widget.wholesale;
                      final profit = revenue - cost;
                      final barH = maxRevenue > 0 ? (revenue / maxRevenue) * (chartH - 32) : 0.0;
                      final profitH = barH * (profit / (revenue == 0 ? 1 : revenue));

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                                  // Two adjacent bars for better readability in expanded view
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Revenue bar (blue)
                                      Expanded(
                                        child: MouseRegion(
                                          onEnter: (_) => _setHoverText('Revenue: \$${revenue.toStringAsFixed(2)}'),
                                          onExit: (_) => _clearHover(),
                                          child: Container(
                                            height: barH,
                                            margin: const EdgeInsets.symmetric(horizontal: 6),
                                            decoration: BoxDecoration(color: Colors.blue[300], borderRadius: BorderRadius.circular(6)),
                                          ),
                                        ),
                                      ),
                                      // Profit bar (green)
                                      Expanded(
                                        child: MouseRegion(
                                          onEnter: (_) => _setHoverText('Profit: \$${profit.toStringAsFixed(2)}'),
                                          onExit: (_) => _clearHover(),
                                          child: Container(
                                            height: profitH,
                                            margin: const EdgeInsets.symmetric(horizontal: 6),
                                            decoration: BoxDecoration(color: Colors.green[400], borderRadius: BorderRadius.circular(6)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 8),
                            Text(_weekdayLabelFromEntry(d, idx), style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          // Tooltip overlay
          if (_hoverText != null)
            Positioned(
              left: _tooltipLeft!,
              top: _tooltipTop!,
              child: Material(
                elevation: 6,
                color: Colors.transparent,
                child: Container(
                  width: tooltipW,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
                  child: Text(_hoverText!, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
