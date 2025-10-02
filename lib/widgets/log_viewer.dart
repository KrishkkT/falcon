import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/log_service.dart';
import '../theme/app_theme.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  String _filterTag = '';
  String _filterLevel = 'ALL';
  bool _autoScroll = true;
  bool _wrapText = false;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Log Viewer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Controls
          _buildControls(),

          const SizedBox(height: 16),

          // Log List
          Expanded(
            child: Consumer<LogService>(
              builder: (context, logService, child) {
                final logs = logService.getLogs();

                // Apply filters
                final filteredLogs = logs.where((log) {
                  bool matchesTag = _filterTag.isEmpty ||
                      log.tag.toLowerCase().contains(_filterTag.toLowerCase());
                  bool matchesLevel =
                      _filterLevel == 'ALL' || log.level == _filterLevel;
                  return matchesTag && matchesLevel;
                }).toList();

                // Auto-scroll to bottom when new logs are added
                if (_autoScroll && filteredLogs.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _buildLogEntry(log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Filter by tag',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _filterTag = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _filterLevel,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Levels')),
                DropdownMenuItem(value: 'DEBUG', child: Text('Debug')),
                DropdownMenuItem(value: 'INFO', child: Text('Info')),
                DropdownMenuItem(value: 'WARN', child: Text('Warning')),
                DropdownMenuItem(value: 'ERROR', child: Text('Error')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filterLevel = value;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value ?? true;
                          });
                        },
                      ),
                      const Text('Auto-scroll'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _wrapText,
                        onChanged: (value) {
                          setState(() {
                            _wrapText = value ?? false;
                          });
                        },
                      ),
                      const Text('Wrap text'),
                    ],
                  ),
                ],
              ),
            ),
            Consumer<LogService>(
              builder: (context, logService, child) {
                return TextButton(
                  onPressed: logService.clearLogs,
                  child: const Text('Clear Logs'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color levelColor;
    IconData levelIcon;

    switch (log.level) {
      case 'DEBUG':
        levelColor = Colors.blue;
        levelIcon = Icons.bug_report;
        break;
      case 'INFO':
        levelColor = Colors.green;
        levelIcon = Icons.info;
        break;
      case 'WARN':
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case 'ERROR':
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
      default:
        levelColor = AppTheme.greyColor;
        levelIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(levelIcon, color: levelColor, size: 16),
            const SizedBox(width: 8),
            Text(
              '${log.timestamp.toString().split('.').first} [${log.level}] ${log.tag}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: levelColor,
              ),
            ),
          ],
        ),
        subtitle: Text(
          log.message,
          maxLines: _wrapText ? null : 2,
          overflow: _wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    log.stackTrace!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppTheme.greyColor,
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
