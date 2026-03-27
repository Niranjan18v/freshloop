import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedDate = "All dates";
  String selectedLocation = "All Locations";

  final List<String> locationItems = [
    "All Locations",
    "Tambaram",
    "Avadi",
    "Adyar",
    "T Nagar",
    "Koyambedu",
    "Paravakkottai",
    "West Tambaram"
  ];

  final List<Map<String, dynamic>> products = [
    {"name": "Milk", "price": 30, "old": 54, "days": 2, "loc": "Tambaram", "image": "assets/images/milk.png"},
    {"name": "Bread", "price": 25, "old": 40, "days": 1, "loc": "Avadi", "image": "assets/images/b.png"},
    {"name": "Oil", "price": 110, "old": 180, "days": 4, "loc": "Adyar", "image": "assets/images/oill.png"},
    {"name": "Soap", "price": 30, "old": 55, "days": 25, "loc": "T Nagar", "image": "assets/images/s.png"},
    {"name": "Curd", "price": 20, "old": 35, "days": 3, "loc": "Thiruvarur", "image": "assets/images/c.png"},
    {"name": "Rice", "price": 70, "old": 120, "days": 10, "loc": "Paravakkottai", "image": "assets/images/rice.png"},
    {"name": "Oats", "price": 45, "old": 80, "days": 8, "loc": "West Tambaram", "image": "assets/images/o.png"},
    {"name": "Paste", "price": 10, "old": 20, "days": 50, "loc": "Tambaram", "image": "assets/images/red.png"},
    {"name": "Nuts", "price": 60, "old": 90, "days": 2, "loc": "Avadi", "image": "assets/images/n.png"},
    {"name": "Horlicks", "price": 40, "old": 70, "days": 5, "loc": "Adyar", "image": "assets/images/h.png"},
  ];

  List<Map<String, dynamic>> getSortedProducts() {
    List<Map<String, dynamic>> sorted = List.from(products);

    sorted.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      if (selectedDate == "Within 3 days") {
        if (a["days"] <= 3) scoreA += 2;
        if (b["days"] <= 3) scoreB += 2;
      } else if (selectedDate == "Within 7 days") {
        if (a["days"] <= 7) scoreA += 2;
        if (b["days"] <= 7) scoreB += 2;
      } else if (selectedDate == "Within 14 days") {
        if (a["days"] <= 14) scoreA += 2;
        if (b["days"] <= 14) scoreB += 2;
      }

      if (selectedLocation != "All Locations") {
        if (a["loc"] == selectedLocation) scoreA += 3;
        if (b["loc"] == selectedLocation) scoreB += 3;
      }

      return scoreB.compareTo(scoreA);
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = getSortedProducts();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

            

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Marketplace",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),


              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search products...",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

          
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [

                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: selectedDate,
                        decoration:
                            const InputDecoration(labelText: "Expiry Date"),
                        items: [
                          "All dates",
                          "Within 3 days",
                          "Within 7 days",
                          "Within 14 days"
                        ]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedDate = v!),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: locationItems.contains(selectedLocation)
                            ? selectedLocation
                            : "All Locations",
                        decoration:
                            const InputDecoration(labelText: "Location"),
                        items: locationItems
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedLocation = v!),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${displayProducts.length} products found",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 10),

           
              Expanded(
                child: ListView.builder(
                  itemCount: displayProducts.length,
                  itemBuilder: (_, i) {
                    final p = displayProducts[i];
                    bool urgent = p["days"] <= 3;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: p),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: urgent
                                ? Colors.red.shade300
                                : Colors.green.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12, blurRadius: 6)
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                       
                            Stack(
                              children: [
                                Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18)),
                                    image: DecorationImage(
                                      image: AssetImage(p["image"]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: urgent
                                          ? Colors.red
                                          : Colors.green,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${p["days"]} days left",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(p["name"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      Text("₹${p["price"]}",
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight:
                                                  FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text("₹${p["old"]}",
                                          style: const TextStyle(
                                              decoration: TextDecoration
                                                  .lineThrough,
                                              color: Colors.grey)),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14,
                                          color: Colors.grey),
                                      Text(" ${p["loc"]}",
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}