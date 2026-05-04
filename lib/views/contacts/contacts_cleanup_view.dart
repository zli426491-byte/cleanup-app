import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/contacts_service.dart';
import '../../utils/app_theme.dart';

class ContactsCleanupView extends StatelessWidget {
  const ContactsCleanupView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ContactsCleanupService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('聯絡人'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => service.scanContacts(),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '重複 (${service.duplicateGroups.length})'),
              Tab(text: '不完整 (${service.incompleteContacts.length})'),
            ],
          ),
        ),
        body: Stack(
          children: [
            service.isScanning
                ? const Center(child: CircularProgressIndicator())
                : service.duplicateGroups.isEmpty && service.incompleteContacts.isEmpty
                    ? _buildEmptyState(service)
                    : TabBarView(
                        children: [
                          _buildDuplicatesList(service),
                          _buildIncompleteList(service),
                        ],
                      ),
            // Coming Soon overlay
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.construction_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('即將推出',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('聯絡人清理功能正在開發中，敬請期待',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ContactsCleanupService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 60, color: AppTheme.success),
          const SizedBox(height: 16),
          const Text('聯絡人很乾淨！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => service.scanContacts(),
            child: const Text('掃描聯絡人'),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatesList(ContactsCleanupService service) {
    return ListView.builder(
      itemCount: service.duplicateGroups.length,
      itemBuilder: (ctx, i) {
        final group = service.duplicateGroups[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...group.contacts.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c.phoneNumbers.isNotEmpty ? c.phoneNumbers.first : ''),
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => service.mergeContacts(group),
                    icon: const Icon(Icons.merge, size: 16),
                    label: const Text('全部合併'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncompleteList(ContactsCleanupService service) {
    return ListView.builder(
      itemCount: service.incompleteContacts.length,
      itemBuilder: (ctx, i) {
        final c = service.incompleteContacts[i];
        return ListTile(
          leading: const CircleAvatar(
              backgroundColor: AppTheme.warning,
              child: Icon(Icons.person, color: Colors.white)),
          title: Text(c.displayName),
          subtitle: Wrap(
            spacing: 4,
            children: [
              if (c.displayName.trim().isEmpty) _badge('無姓名'),
              if (c.phoneNumbers.isEmpty) _badge('無電話'),
              if (c.emails.isEmpty) _badge('無信箱'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.danger),
            onPressed: () => service.deleteContact(c),
          ),
        );
      },
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(color: AppTheme.warning, fontSize: 10)),
    );
  }
}
