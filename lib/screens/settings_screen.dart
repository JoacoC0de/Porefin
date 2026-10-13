import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/finance_provider.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            const Text(
              'Ajustes',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Exporta, limpia datos y revisa información de la app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            _ActionCard(
              icon: Icons.upload_file,
              title: 'Exportar a Excel',
              subtitle: 'Genera un archivo XLSX con todos tus datos',
              color: AppTheme.info,
              onTap: () async {
                final service = ExcelService();
                final file = await service.exportDataToExcel();
                if (file != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Archivo generado. Abriendo menú de compartir...')),
                    );
                    await Share.shareXFiles([XFile(file.path)], text: 'Respaldo Finanzas Rápidas');
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.download_for_offline,
              title: 'Importar de Excel',
              subtitle: 'Restaura datos desde un archivo XLSX',
              color: Colors.green,
              onTap: () async {
                final service = ExcelService();
                final success = await service.importDataFromExcel();
                if (success) {
                  await provider.refresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos importados correctamente')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo importar el archivo')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.delete_forever_outlined,
              title: 'Limpiar todos los datos',
              subtitle: 'Borra transacciones, metas y cuentas, manteniendo categorías',
              color: AppTheme.expense,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Limpiar datos'),
                      content: const Text('Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  await provider.clearAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos eliminados')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: SwitchListTile(
                title: const Text('Recordatorios diarios', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                subtitle: const Text('Recibe notificaciones sobre gastos y deudas', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                value: provider.remindersEnabled,
                activeColor: AppTheme.primary,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, color: AppTheme.primary, size: 20),
                ),
                onChanged: (value) async {
                  if (value) {
                    final granted = await Permission.notification.request().isGranted;
                    if (granted) {
                      provider.toggleReminders(true);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Permiso de notificaciones denegado')),
                        );
                      }
                    }
                  } else {
                    provider.toggleReminders(false);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acerca de', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                    'Finanzas Rápidas es una app offline para registrar gastos e ingresos con velocidad.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 14),
                  Text('Versión 1.0.0+1', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}