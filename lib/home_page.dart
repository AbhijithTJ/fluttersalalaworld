import 'package:flutter/material.dart';
import 'BillingPage.dart';
import 'CustomerSearchPage.dart';
import 'ProductManagementPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salala World'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to profile page
            },
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Abhijith!', // Personalized greeting
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your business efficiently.',
                style: textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              _buildLogoBanner(colorScheme),
              const SizedBox(height: 32),
              _buildActionCard(
                context: context,
                icon: Icons.note_add_outlined,
                title: 'Generate New Bill',
                subtitle: 'Create a new invoice for a customer.',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BillingPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                icon: Icons.people_alt_outlined,
                title: 'View Customer Details',
                subtitle: 'Search and manage your customers.',
                color: Colors.orange.shade700,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CustomerSearchPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                icon: Icons.inventory_2_outlined,
                title: 'Manage Products',
                subtitle: 'Add, update, or remove items.',
                color: Colors.green.shade600,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProductManagementPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.25),
            colorScheme.surfaceVariant.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Center(child: _buildLogo(colorScheme)),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    // This widget creates a temporary logo for "Salala World".
    // You can replace this with your own Image.asset('assets/logo.png') later on.
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}