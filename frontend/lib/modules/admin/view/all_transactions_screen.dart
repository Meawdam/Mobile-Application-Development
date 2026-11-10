import 'package:flutter/material.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  // ข้อมูลจำลอง ใช้ชื่อบุคคลจริง และรองรับทั้งการรับเงินและคืนเงินทั้งสองฝั่ง
  final allTransactions = [
    {
      'title': 'Deposit Refunded - Lab Coat',
      'user': 'Anucha Khetthong',
      'time': '28 Oct. 14:30',
      'amount': '-฿500.00',
      'isIncome': false,
      'isPending': false,
    },
    {
      'title': 'Fine Payment - Calculator',
      'user': 'Thanakon Srisuk',
      'time': '29 Oct. 09:10',
      'amount': '+฿50.00',
      'isIncome': true,
      'isPending': false,
    },
    {
      'title': 'Deposit Held - Microscope',
      'user': 'Pimchanok Sriboon',
      'time': '30 Oct. 10:15',
      'amount': '+฿1,500.00',
      'isIncome': true,
      'isPending': true,
    },
    {
      'title': 'Deposit Held - Laptop Stand',
      'user': 'Somchai Jaidee',
      'time': '30 Oct. 11:45',
      'amount': '+฿300.00',
      'isIncome': true,
      'isPending': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    var filteredList = [];

    for (var tx in allTransactions) {
      bool matchesCategory = true;
      if (selectedFilter == 'Pending Refund') {
        matchesCategory = tx['isPending'] == true;
      } else if (selectedFilter == 'Collected') {
        matchesCategory = tx['isIncome'] == true && tx['isPending'] == false;
      } else if (selectedFilter == 'Refunded') {
        matchesCategory = tx['isIncome'] == false;
      }

      String query = _searchController.text.toLowerCase();
      bool matchesSearch = query.isEmpty ||
          tx['title'].toString().toLowerCase().contains(query) ||
          tx['user'].toString().toLowerCase().contains(query) ||
          tx['time'].toString().toLowerCase().contains(query);

      if (matchesCategory && matchesSearch) {
        filteredList.add(tx);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions History'),
        backgroundColor: const Color(0xFF0000A0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ช่องค้นหาข้อมูล
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, item or date...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),

          // แถบหมวดหมู่
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterTab('All'),
                const SizedBox(width: 8),
                _buildFilterTab('Pending Refund'),
                const SizedBox(width: 8),
                _buildFilterTab('Collected'),
                const SizedBox(width: 8),
                _buildFilterTab('Refunded'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // รายการธุรกรรม (เรียงจากล่างขึ้นบน ให้รายการล่าสุดอยู่บนสุด)
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text('No transactions found',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tx = filteredList[filteredList.length - 1 - index];
                      
                      final bool isIncome = tx['isIncome'] == true;
                      final bool isPending = tx['isPending'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            tx['title']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Name : ${tx['user'] ?? ''} | ${tx['time'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          trailing: isPending
                              ? ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Refund processed for ${tx['user']}!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 30),
                                  ),
                                  child: const Text('Refund',
                                      style: TextStyle(fontSize: 11)),
                                )
                              : Text(
                                  tx['amount']?.toString() ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? Colors.green
                                          : Colors.red),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String category) {
    bool isSelected = selectedFilter == category;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0000A0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? const Color(0xFF0000A0) : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}