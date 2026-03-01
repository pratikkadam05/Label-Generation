import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'add_edit_user_screen.dart';
import 'print_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Application'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Import Excel
          IconButton(
            onPressed: () => _importExcel(context),
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Excel',
          ),
          // Export Excel
          IconButton(
            onPressed: () => _exportExcel(context),
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Excel',
          ),
          // More Options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Banner
          Consumer<UserProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total Users: ${provider.totalUsers}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Data stored securely',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<UserProvider>(
              builder: (context, provider, child) {
                return TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.searchUsers(value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, address, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                );
              },
            ),
          ),

          // User List
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, child) {
                if (provider.loadingState == LoadingState.loading &&
                    provider.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'No users found'
                              : 'No users yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'Try a different search'
                              : 'Tap + to add your first user\nor import from Excel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.users.length,
                  itemBuilder: (context, index) {
                    final user = provider.users[index];
                    return _buildUserCard(context, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddUser(context),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPrintDialog(context, user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(context, value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'print',
                    child: ListTile(
                      leading: Icon(Icons.print),
                      title: Text('Print'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context, UserModel user) {
    int copies = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Print Labels'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How many labels do you want to print for ${user.name}?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: copies > 1 ? () => setState(() => copies--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$copies',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: copies < 100 ? () => setState(() => copies++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [1, 5, 10, 20].map((n) {
                  return ActionChip(
                    label: Text('$n'),
                    onPressed: () => setState(() => copies = n),
                    backgroundColor: copies == n
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrintPreviewScreen(
                      user: user,
                      copies: copies,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.preview),
              label: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(BuildContext context, String action, UserModel user) {
    switch (action) {
      case 'print':
        _showPrintDialog(context, user);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditUserScreen(user: user),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, user);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserProvider>().deleteUser(user.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    if (action == 'clear') {
      _showClearDataConfirmation(context);
    }
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all users? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserProvider>().clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _importExcel(BuildContext context) async {
    final provider = context.read<UserProvider>();
    final success = await provider.importFromExcel();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Users imported successfully'
              : provider.errorMessage ?? 'Import cancelled'),
        ),
      );
    }
  }

  void _exportExcel(BuildContext context) async {
    final provider = context.read<UserProvider>();

    if (provider.totalUsers == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users to export')),
      );
      return;
    }

    final filePath = await provider.exportToExcel();

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Excel file created'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => provider.shareExcel(filePath),
          ),
        ),
      );
    }
  }

  void _navigateToAddUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditUserScreen()),
    );
  }
}
