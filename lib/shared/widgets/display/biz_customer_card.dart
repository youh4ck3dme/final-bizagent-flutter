import 'package:flutter/material.dart';
import '../../../../core/ui/biz_theme.dart';

class BizCustomerCard extends StatelessWidget {
  final String name;
  final String? email;
  final String? phone;
  final VoidCallback? onTap;

  const BizCustomerCard({
    super.key,
    required this.name,
    this.email,
    this.phone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join();

    return Card(
      margin: const EdgeInsets.only(bottom: BizTheme.spacingSm),
      child: Semantics(
        label: 'Zákazník $name${email != null ? ', email $email' : ''}${phone != null ? ', telefón $phone' : ''}',
        button: onTap != null,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(BizTheme.spacingSm), // slightly tighter than invoice
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: (email != null || phone != null) 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (email != null) Text(email!, style: theme.textTheme.bodySmall),
                  if (phone != null) Text(phone!, style: theme.textTheme.bodySmall),
                ],
              )
            : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
