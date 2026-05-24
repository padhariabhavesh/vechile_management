import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_management/features/petrol_tracking/domain/entities/petrol_log.dart';
import 'package:vehicle_management/features/petrol_tracking/domain/utils/fuel_economy_calculator.dart';
import 'package:vehicle_management/features/service_tracking/domain/utils/service_reminder_engine.dart';
import 'package:vehicle_management/features/vehicle_management/domain/entities/vehicle.dart';
import 'package:vehicle_management/features/vehicle_management/domain/entities/fuel_type.dart';

import 'package:vehicle_management/features/vehicle_management/domain/services/odometer_processor.dart';
import 'package:vehicle_management/features/vehicle_management/domain/repositories/vehicle_repository.dart';
import 'package:vehicle_management/core/database/local_db_simulator.dart';

// Mock repository implementation for odometer test
class MockVehicleRepository implements VehicleRepository {
  Vehicle? lastSavedVehicle;

  @override
  Future<List<Vehicle>> getVehiclesForUser(String userId) async => [];
  
  @override
  Future<Vehicle?> getVehicleById(String vehicleId) async => null;

  @override
  Future<void> saveVehicle(Vehicle vehicle) async {
    lastSavedVehicle = vehicle;
  }

  @override
  Future<void> updateOdometer(String vehicleId, double newOdometer) async {}
}

void main() {
  group('FuelEconomyCalculator Tests', () {
    test('Should calculate mileage successfully on back-to-back full tank logs', () {
      final prev = PetrolLog(
        id: '1',
        vehicleId: 'car-1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        odometerReading: 10000.0,
        liters: 40.0,
        costPerLiter: 3.5,
        totalCost: 140.0,
        isFullTank: true,
      );

      final curr = PetrolLog(
        id: '2',
        vehicleId: 'car-1',
        date: DateTime.now(),
        odometerReading: 10400.0,
        liters: 32.0,
        costPerLiter: 3.5,
        totalCost: 112.0,
        isFullTank: true,
      );

      final result = FuelEconomyCalculator.calculate(currentLog: curr, previousLog: prev);

      expect(result.isSuccess, true);
      // Mileage = (10400 - 10000) / 32 = 400 / 32 = 12.5 km/L
      expect(result.mileage, 12.5);
      expect(result.displayMessage, '12.50 km/L');
    });

    test('Should return pending status if current fill is not a full tank', () {
      final prev = PetrolLog(
        id: '1',
        vehicleId: 'car-1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        odometerReading: 10000.0,
        liters: 40.0,
        costPerLiter: 3.5,
        totalCost: 140.0,
        isFullTank: true,
      );

      final curr = PetrolLog(
        id: '2',
        vehicleId: 'car-1',
        date: DateTime.now(),
        odometerReading: 10400.0,
        liters: 32.0,
        costPerLiter: 3.5,
        totalCost: 112.0,
        isFullTank: false, // Partial fill
      );

      final result = FuelEconomyCalculator.calculate(currentLog: curr, previousLog: prev);

      expect(result.isSuccess, false);
      expect(result.status, CalculationStatus.pendingNextFullTank);
      expect(result.displayMessage, 'Pending Next Full Tank');
    });

    test('Should return pending status if previous fill was not a full tank', () {
      final prev = PetrolLog(
        id: '1',
        vehicleId: 'car-1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        odometerReading: 10000.0,
        liters: 40.0,
        costPerLiter: 3.5,
        totalCost: 140.0,
        isFullTank: false, // Partial fill in previous
      );

      final curr = PetrolLog(
        id: '2',
        vehicleId: 'car-1',
        date: DateTime.now(),
        odometerReading: 10400.0,
        liters: 32.0,
        costPerLiter: 3.5,
        totalCost: 112.0,
        isFullTank: true,
      );

      final result = FuelEconomyCalculator.calculate(currentLog: curr, previousLog: prev);

      expect(result.isSuccess, false);
      expect(result.status, CalculationStatus.pendingNextFullTank);
    });
  });

  group('ServiceReminderEngine Tests', () {
    test('Should flag OK state when remaining distance is above 200 km', () {
      final status = ServiceReminderEngine.calculateStatus(
        nextServiceTrigger: 15000.0,
        currentOdometer: 14000.0,
      );

      expect(status.severity, AlertSeverity.ok);
      expect(status.remainingDistance, 1000.0);
    });

    test('Should flag WARNING state when remaining distance is <= 200 km but > 0', () {
      final status = ServiceReminderEngine.calculateStatus(
        nextServiceTrigger: 15000.0,
        currentOdometer: 14850.0,
      );

      expect(status.severity, AlertSeverity.warning);
      expect(status.remainingDistance, 150.0);
      expect(status.message.contains('Service due soon'), true);
    });

    test('Should flag OVERDUE state when remaining distance is <= 0', () {
      final status = ServiceReminderEngine.calculateStatus(
        nextServiceTrigger: 15000.0,
        currentOdometer: 15120.0,
      );

      expect(status.severity, AlertSeverity.overdue);
      expect(status.remainingDistance, -120.0);
      expect(status.message.contains('Overdue'), true);
    });
  });


  group('OdometerProcessor Tests', () {
    test('Should trigger update if log odometer is higher than master odometer', () async {
      final vehicle = Vehicle(
        id: 'car-1',
        userId: 'user-1',
        name: 'Sedan',
        model: 'Camry',
        registrationNumber: 'XYZ-123',
        initialOdometer: 5000.0,
        currentOdometer: 6200.0,
        fuelType: FuelType.petrol,
      );

      final repo = MockVehicleRepository();
      final updated = await OdometerProcessor.processOdometerUpdate(
        vehicle: vehicle,
        logOdometer: 6500.0,
        vehicleRepository: repo,
      );

      expect(updated, true);
      expect(repo.lastSavedVehicle?.currentOdometer, 6500.0);
    });

    test('Should not trigger update if log odometer is lower or equal', () async {
      final vehicle = Vehicle(
        id: 'car-1',
        userId: 'user-1',
        name: 'Sedan',
        model: 'Camry',
        registrationNumber: 'XYZ-123',
        initialOdometer: 5000.0,
        currentOdometer: 6200.0,
        fuelType: FuelType.petrol,
      );

      final repo = MockVehicleRepository();
      final updated = await OdometerProcessor.processOdometerUpdate(
        vehicle: vehicle,
        logOdometer: 6000.0,
        vehicleRepository: repo,
      );

      expect(updated, false);
      expect(repo.lastSavedVehicle, null);
    });
  });

  group('Authentication & Onboarding Tests', () {
    test('Should successfully login seeded user with correct credentials', () async {
      final db = LocalDbSimulator.instance;
      final user = await db.loginUser(username: 'sarah', password: 'sarah123');

      expect(user, isNotNull);
      expect(user?.name, 'Sarah Jenkins');
      expect(user?.username, 'sarah');
    });

    test('Should return null for login with invalid credentials', () async {
      final db = LocalDbSimulator.instance;
      final user = await db.loginUser(username: 'sarah', password: 'wrongpassword');

      expect(user, isNull);
    });

    test('Should successfully register a new user with unique username', () async {
      final db = LocalDbSimulator.instance;
      final uniqueUsername = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
      final user = await db.registerUser(
        username: uniqueUsername,
        fullName: 'Test User',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user?.username, uniqueUsername);
      expect(user?.name, 'Test User');
      expect(user?.password, 'password123');
    });

    test('Should reject registration with an existing username', () async {
      final db = LocalDbSimulator.instance;
      // 'sarah' username already exists in seeded data
      final user = await db.registerUser(
        username: 'sarah',
        fullName: 'Sarah Alternate',
        password: 'password999',
      );

      expect(user, isNull);
    });
  });
}
