import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  int selectedTab = 0; 

  List<Map<String, dynamic>> available = [
    {
      "name": "Bread",
      "store": "D-Mart",
      "price": 40,
      "purchased": "14/3/2026",
      "expiry": "17/3/2026",
      "days": 2,
      "image": "assets/images/b.png"
    },
    {
      "name": "Milk",
      "store": "D-Mart",
      "price": 54,
      "purchased": "10/3/2026",
      "expiry": "18/3/2026",
      "days": 3,
      "image": "assets/images/milk.png"
    },
    {
      "name": "Oil",
      "store": "Big Bazaar",
      "price": 120,
      "purchased": "12/3/2026",
      "expiry": "19/3/2026",
      "days": 4,
      "image": "assets/images/oil.png"
    },
  ];

  List<Map<String, dynamic>> active = [];
  List<Map<String, dynamic>> sold = [];

  Color getColor(int days) {
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  void moveToActive(int index) {
    setState(() {
      active.add(available[index]);
      available.removeAt(index);
    });
  }

  void moveToSold(int index) {
    setState(() {
      sold.add(active[index]);
      active.removeAt(index);
    });
  }

  List<Map<String, dynamic>> getCurrentList() {
    if (selectedTab == 0) return available;
    if (selectedTab == 1) return active;
    return sold;
  }

  @override
  Widget build(BuildContext context) {
    final list = getCurrentList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Sell Products",
         style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
         ),
         ),
        backgroundColor: const Color.fromARGB(255, 224, 230, 228),
      ),
      body: Column(
        children: [

          const SizedBox(height: 10),

          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tab("Available", 0),
              _tab("Active", 1),
              _tab("Sold", 2),
            ],
          ),

          const SizedBox(height: 10),

         
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: getColor(p["days"]).withOpacity(0.5)),
                  ),

                  child: Column(
                    children: [

                      Row(
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
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),

                                Text("Bought from ${p["store"]}"),

                                const SizedBox(height: 6),

                                Text("₹${p["price"]}"),
                                Text("Purchased: ${p["purchased"]}"),
                                Text("Expiry: ${p["expiry"]}"),
                              ],
                            ),
                          ),

                        
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: getColor(p["days"]).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${p["days"]} days",
                              style: TextStyle(
                                color: getColor(p["days"]),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                     
                      Row(
                        children: [

                          if (selectedTab == 0) 
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => moveToActive(i),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Sell on FreshLoop"),
                              ),
                            ),

                          if (selectedTab == 1) 
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => moveToSold(i),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text("Mark as Sold"),
                              ),
                            ),

                          if (selectedTab != 2)
                            const SizedBox(width: 10),

                          if (selectedTab != 2)
                            Flexible(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text("Donate"),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}