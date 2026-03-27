import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // ── 🛡️ NOTIFICATION INITIALIZATION ───────────────────────────────────
  final notifications = NotificationService();
  await notifications.init();
  
  // ── 🌑 WORKMANAGER REGISTRATION ──────────────────────────────────────
  Workmanager().initialize(
    callbackDispatcher, 
    isInDebugMode: true 
  );
  
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
        appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
      ),
      // ── 🛡️ AUTHENTICATION GATE ───────────────────────────────────────
      // Automatically switches between Login and Home based on Firebase Auth State.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While checking for the session...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5D8064))));
          }
          // If a user is logged in, show the App Navigation
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          // Otherwise, show the Login Screen
          return const LoginScreen();
        },
      ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -10))],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5D8064),
          unselectedItemColor: Colors.black26,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: "Shop"),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: "Add"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: "Products"),
            BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), label: "Sell"),
          ],
        ),
      ),
    );
  }
}