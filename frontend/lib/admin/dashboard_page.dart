import 'package:flutter/material.dart';

void main() {
  runApp(const BorrowAdminApp());
}

class BorrowAdminApp extends StatelessWidget {
  const BorrowAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Roboto',
      ),
      home: const AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 768;

          return Row(
            children: [
              // Sidebar (แถบเมนูด้านซ้าย)
            //  if (!isSmallScreen)
               // Container(
                 // width: 260,
                  // color: const Color(0xFF0000A0),
                //  padding: const EdgeInsets.all(20.0),
                // child: Column(
                  //  crossAxisAlignment: CrossAxisAlignment.start,
                  //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //children: [
                    //  Column(
                       // crossAxisAlignment: CrossAxisAlignment.start,
                       // children: [
                         // Row(
                          //  children: [
                            //  Container(
                             //   width: 44,
                              //  height: 44,
                              //  decoration: BoxDecoration(
                                //  color: Colors.white,
                              //    borderRadius: BorderRadius.circular(12),
                             //   ),
                               // alignment: Alignment.center,
                             // child: const Text(
                                 // 'B',
                                //  style: TextStyle(
                                   // fontSize: 22,
                                  //  fontWeight: FontWeight.bold,
                                 //   color: Color(0xFF0000A0),
                                //  ),
                              //  ),
                            //  ),
                          //    const SizedBox(width: 12),
                             // Column(
                              //  crossAxisAlignment: CrossAxisAlignment.start,
                              //  children: const [
                                 // Text(
                                   // 'Borrow',
                                  //  style: TextStyle(
                                   //   color: Colors.white,
                                   //   fontSize: 18,
                                    //  fontWeight: FontWeight.bold,
                                   // ),
                                 // ),
                                //  Text(
                                 //   'Admin',
                                  //  style: TextStyle(
                                 //    color: Colors.white70,
                                  //    fontSize: 13,
                                //    ),
                                //  ),
                              //  ],
                            //  ),
                          //  ],
                        //  ),
                         // const SizedBox(height: 30),
                         // _buildNavItem('Dashboard', isSelected: true),
                        //  const SizedBox(height: 8),
                          //_buildNavItem('Approve Items', badgeCount: '3'),
                         // const SizedBox(height: 8),
                          //_buildNavItem('Users & History'),
                        //  const SizedBox(height: 8),
                        //  _buildNavItem('All borrowing Records'),
                      //  ],
                    //  ),
                     // SizedBox(
                      //  width: double.infinity,
                      //  height: 44,
                      //  child: ElevatedButton(
                         // onPressed: () {},
                        //  style: ElevatedButton.styleFrom(
                          //  backgroundColor: const Color(0xFF0047AB),
                           // shape: RoundedRectangleBorder(
                          //    borderRadius: BorderRadius.circular(10),
                         //   ),
                           // elevation: 0,
                         // ),
                         // child: const Text(
                           // 'Logout',
                           // style: TextStyle(
                            //  color: Colors.white,
                            //  fontWeight: FontWeight.bold,
                           // ),
                         // ),
                       // ),
                     // ),
                   // ],
                 // ),
               // ),

              // Main Content (เนื้อหาหลักด้านขวา)
              Expanded(
                child: Scaffold(
                  appBar: isSmallScreen
                      ? AppBar(
                          backgroundColor: const Color(0xFF0000A0),
                          title: const Text('Borrow Admin'),
                        )
                      : null,
                  drawer: isSmallScreen
                      ? Drawer(
                          backgroundColor: const Color(0xFF0000A0),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Menu',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20)),
                                const SizedBox(height: 20),
                                _buildNavItem('Dashboard', isSelected: true),
                                _buildNavItem('Approve Items', badgeCount: '3'),
                                _buildNavItem('Users & History'),
                                _buildNavItem('All borrowing Records'),
                              ],
                            ),
                          ),
                        )
                      : null,
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Top 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Friday , October 30, 2026',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stat Cards Grid
                        LayoutBuilder(
                          builder: (context, cardConstraints) {
                            int crossAxisCount = cardConstraints.maxWidth > 900
                                ? 4
                                : (cardConstraints.maxWidth > 500 ? 2 : 1);
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.8,
                              children: [
                                _buildStatCard('Approved Items', '1248'),
                                _buildStatCard('Pending Approval', '3'),
                                _buildStatCard('Currently Borrowed', '96'),
                                _buildStatCard('Held Deposits', '฿84,500'),
                              ],
                              
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Lower Section: Chart Section 
                        _buildChartSection(),
                      ],
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

  // Widget เมนูด้านข้าง
  Widget _buildNavItem(String title,
      {bool isSelected = false, String? badgeCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF93C5FD),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badgeCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount,
                style: const TextStyle(
                  color: Color(0xFF030712),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget การ์ดสถิติ
  Widget _buildStatCard(String title, String value) {
    //return Container(

     return Card( 
      //decoration: BoxDecoration(
       elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side : const BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1
        ),
      ),
      
      child : Padding(
      padding : const EdgeInsets.all(16),
      
      //decoration: BoxDecoration(
       // color: Colors.white,
      //  borderRadius: BorderRadius.circular(14),
      //  border: Border.all(color: const Color(0xFFE5E7EB)),
      
       
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
     ),
     );
    
  }

  // Widget ส่วนกราฟ
  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Number of borrowing\nin the last 7 days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                'Times / day',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(30),
              _buildBar(50),
              _buildBar(60),
              _buildBar(70),
              _buildBar(90),
              _buildBar(40),
              _buildBar(75),
            ],
          ),
        ],
      ),
    );
  }

  // Widget แท่งกราฟ
  Widget _buildBar(double height) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0000A0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}