import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    bool urgent = product["days"] <= 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(product["name"]),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            
            Container(
              height: 220,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(product["image"]), 
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(product["name"],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text("₹${product["price"]}",
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text("₹${product["old"]}",
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text("${product["days"]} days left",
                      style: TextStyle(
                          color: urgent ? Colors.red : Colors.green)),

                  const SizedBox(height: 20),

                  const Text("Seller Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Name: Karthi"),
                        const SizedBox(height: 5),
                        Text("Address: ${product["loc"]}, Chennai, Tamil Nadu"),
                        const SizedBox(height: 5),
                        const Text("Contact: +91 9876543210"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}