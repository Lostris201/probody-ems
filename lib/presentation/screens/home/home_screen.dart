import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProBody Systems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await UserRepository().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan dekorasyonu
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[50]!,
                    Colors.blue[100]!,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Ana içerik
          Center(
            child: isTablet
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // İnsan figürü ve kas grubu (placeholder görsel)
                      Container(
                        width: 220,
                        height: 340,
                        margin: const EdgeInsets.only(right: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/images/human_muscle_tablet.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.person_outline, size: 120, color: Colors.grey[300]),
                            ),
                          ),
                        ),
                      ),
                      // Menü kartları
                      _buildMenuGrid(context, crossAxisCount: 2),
                    ],
                  )
                : _buildMenuGrid(context, crossAxisCount: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, {int crossAxisCount = 2}) {
    return SizedBox(
      width: 400,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: crossAxisCount,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            'Antrenman',
            Icons.fitness_center,
            AppRoutes.training,
          ),
          _buildMenuCard(
            context,
            'Programlar',
            Icons.schedule,
            AppRoutes.programs,
          ),
          _buildMenuCard(
            context,
            'Profil',
            Icons.person,
            AppRoutes.profile,
          ),
          _buildMenuCard(
            context,
            'Cihazlar',
            Icons.bluetooth,
            AppRoutes.training,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 6,
        shadowColor: Colors.blueAccent.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, route),
          splashColor: Colors.orangeAccent.withOpacity(0.10),
          highlightColor: Colors.orange.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.blueAccent),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
