import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'appointment_history_screen.dart';
import 'login_screen.dart';
import 'specialist_availability_screen.dart';
import 'specialist_profile_screen.dart';

class SpecialistDashboardScreen extends StatelessWidget {
  const SpecialistDashboardScreen({super.key});

  static const routeName = '/specialist-dashboard';

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.profile ?? const <String, dynamic>{};
    final consultationFee = _asNum(profile['consultation_fee']);
    final patientsConsulted = _asNum(profile['patients_consulted']).toInt();
    final isVerified = profile['is_verified'] == true;
    final hasActiveSlots =
        (profile['availability_summary'] as Map<String, dynamic>?)?['has_active_slots'] ==
            true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Specialist Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroHeader(
            name: user?.name ?? 'Specialist',
            email: user?.email ?? '',
            specialization:
                _stringOrFallback(profile['specialization'], 'Add specialization later'),
            isVerified: isVerified,
            onEditProfile: () {
              Navigator.of(context).pushNamed(SpecialistProfileScreen.routeName);
            },
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _MetricCard(
                title: 'Patients Consulted',
                value: '$patientsConsulted',
                subtitle: 'Total patient conversations',
                icon: Icons.groups_2_outlined,
              ),
              _MetricCard(
                title: 'Consultation Fee',
                value: 'Rs. ${consultationFee.toStringAsFixed(0)}',
                subtitle: 'Per patient session',
                icon: Icons.currency_rupee,
              ),
              _MetricCard(
                title: 'Availability',
                value: hasActiveSlots ? 'Open' : 'Closed',
                subtitle: 'Slot setup status',
                icon: Icons.calendar_month_outlined,
              ),
              _MetricCard(
                title: 'Verification',
                value: isVerified ? 'Verified' : 'Pending',
                subtitle: 'Certificate review comes later',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Progress Graph',
            subtitle: 'Appointment completion and follow-up trend',
          ),
          const SizedBox(height: 12),
          const _ProgressLineChart(),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Monthly Progress',
            subtitle: 'Current month breakdown',
          ),
          const SizedBox(height: 12),
          const _ProgressPieChart(
            title: 'Monthly Progress Status',
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Yearly Progress',
            subtitle: 'This year at a glance',
          ),
          const SizedBox(height: 12),
          const _ProgressPieChart(
            title: 'Yearly Progress Status',
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Profile Snapshot',
            subtitle: 'Role-specific data stored in specialist_profiles',
          ),
          const SizedBox(height: 12),
          _ProfileCard(profile: profile),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    required this.email,
    required this.specialization,
    required this.isVerified,
    required this.onEditProfile,
  });

  final String name;
  final String email;
  final String specialization;
  final bool isVerified;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: Icon(
                  isVerified ? Icons.verified : Icons.pending_outlined,
                  size: 18,
                ),
                label: Text(isVerified ? 'Verified' : 'Pending'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            specialization,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Specialist tools are now separated from the patient dashboard, which keeps the next features much easier to build.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                SpecialistAvailabilityScreen.routeName,
              );
            },
            icon: const Icon(Icons.schedule_outlined),
            label: const Text('Manage Availability'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const AppointmentHistoryScreen(role: 'specialist'),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View Appointments'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProgressLineChart extends StatelessWidget {
  const _ProgressLineChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const points = [
      FlSpot(0, 0),
      FlSpot(1, 0),
      FlSpot(2, 0),
      FlSpot(3, 0),
      FlSpot(4, 0),
      FlSpot(5, 0),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 5,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[index]),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      barWidth: 4,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No specialist progress records yet. We will connect this chart to real appointment, follow-up, and test data in the next backend phase.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPieChart extends StatelessWidget {
  const _ProgressPieChart({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 44,
                        sectionsSpace: 3,
                        sections: [
                          PieChartSectionData(
                            value: 100,
                            title: '',
                            radius: 54,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendRow(
                          color: theme.colorScheme.outlineVariant,
                          title: 'No records yet',
                          value: '0',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The pie chart will use real specialist analytics once we add appointments and home test workflow tables.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title)),
        Text(value),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, String>>[
      MapEntry(
        'Specialization',
        _stringOrFallback(profile['specialization'], 'Not added yet'),
      ),
      MapEntry(
        'Experience',
        '${_asNum(profile['years_of_experience']).toInt()} years',
      ),
      MapEntry(
        'City',
        _stringOrFallback(profile['city'], 'Not added yet'),
      ),
      MapEntry(
        'State',
        _stringOrFallback(profile['state'], 'Not added yet'),
      ),
      MapEntry(
        'Languages',
        _joinList(profile['languages']),
      ),
      MapEntry(
        'Phone',
        _stringOrFallback(profile['phone'], 'Not added yet'),
      ),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              if (entry.key != entries.last.key) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

double _asNum(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _stringOrFallback(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _joinList(dynamic value) {
  if (value is List) {
    final items = value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty);
    final joined = items.join(', ');
    if (joined.isNotEmpty) {
      return joined;
    }
  }
  return 'Not added yet';
}
