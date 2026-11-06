
import 'package:flutter/material.dart';

class UsersHistoryPage extends StatefulWidget {
  const UsersHistoryPage({super.key});

  @override
  State<UsersHistoryPage> createState() => _UsersHistoryPageState();
}

class _UsersHistoryPageState extends State<UsersHistoryPage> {
  String filter = 'All';
  String search = '';

  final logs = [
    ['30 Oct. 11:12', 'Finance', 'Payment successful 245฿', 'User'],
    ['30 Oct. 11:10', 'Rental', 'Requested to rent Casio fx-991EX', 'User'],
    ['29 Oct. 16:08', 'Rental', 'Picked up Lab Coat Size M', 'User'],
    ['27 Oct. 14:30', 'Rental', 'Confirmed item return - Calculus Textbook Vol. 1', 'User'],
    ['1 Oct. 10:02', 'Account', 'Account rejected', 'Admin'],
    ['29 Oct. 20:17', 'Account', 'Account approved', 'Admin'],
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = logs.where((log) {
      final matchesFilter = filter == 'All' || log[1] == filter;
      final matchesSearch =
          log.join(' ').toLowerCase().contains(search.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Container(
      color: const Color(0xFFF0EEEE),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users & History',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('View activity logs for each user',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade400,
                    child: const Text('S',
                        style: TextStyle(fontSize: 25, color: Colors.black)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Somchai J.',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Approved by Admin Suphaphorn on Oct 1, 2026',
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  _stat('All Rental Records', '10'),
                  _stat('Lending', '6'),
                  _stat('Overdue', '1', warning: true),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Suspend Account'),
                          content: const Text(
                              'Are you sure you want to suspend this account?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text('Suspend Account'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Activity Log',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        ...['All', 'Account', 'Rental', 'Finance'].map(
                          (type) => ChoiceChip(
                            label: Text(type),
                            selected: filter == type,
                            onSelected: (_) =>
                                setState(() => filter = type),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              filter = 'All';
                              search = '';
                            });
                          },
                          child: const Text('Export Log'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(flex: 2, child: Text('Date / Time')),
                        Expanded(flex: 2, child: Text('Type')),
                        Expanded(flex: 4, child: Text('Details')),
                        Expanded(child: Text('Performed By')),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final log = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(log[0])),
                                Expanded(
                                  flex: 2,
                                  child: Text(log[1],
                                      style: TextStyle(
                                          color: log[1] == 'Finance'
                                              ? Colors.green
                                              : log[1] == 'Account'
                                                  ? Colors.blue
                                                  : Colors.orange)),
                                ),
                                Expanded(
                                    flex: 4,
                                    child: Text(log[2],
                                        style: const TextStyle(fontSize: 12))),
                                Expanded(child: Text(log[3])),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, {bool warning = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warning ? Colors.red.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  fontSize: 23, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
