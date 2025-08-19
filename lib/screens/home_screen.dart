import 'package:flutter/material.dart';
import 'reports_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing Manager Dashboard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMenuButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'New Transaction',
                onPressed: () {
                  // Navigate to the form to create a new transaction (passing null)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionFormScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildMenuButton(
                context,
                icon: Icons.list_alt_rounded,
                label: 'View Transactions',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildMenuButton(
                context,
                icon: Icons.bar_chart_rounded,
                label: 'Monthly Reports',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }
}
