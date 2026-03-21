import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/add/add_product_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/sales/sell_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FreshLoop',
      theme: ThemeData(useMaterial3: true),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int index = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    ShopScreen(),
    AddProductScreen(),
    ProductsScreen(),
    SellScreen(),
  ];

  void _onTap(int i) {
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: _onTap,

        backgroundColor: const Color(0xFF5D8064),

        selectedItemColor: const Color(0xFFA8D5BA), 
        unselectedItemColor: Colors.white70,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Shop",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Products",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: "Sell",
          ),
        ],
      ),
    );
  }
}