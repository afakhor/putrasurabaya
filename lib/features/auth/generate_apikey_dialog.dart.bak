import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/features/auth/auth_provider.dart';

class GenerateApiKeyDialog extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const GenerateApiKeyDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  ConsumerState<GenerateApiKeyDialog> createState() => _GenerateApiKeyDialogState();
}

class _GenerateApiKeyDialogState extends ConsumerState<GenerateApiKeyDialog> {
  UserRole _selectedRole = UserRole.salesman;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AlertDialog(
      title: Text('Generate API Key: ${widget.targetUserName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Peran Akun:'),
          DropdownButton<UserRole>(
            value: _selectedRole,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: UserRole.admin,
                child: Text('Admin (Review Omset, Sales & KPI)'),
              ),
              DropdownMenuItem(
                value: UserRole.salesman,
                child: Text('Salesman / Kasir (Operasional POS)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
          const SizedBox(height: 16),
          if (authState.generatedApiKey != null) ...[
            const Text('API Key Berhasil Dibuat:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      authState.generatedApiKey!,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: authState.generatedApiKey!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key berhasil disalin!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(authProvider.notifier).clearGeneratedApiKey();
            Navigator.pop(context);
          },
          child: const Text('Tutup'),
        ),
        ElevatedButton(
          onPressed: authState.isLoading
              ? null
              : () async {
                  await ref.read(authProvider.notifier).generateApiKeyForRole(
                        targetUserId: widget.targetUserId,
                        targetRole: _selectedRole,
                      );
                },
          child: const Text('Generate Key Baru'),
        ),
      ],
    );
  }
}
