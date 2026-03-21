import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

import '../profile/profile_screen.dart';
import '../products/products_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final PageController _controller = PageController();
  int currentPage = 0;
  Timer? timer;

  final List<Map<String, dynamic>> products = [
    {"name": "Milk", "days": 2, "image": "assets/images/milk1.png"},
    {"name": "Bread", "days": 1, "image": "assets/images/b.png"},
    {"name": "Curd", "days": 3, "image": "assets/images/curd.png"},
    {"name": "Oil", "days": 10, "image": "assets/images/oil.png"},
    {"name": "Soap", "days": 20, "image": "assets/images/soap.png"},
  ];

  void openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (currentPage < 2) {
        currentPage++;
      } else {
        currentPage = 0;
      }

      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

             
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green),

                    const SizedBox(width: 8),

                    const Text(
                      "FRESHLOOP",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () => openPage(context, const ProfileScreen()),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

           
              Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      children: [
                        _slideCard("Expiring Soon", "Use items before waste", "assets/images/expiring-soon.png", () {}),
                        _slideCard("Your Products", "Manage inventory", "assets/images/products.png",
                            () => openPage(context, const ProductsScreen())),
                        _slideCard("Shop Deals", "Buy discounted items", "assets/images/sales.png",
                            () => openPage(context, const ShopScreen())),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: currentPage == index ? 18 : 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? AppColors.primary
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

            
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "⏰ Expiring Soon",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              ...products.where((p) => p["days"] <= 3).map((p) => _productCard(p)),

              const SizedBox(height: 10),

         
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "🟢 Fresh Products",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              ...products.where((p) => p["days"] > 3).map((p) => _productCard(p)),

              const SizedBox(height: 10),

              
              GestureDetector(
                onTap: () => openPage(context, const ProductsScreen()),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    "Show More",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slideCard(String title, String subtitle, String img, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(img),
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    bool isUrgent = p["days"] <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(p["image"], width: 60, height: 60),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${p["days"]} days left",
                    style: TextStyle(
                        color: isUrgent ? Colors.red : Colors.green)),
              ],
            ),
          ),

          Icon(
            isUrgent ? Icons.warning : Icons.check_circle,
            color: isUrgent ? Colors.red : Colors.green,
          )
        ],
      ),
    );
  }
}