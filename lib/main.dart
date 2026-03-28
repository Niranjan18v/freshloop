import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/expiry_checker.dart';
import 'background/task_handler.dart';

import 'screens/home/home_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/add/add_product_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/sales/sell_screen.dart';
import 'screens/login_screen.dart';

import 'package:flutter/foundation.dart'; // ✅ ADDED

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

// ✅ FIX: Safe Firebase init
try {
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);
} catch (e) {
print("Firebase init error: $e");
}

final notifications = NotificationService();
await notifications.init();

// ✅ FIX: Avoid crash on Web
if (!kIsWeb) {
Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
Workmanager().registerPeriodicTask(
"1",
"expiryTask",
frequency: const Duration(minutes: 15),
constraints: Constraints(networkType: NetworkType.connected),
);
}

runApp(const MyApp());

// ✅ FIX: Avoid crash on Web
if (!kIsWeb) {
ExpiryCheckerService().checkExpiry();
}
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
appBarTheme: const AppBarTheme(
elevation: 0,
backgroundColor: Colors.transparent,
),
),
home: StreamBuilder<User?>(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (context, snapshot) {
Widget activeScreen;


      if (snapshot.connectionState == ConnectionState.waiting) {
        activeScreen = const Scaffold(
          key: ValueKey('loading'),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5D8064),
            ),
          ),
        );
      } else if (snapshot.hasData) {
        activeScreen = MainNavigation(
          key: MainNavigation.navKey,
        );
      } else {
        activeScreen = const LoginScreen(
          key: ValueKey('login'),
        );
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: activeScreen,
      );
    },
  ),
);


}
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// 🚀 GLOBAL ACCESS TO NAVIGATION
  static final GlobalKey<MainNavigationState> navKey = GlobalKey<MainNavigationState>();

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
int index = 0;

void setTabIndex(int i) {
  if (mounted) setState(() => index = i);
}

final List<Widget> screens = const [
HomeScreen(),
ShopScreen(),
AddProductScreen(),
ProductsScreen(),
SellScreen(),
];

@override
void initState() {
  super.initState();
  NotificationService().startShopListener((title, body) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(body, style: const TextStyle(color: Colors.white70)),
                  ]
                )
              )
            ]
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 4),
          dismissDirection: DismissDirection.up,
        )
      );
    }
  });
}

@override
Widget build(BuildContext context) {
return Scaffold(
extendBody: true,
body: IndexedStack(
index: index,
children: screens,
),
bottomNavigationBar: ClipRRect(
borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
child: Container(
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.75),
border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 20,
offset: const Offset(0, -5),
)
],
),
child: BottomNavigationBar(
currentIndex: index,
onTap: (i) {
HapticFeedback.lightImpact();
setState(() => index = i);
},
backgroundColor: Colors.transparent,
elevation: 0,
selectedItemColor: const Color(0xFF5D8064),
unselectedItemColor: Colors.black38,
selectedLabelStyle: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 13,
),
unselectedLabelStyle: const TextStyle(fontSize: 12),
type: BottomNavigationBarType.fixed,
items: const [
BottomNavigationBarItem(
icon: Icon(Icons.home_filled), label: "Home"),
BottomNavigationBarItem(
icon: Icon(Icons.storefront_rounded), label: "Shop"),
BottomNavigationBarItem(
icon: Icon(Icons.add_circle_outline_rounded), label: "Add"),
BottomNavigationBarItem(
icon: Icon(Icons.inventory_2_outlined), label: "Products"),
BottomNavigationBarItem(
icon: Icon(Icons.sell_outlined), label: "Sell"),
],
),
),
),
),
);
}
}
