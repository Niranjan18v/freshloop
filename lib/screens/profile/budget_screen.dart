import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Budget & Analytics"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          
          Row(
            children: [
              _card("₹16,500", "Total Spent"),
              const SizedBox(width: 10),
              _card("₹5,460", "Total Saved"),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _card("14", "Items Sold"),
              const SizedBox(width: 10),
              _card("9", "Items Donated"),
            ],
          ),

          const SizedBox(height: 20),

      
          _chartContainer(
            "Monthly Spending vs Savings",
            SizedBox(height: 200, child: _barChart()),
          ),

          const SizedBox(height: 16),

      
          _chartContainer(
            "Spending by Category",
            SizedBox(height: 200, child: _pieChart()),
          ),

          const SizedBox(height: 16),

          _chartContainer(
            "Cumulative Savings Over Time",
            SizedBox(height: 200, child: _lineChart()),
          ),
        ],
      ),
    );
  }

  Widget _card(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }


  Widget _chartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          chart,
        ],
      ),
    );
  }

  
  Widget _barChart() {
    return BarChart(
      BarChartData(
        barGroups: List.generate(6, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: (i + 1) * 500.0),
            BarChartRodData(toY: (i + 1) * 300.0),
          ]);
        }),
      ),
    );
  }

  
  Widget _pieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 40),
          PieChartSectionData(value: 20),
          PieChartSectionData(value: 15),
          PieChartSectionData(value: 10),
          PieChartSectionData(value: 5),
        ],
      ),
    );
  }

  Widget _lineChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 1000),
              FlSpot(1, 1500),
              FlSpot(2, 2200),
              FlSpot(3, 3000),
              FlSpot(4, 3800),
              FlSpot(5, 5000),
            ],
          )
        ],
      ),
    );
  }
}