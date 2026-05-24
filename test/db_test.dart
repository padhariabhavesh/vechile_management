import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  print('Connecting to MongoDB Atlas...');
  final connectionString =
      'mongodb+srv://vechile_management:vehicle@cluster.92ecnxr.mongodb.net/?appName=Cluster';

  try {
    final db = await Db.create(connectionString);
    await db.open();
    print('✅ Connected successfully!\n');

    final col = db.collection('petrol_logs');

    // 1. Total logs
    final total = await col.count();
    print('Total fuel logs in database: $total\n');

    // 2. Search by liters = 4.0
    print('--- Searching by liters = 4.0 ---');
    final byLiters = await col.find(where.eq('liters', 4.0)).toList();
    if (byLiters.isNotEmpty) {
      print('✅ FOUND ${byLiters.length} log(s) with 4.0 liters:');
      for (var log in byLiters) {
        print('  → ID: ${log['id']}');
        print('     Odometer  : ${log['odometerReading']} km');
        print('     Liters    : ${log['liters']} L');
        print('     Cost/L    : ₹${log['costPerLiter']}');
        print('     Total     : ₹${log['totalCost']}');
        print('     Date      : ${log['date']}');
      }
    } else {
      print('❌ No log found with 4.0 liters.\n');
    }

    // 3. Search by totalCost around 443
    print('\n--- Searching by totalCost between 400 and 500 ---');
    final byCost = await col
        .find(where.gt('totalCost', 400).lt('totalCost', 500))
        .toList();
    if (byCost.isNotEmpty) {
      print('✅ FOUND ${byCost.length} log(s) with cost between ₹400-500:');
      for (var log in byCost) {
        print('  → ID: ${log['id']}  | ${log['liters']}L | ₹${log['totalCost']}');
      }
    } else {
      print('❌ No logs found with cost between ₹400-500.');
    }

    // 4. Show ALL logs to see what's actually stored
    print('\n--- ALL ${total} logs in petrol_logs collection ---');
    final all = await col.find().toList();
    for (var log in all) {
      print('  Odo: ${log['odometerReading']} km | '
          '${log['liters']}L | ₹${log['totalCost']} | '
          'VehicleId: ${log['vehicleId']} | '
          'Date: ${log['date']}');
    }

    await db.close();
    print('\n\nDIAGNOSIS:');
    if (total == 24) {
      print('⚠️  Only the 24 seeded mock logs exist.');
      print('   The fuel refill you added was saved in APP MEMORY only,');
      print('   but did NOT sync to MongoDB. This means the database');
      print('   connection was NOT active when you added the entry.');
    }
    print('\nConnection closed.');
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
