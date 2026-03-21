import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {

  List<Map<String, dynamic>> products = [
    {"name": "Biscut", "store": "D-Mart", "price": 40, "purchased": "14/3/2026", "expiry": "17/3/2026", "image": "assets/images/bread.png"},
    {"name": "Milk", "store": "D-Mart", "price": 54, "purchased": "10/3/2026", "expiry": "18/3/2026", "image": "assets/images/milk1.png"},
    {"name": "Curd", "store": "Reliance", "price": 30, "purchased": "12/3/2026", "expiry": "16/3/2026", "image": "assets/images/curd.png"},
    {"name": "Oil", "store": "Big Bazaar", "price": 120, "purchased": "12/3/2026", "expiry": "19/3/2026", "image": "assets/images/oil.png"},
    {"name": "Soap", "store": "Reliance", "price": 125, "purchased": "1/3/2026", "expiry": "1/9/2026", "image": "assets/images/soap.png"},
    {"name": "Maggi", "store": "Reliance", "price": 45, "purchased": "13/3/2026", "expiry": "21/3/2026", "image": "assets/images/maggi.png"},
    {"name": "Garam Masala", "store": "Spar", "price": 85, "purchased": "8/3/2026", "expiry": "22/3/2026", "image": "assets/images/masala.png"},
    {"name": "Biscuits", "store": "D-Mart", "price": 85, "purchased": "5/3/2026", "expiry": "30/3/2026", "image": "assets/images/bread.png"},
    {"name": "Rice", "store": "Big Bazaar", "price": 300, "purchased": "1/3/2026", "expiry": "1/12/2026", "image": "assets/images/rice.png"},
    {"name": "Horlicks", "store": "Reliance", "price": 360, "purchased": "2/3/2026", "expiry": "2/12/2026", "image": "assets/images/horlicks.png"},
    {"name": "Paste", "store": "D-Mart", "price": 120, "purchased": "10/3/2026", "expiry": "10/10/2026", "image": "assets/images/red.png"},
    {"name": "Nuts", "store": "Reliance", "price": 350, "purchased": "11/3/2026", "expiry": "20/3/2026", "image": "assets/images/nuts.png"},
    {"name": "Juice", "store": "D-Mart", "price": 40, "purchased": "9/3/2026", "expiry": "25/3/2026", "image": "assets/images/campa.png"},
    {"name": "Boost", "store": "Local Store", "price": 390, "purchased": "14/3/2026", "expiry": "20/3/2026", "image": "assets/images/boost.png"},
    {"name": "Oats", "store": "Reliance", "price": 250, "purchased": "13/3/2026", "expiry": "28/3/2026", "image": "assets/images/oats.png"},
  ];

  void removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  int getDaysLeft(String expiry) {
    final parts = expiry.split('/');
    final expDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    return expDate.difference(DateTime.now()).inDays;
  }

  Color getColor(int days) {
    if (days <= 5) return Colors.red;
    if (days <= 14) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {

    
    products.sort((a, b) =>
        getDaysLeft(a["expiry"]).compareTo(getDaysLeft(b["expiry"])));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("My Products"),
        backgroundColor: AppColors.primary,
      ),

      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          final days = getDaysLeft(p["expiry"]);

          return Stack(
            children: [

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: getColor(days).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: getColor(days)),
                ),

                child: Row(
                  children: [

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        p["image"],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            p["name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          Text("Bought from ${p["store"]}"),

                          const SizedBox(height: 6),

                          Text("₹${p["price"]}"),
                          Text("Purchased: ${p["purchased"]}"),
                          Text("Expiry: ${p["expiry"]}"),

                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: () => removeProduct(i),
                            child: const Text("Use it"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 20,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getColor(days),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$days days",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}