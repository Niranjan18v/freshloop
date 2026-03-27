import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'core/app_colors.dart';
import 'services/notification_service.dart';
import 'services/expiry_checker.dart';
import 'background/task_handler.dart';

import 'screens/home/home_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/add/add_product_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/sales/sell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // ── 🛡️ NOTIFICATION INITIALIZATION ───────────────────────────────────
  final notifications = NotificationService();
  await notifications.init();
  
  // ── 🌑 WORKMANAGER REGISTRATION ──────────────────────────────────────d
  // Initializes background task dispatcher for 'FreshLoop'
  Workmanager().initialize(
    callbackDispatcher, 
    isInDebugMode: true // Set to false for production
  );
  
  // Register a periodic task (runs every 6 hours by default)
  Workmanager().registerPeriodicTask(
    "1", 
    "expiryTask", 
    frequency: const Duration(hours: 6),
    constraints: Constraints(networkType: NetworkType.connected)
  );
  
  // Run immediate scan on launch
  await ExpiryCheckerService().checkExpiry();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FreshLoop',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF5D8064),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        backgroundColor: const Color(0xFF5D8064),
        selectedItemColor: const Color(0xFFA8D5BA),
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: "Sell"),
        ],
      ),
    );
  }
}