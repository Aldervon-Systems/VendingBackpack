import 'package:flutter/material.dart';

import '../../core/repositories/corporate_repository.dart';
import '../../core/styles/AppStyle.dart';

class CorporateScreen extends StatefulWidget {
  const CorporateScreen({super.key});

  @override
  State<CorporateScreen> createState() => _CorporateScreenState();
}

class _CorporateScreenState extends State<CorporateScreen> {
  final CorporateRepository _repository = CorporateRepository();
  Map<String, dynamic>? _snapshot;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCorporate();
  }

  Future<void> _loadCorporate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _snapshot = await _repository.getSnapshot();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.border,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!.toUpperCase(),
          style: AppStyle.label(
            color: AppColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final snapshot = _snapshot ?? {};
    final rows = snapshot.entries.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: rows.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CORPORATE',
                style: AppStyle.label(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dataPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'LIVE ORGANIZATION SNAPSHOT',
                style: AppStyle.label(fontSize: 10),
              ),
            ],
          );
        }
        final row = rows[index - 1];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyle.surfaceCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.key.toUpperCase(),
                style: AppStyle.label(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dataSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                row.value.toString(),
                style: AppStyle.label(color: AppColors.dataPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}

