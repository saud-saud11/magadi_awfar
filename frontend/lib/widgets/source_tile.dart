import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/url_launcher_helper.dart';
import '../theme/app_theme.dart';

/// A store listing is separate from whether its prices responded to this search.
class SourceTile extends StatelessWidget {
  final SourceInfo source;
  final bool compact;
  const SourceTile({super.key, required this.source, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final connected = source.status == 'connected';
    final unavailable = source.status == 'temporarily_unavailable';
    final color = connected
        ? AppTheme.primary
        : unavailable
        ? Colors.orange.shade800
        : AppTheme.textMuted;
    final label = connected
        ? 'استجاب'
        : unavailable
        ? 'متعذر الآن'
        : source.isEnabled
        ? 'يُفحص عند البحث'
        : 'زيارة المتجر';
    final rawUrl = source.searchUrl ?? source.websiteUrl;
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    final canOpen = uri?.scheme == 'https' && uri!.host.isNotEmpty;
    return ListTile(
      dense: compact,
      isThreeLine: !compact,
      leading: Icon(
        source.category == 'pharmacy'
            ? Icons.local_pharmacy_outlined
            : Icons.storefront_outlined,
        color: color,
      ),
      title: Text(
        source.nameAr,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('$label · ${source.statusText}'),
      trailing: canOpen
          ? IconButton(
              tooltip: 'فتح ${source.nameAr}',
              icon: const Icon(Icons.open_in_new, size: 19),
              onPressed: () async {
                final opened = await UrlLauncherHelper.openStoreUrl(rawUrl!);
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر فتح المتجر. حاول مجددًا.'),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }
}
