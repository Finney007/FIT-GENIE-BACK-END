import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class DashboardScreen extends StatelessWidget {
  final int userId;
  final String email;

  const DashboardScreen({Key? key, required this.userId, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${email.split('@')[0]}!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildInfoCard(
            title: 'Health Summary',
            content: 'Track your health metrics and progress',
            icon: Icons.favorite,
            color: Colors.redAccent,
          ),
          SizedBox(height: 16),
          _buildInfoCard(
            title: 'AI Health Assistant',
            content: 'Get personalized health advice using AI',
            icon: Icons.psychology,
            color: Colors.blueAccent,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen(userId: userId, email: email)),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoCard(
            title: 'Nutrition Tracking',
            content: 'Log and monitor your daily nutrition intake',
            icon: Icons.restaurant_menu,
            color: Colors.orangeAccent,
          ),
          SizedBox(height: 16),
          _buildInfoCard(
            title: 'Fitness Activities',
            content: 'Track your workouts and physical activities',
            icon: Icons.fitness_center,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}