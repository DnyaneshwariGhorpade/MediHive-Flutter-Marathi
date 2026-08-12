import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/standard_header.dart';
import '../../widgets/section_card.dart';
import '../../l10n/app_localizations.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedFaq;
  List<Map<String, String>> _faqs = [];

  void _initFaqs(AppLocalizations l10n) {
    if (_faqs.isEmpty) {
      _faqs = [
        {'q': l10n.faqBackupTitle, 'a': l10n.faqBackupAnswer},
        {'q': l10n.faqExportTitle, 'a': l10n.faqExportAnswer},
        {'q': l10n.faqShareTitle, 'a': l10n.faqShareAnswer},
        {'q': l10n.faqPasswordTitle, 'a': l10n.faqPasswordAnswer},
      ];
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    _initFaqs(l10n);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            StandardHeader(
              title: l10n.helpAndSupport,
              showBack: true,
              onBack: _handleBack,
            ),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        _infoCard(Icons.code, Color(0x1A1A506C), AppTheme.primary, l10n.developerInformation, [
          _row(l10n.forTechnicalQueries, ''),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow(l10n.emailLabel, 'ashwin.innovatehive@gmail.com', AppTheme.primary),
              SizedBox(height: 8), _detailRow(l10n.phoneLabel, '8767555945', AppTheme.textPrimary),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.info_outline, Color(0x1A2563EB), Color(0xFF2563EB), l10n.applicationInfo, [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow(l10n.appNameLabel, 'MediHive', AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow(l10n.version, 'v1.0.7', AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow(l10n.platform, l10n.platformMobile, AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow(l10n.lastUpdated, l10n.lastUpdatedDate, AppTheme.textPrimary),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.storage, Color(0x1A22C55E), Color(0xFF22C55E), l10n.backupInformation, [
          Text(l10n.backupFilesStored, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          SizedBox(height: 12),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.location, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              SizedBox(height: 4),
              Text(l10n.backupStoragePath, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontFamily: 'monospace')),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.shield_outlined, Color(0x1A9333EA), Color(0xFF9333EA), l10n.dataAndPrivacy, [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceTint, borderRadius: BorderRadius.circular(12)),
            child: Text(l10n.dataPrivacyDescription,
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
        ]),
        SizedBox(height: 16),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.frequentlyAskedQuestions, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
          SizedBox(height: 16),
          ..._faqs.asMap().entries.map((e) => Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              InkWell(
                onTap: () => setState(() => _expandedFaq = _expandedFaq == e.key ? null : e.key),
                borderRadius: BorderRadius.circular(12),
                child: Padding(padding: EdgeInsets.all(16), child: Row(children: [
                  Expanded(child: Text(e.value['q']!, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
                  AnimatedRotation(turns: _expandedFaq == e.key ? 0.5 : 0, duration: Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: AppTheme.textTertiary)),
                ])),
              ),
              if (_expandedFaq == e.key) Container(
                width: double.infinity, padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                child: Text(e.value['a']!, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            ]),
          )),
        ])),
        SizedBox(height: 80),
      ]))),
    ])),
    );
  }

  Widget _infoCard(IconData icon, Color bg, Color fg, String title, List<Widget> children) => SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: fg, size: 24)),
      SizedBox(width: 12),
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
    ]),
    SizedBox(height: 16), ...children,
  ]));

  Widget _row(String label, String value) => Padding(padding: EdgeInsets.only(bottom: 12), child: Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)));
  Widget _detailRow(String label, String value, Color valueColor) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
  ]);
}



