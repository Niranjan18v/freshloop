import 'package:flutter/material.dart';
import 'budget_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

             
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Profile",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),

              const SizedBox(height: 10),

             
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFFE6F4EA),
                      child: Icon(Icons.person, size: 40, color: Colors.green),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Sai Thanuja",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16),
                        SizedBox(width: 6),
                        Text("+91 99887 76655"),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 6),
                        Text("Paravakkottai"),
                      ],
                    ),

                    const SizedBox(height: 16),

                   
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BudgetScreen()),
                        );
                      },
                      child: const Text(
                        "Budget & Analytics",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  _statCard("1,350", "Credit Points", Icons.currency_rupee),
                  const SizedBox(width: 10),
                  _statCard("10", "Rewards Earned", Icons.emoji_events),
                  const SizedBox(width: 10),
                  _statCard("25", "Products Saved", Icons.inventory),
                ],
              ),

              const SizedBox(height: 20),

              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Activity",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    _activityItem(
                      "assets/images/b.png",
                      "Britannia Bread (400g)",
                      "₹40 • 16/3/2026",
                      "Selling",
                    ),

                    _activityItem(
                      "assets/images/milk1.png",
                      "Amul Taza Milk (1L)",
                      "₹54 • 16/3/2026",
                      "Selling",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  
  Widget _activityItem(
      String img, String name, String price, String status) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(img,
                width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                Text(price,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.green),
            ),
          )
        ],
      ),
    );
  }
}