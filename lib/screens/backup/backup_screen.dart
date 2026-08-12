import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
 
import '../../theme/app_theme.dart';
import '../../widgets/standard_header.dart';
import '../../widgets/section_card.dart';
import '../../providers/settings_provider.dart';
import '../../services/sync_manager.dart';
import '../../services/excel_export_service.dart';
import '../../services/google_drive_sync_service.dart';
import '../../services/excel_restore_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _showDropdown = false;
  String _backupTimeStr = '02:00 AM';
  TimeOfDay _backupTime = const TimeOfDay(hour: 2, minute: 0);

  // Sync Preferences State
  bool _autoSync = true;
  String _syncFrequency = 'Daily';
  bool _wifiOnly = false;
  String _driveUsageStr = '2.3 MB used';
  List<DriveBackupInfo> _cloudBackups = [];
  bool _isLoadingHistory = false;
  bool _isRestoring = false;
  String _restoreProgressStr = '';

  @override
  void initState() {
    super.initState();
    _loadBackupTime();
    _loadSyncSettings();
  }

  Future<void> _loadBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('backup_hour') ?? 2;
    final minute = prefs.getInt('backup_minute') ?? 0;
    setState(() {
      _backupTime = TimeOfDay(hour: hour, minute: minute);
      _backupTimeStr = _formatTimeOfDay(_backupTime);
    });
  }

  Future<void> _loadSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _syncFrequency = prefs.getString('sync_frequency') ?? 'Daily';
      _wifiOnly = prefs.getBool('wifi_only') ?? false;
    });
    _fetchDriveUsage();
    _fetchCloudBackupHistory();
  }

  Future<void> _saveAutoSync(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', val);
    setState(() => _autoSync = val);
  }

  Future<void> _saveSyncFrequency(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_frequency', val);
    setState(() => _syncFrequency = val);
  }

  Future<void> _saveWifiOnly(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_only', val);
    setState(() => _wifiOnly = val);
  }

  Future<void> _fetchDriveUsage() async {
    try {
      final usage = await GoogleDriveSyncService().getDriveUsage();
      setState(() {
        _driveUsageStr = usage;
      });
    } catch (_) {
      setState(() {
        _driveUsageStr = AppLocalizations.of(context)?.unknown ?? 'Unknown';
      });
      if (mounted) {
        _showToast(AppLocalizations.of(context)!.failedToFetchDriveUsage, isError: true);
      }
    }
  }

  Future<void> _fetchCloudBackupHistory() async {
    final signedIn = Provider.of<SettingsProvider>(context, listen: false).googleUser != null;
    if (!signedIn) return;

    setState(() => _isLoadingHistory = true);
    try {
      final history = await GoogleDriveSyncService().listBackups();
      setState(() {
        _cloudBackups = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        _showToast(AppLocalizations.of(context)!.failedToLoadBackupHistory(e.toString()), isError: true);
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $amPm';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return AppLocalizations.of(context)!.unknownDate;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) {
      return AppLocalizations.of(context)!.todayAt(_formatTimeOfDay(TimeOfDay.fromDateTime(dateTime)));
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterdayAt(_formatTimeOfDay(TimeOfDay.fromDateTime(dateTime)));
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  int _parseRecordCount(String filename) {
    final regExp = RegExp(r'_(\d+)_records_');
    final match = regExp.firstMatch(filename);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _selectBackupTime(BuildContext context, SyncManager syncMgr) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _backupTime,
    );
    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('backup_hour', selected.hour);
      await prefs.setInt('backup_minute', selected.minute);
      setState(() {
        _backupTime = selected;
        _backupTimeStr = _formatTimeOfDay(selected);
      });
      await syncMgr.scheduleDailyBackup(selected);
      _showToast('✓ ${AppLocalizations.of(context)!.backupScheduledAt(_backupTimeStr)}');
    }
  }

  Future<void> _shareBackup() async {
    try {
      _showToast(AppLocalizations.of(context)!.preparingBackupToShare);
      final bytes = await ExcelExportService().generateExcelFile();
      final fileName = ExcelExportService().generateFileName('Shree_Clinic');
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: AppLocalizations.of(context)!.shareBackupText,
      );
    } catch (e) {
      _showToast(AppLocalizations.of(context)!.shareFailed(e.toString()), isError: true);
    }
  }

  Future<void> _confirmAndRestore(DriveBackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.restoreBackupTitle),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.restoreWarning,
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.danger,
                                                  foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.restoreDataBtn),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _performRestore(backup);
    }
  }

  Future<void> _performRestore(DriveBackupInfo backup) async {
    setState(() {
      _isRestoring = true;
      _restoreProgressStr = AppLocalizations.of(context)!.downloadingBackup;
    });

    try {
      final bytes = await GoogleDriveSyncService().downloadBackupBytes(backup.id);
      
      final recordCount = _parseRecordCount(backup.name);
      setState(() {
        _restoreProgressStr = AppLocalizations.of(context)!.restoringNRecords(recordCount);
      });

      final restored = await ExcelRestoreService().restoreFromExcel(bytes);
      
      setState(() {
        _isRestoring = false;
        _restoreProgressStr = '';
      });

      _showToast('✓ ${AppLocalizations.of(context)!.restoredNRecords(restored)}');
      _fetchCloudBackupHistory();
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _restoreProgressStr = '';
      });
      _showToast(AppLocalizations.of(context)!.restoreFailed(e.toString()), isError: true);
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
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                StandardHeader(
                  title: l10n.backupAndCloudSyncTitle,
                  showBack: true,
                  onBack: _handleBack,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Google Drive Usage Badge
                        Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                          if (settings.googleUser == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_circle_outlined, color: AppTheme.primary, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.googleDriveUsed(_driveUsageStr),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Export to Device Card (Local Backup)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.storage, color: AppTheme.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.localBackup,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      l10n.exportAndShareLocally,
                                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.surfaceTint, AppTheme.surfaceVariant]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.generateExcelDescription,
                                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => setState(() => _showDropdown = !_showDropdown),
                                    icon: const Icon(Icons.download, size: 20),
                                    label: Text(l10n.exportToDevice),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: AppTheme.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _shareBackup,
                                    icon: const Icon(Icons.share, size: 20),
                                    label: Text(l10n.shareBackupBtn),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_showDropdown)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: AppTheme.heavyShadow,
                                ),
                                child: Column(
                                  children: [l10n.month1Period, l10n.months3Period, l10n.months6Period, l10n.months12Period, l10n.completeBackup].map((p) => InkWell(
                                    onTap: () async {
                                      setState(() => _showDropdown = false);
                                      try {
                                        _showToast(l10n.generatingBackup(p));
                                        final bytes = await ExcelExportService().generateExcelFile();
                                        final suffix = p.replaceAll(' ', '_').toLowerCase();
                                        final fileName = ExcelExportService().generateFileName('Shree_Clinic')
                                            .replaceAll('.xlsx', '_$suffix.xlsx');

                                        final appDir = await getApplicationDocumentsDirectory();
                                        final path = '${appDir.path}/$fileName';

                                        final file = File(path);
                                        await file.writeAsBytes(bytes);
                                        _showToast(l10n.backupSavedLocally(fileName));

                                        final syncMgr = context.read<SyncManager>();
                                        if (syncMgr.syncState != SyncState.offline) {
                                          final upload = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(l10n.uploadToDriveQuestion),
                                              content: Text(l10n.backupSavedUploadPrompt),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
                                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.upload)),
                                              ],
                                            ),
                                          );
                                          if (upload == true) {
                                            await syncMgr.backupToDriveOnly();
                                          }
                                        }
                                      } catch (e) {
                                        _showToast(l10n.backupGenFailed(e.toString()), isError: true);
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppTheme.actionButton)),
                                      ),
                                      child: Text(p, style: TextStyle(color: AppTheme.textPrimary)),
                                    ),
                                  )).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Google Cloud Sync Section
                      SectionCard(
                        child: Consumer2<SettingsProvider, SyncManager>(
                          builder: (context, settings, syncMgr, child) {
                            final googleUser = settings.googleUser;
                            final isSyncing = syncMgr.isSyncing;
                            final unsyncedCount = syncMgr.getUnsyncedCount();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.cloud_done_outlined, color: AppTheme.success, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.cloudBackupTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          googleUser != null
                                              ? l10n.googleDriveBackupActive
                                              : l10n.secureOnGoogleDrive,
                                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                if (googleUser == null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l10n.connectDriveDescription,
                                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: AppTheme.textOnPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: settings.isGoogleSigningIn
                                          ? null
                                          : () async {
                                              try {
                                                await settings.signInGoogle();
                                                if (!context.mounted) return;
                                                _fetchDriveUsage();
                                                _fetchCloudBackupHistory();
                                              } catch (e) {
                                                if (context.mounted) {
                                                  _showToast(l10n.failedToConnect(e.toString()), isError: true);
                                                }
                                              }
                                            },
                                      icon: settings.isGoogleSigningIn
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textOnPrimary),
                                            )
                                          : const Icon(Icons.link, size: 20),
                                      label: Text(
                                        settings.isGoogleSigningIn ? l10n.connecting : l10n.connectGoogleDrive,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Google account card
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      border: Border.all(color: AppTheme.border),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: googleUser.photoUrl != null
                                              ? NetworkImage(googleUser.photoUrl!)
                                              : null,
                                          child: googleUser.photoUrl == null
                                              ? Text(googleUser.displayName?[0].toUpperCase() ?? 'G')
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                googleUser.displayName ?? l10n.googleAccountLabel,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                googleUser.email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.danger,
                                            side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await settings.signOutGoogle();
                                              if (!context.mounted) return;
                                              setState(() {
                                                _cloudBackups.clear();
                                              });
                                            } catch (e) {
                                              if (context.mounted) {
                                                _showToast(l10n.failedToDisconnect(e.toString()), isError: true);
                                              }
                                            }
                                          },
                                          child: Text(l10n.disconnect, style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Last Sync Detail Label
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(l10n.lastSyncLabel, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                      Text(
                                        settings.lastSyncTime.contains(l10n.neverLabel) 
                                            ? l10n.neverLabel
                                            : settings.lastSyncTime,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Auto Sync Settings toggles
                                  SwitchListTile(
                                    title: Text(l10n.autoSyncBackups, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    subtitle: Text(l10n.uploadRecordsAutomatically, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    value: _autoSync,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: _saveAutoSync,
                                  ),
                                  
                                  if (_autoSync) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(l10n.autoSyncFrequency, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                        DropdownButton<String>(
                                          value: _syncFrequency,
                                          dropdownColor: AppTheme.surface,
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          underline: const SizedBox.shrink(),
                                          items: [l10n.dailyFrequency, l10n.weeklyFrequency, l10n.onEverySave].map((String val) {
                                            return DropdownMenuItem<String>(
                                              value: val,
                                              child: Text(val),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) _saveSyncFrequency(val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  SwitchListTile(
                                    title: Text(l10n.wifiOnlySync, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    subtitle: Text(l10n.doNotSyncOnCellular, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    value: _wifiOnly,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: _saveWifiOnly,
                                  ),
                                  const Divider(height: 24),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.dailyBackgroundBackup,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                          ),
                                          Text(
                                            l10n.scheduledAt(_backupTimeStr),
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _selectBackupTime(context, syncMgr),
                                        icon: const Icon(Icons.alarm, size: 16),
                                        label: Text(l10n.changeBtn, style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  if (isSyncing) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              l10n.syncingNRecords(unsyncedCount),
                                              style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const LinearProgressIndicator(),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ],
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: AppTheme.textOnPrimary,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: (isSyncing || syncMgr.syncState == SyncState.offline)
                                              ? null
                                              : () async {
                                                  try {
                                                    final success = await syncMgr.triggerManualSync();
                                                    if (!context.mounted) return;
                                                    if (success) {
                                                      // Update timestamp in settings
                                                      await settings.triggerSync();
                                                      _fetchDriveUsage();
                                                      _fetchCloudBackupHistory();
                                                      _showToast(l10n.syncedSuccessfully);
                                                    } else {
                                                      _showToast(l10n.syncFailedRetry, isError: true);
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      _showToast(l10n.syncFailedMessage(e.toString()), isError: true);
                                                    }
                                                  }
                                                },
                                          icon: const Icon(Icons.sync, size: 20),
                                          label: Text(isSyncing ? l10n.syncingData : l10n.syncNowBtn),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primary,
                                            side: BorderSide(color: AppTheme.primary),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: (isSyncing || syncMgr.syncState == SyncState.offline)
                                              ? null
                                              : () async {
                                                  try {
                                                    final success = await syncMgr.backupToDriveOnly();
                                                    if (!context.mounted) return;
                                                    if (success) {
                                                      // Update timestamp only (no duplicate file creation)
                                                      await settings.triggerSync();
                                                      _fetchDriveUsage();
                                                      _fetchCloudBackupHistory();
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      _showToast(l10n.uploadFailed(e.toString()), isError: true);
                                                    }
                                                  }
                                                },
                                          icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                                          label: Text(isSyncing ? l10n.uploading : l10n.uploadToDriveBtn),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Backup History Section
                      SectionCard(
                        child: Consumer<SettingsProvider>(
                          builder: (context, settings, child) {
                            final signedIn = settings.googleUser != null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.backupHistory,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary),
                                    ),
                                    if (signedIn && !_isLoadingHistory)
                                      IconButton(
                                        icon: Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                                        onPressed: _fetchCloudBackupHistory,
                                      )
                                    else
                                      Icon(Icons.access_time, color: AppTheme.textTertiary, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                if (!signedIn) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        l10n.connectDriveToViewHistory,
                                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ] else if (_isLoadingHistory) ...[
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24.0),
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 12),
                                          Text(l10n.fetchingHistory, style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else if (_cloudBackups.isEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        l10n.noBackupsInDrive,
                                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ..._cloudBackups.map((b) {
                                    final recordCount = _parseRecordCount(b.name);
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.backupFileSize(_formatSize(b.size)),
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDateTime(b.lastModified),
                                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  l10n.nRecordsSynced(recordCount),
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary,
                                                foregroundColor: AppTheme.textOnPrimary,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _confirmAndRestore(b),
                                            icon: const Icon(Icons.restore, size: 14),
                                            label: Text(l10n.restore, style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Restore Screen Progress Modal Overlay
          if (_isRestoring)
            Container(
              color: const Color(0xFF000000).withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.heavyShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        l10n.restoreInProgress,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _restoreProgressStr,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
