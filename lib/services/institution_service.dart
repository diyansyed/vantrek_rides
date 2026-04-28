import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/institution_model_new.dart';

class InstitutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register driver at an institution
  Future<void> registerAtInstitution({
    required String institutionId,
    required String institutionName,
    required double institutionLatitude,
    required double institutionLongitude,
    required String placeId,
    required List<String> route,
    List<String>? pickupTimes,   // NEW
    List<String>? dropoffTimes,  // NEW
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    print('═══════════════════════════════════════');
    print('REGISTERING DRIVER AT INSTITUTION');
    print('Institution: $institutionName');
    print('Driver ID: ${user.uid}');

    // Get driver profile
    final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
    if (!driverDoc.exists) {
      throw Exception('Driver profile not found');
    }

    final driverData = driverDoc.data()!;

    // AUTO-FIX: Get driver name from multiple sources with smart fallback
    String driverName = driverData['name'] ??
        driverData['fullName'] ??
        driverData['driverName'] ??
        user.displayName ??
        '';

    // If still empty, try to get from users collection
    if (driverName.isEmpty) {
      print('⚠️  Driver name empty, checking users collection...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        driverName = userDoc.data()?['name'] ?? 'Driver';
      } else {
        driverName = 'Driver';
      }
    }

    String phoneNumber = driverData['phoneNumber'] ??
        driverData['phone'] ??
        user.phoneNumber ??
        '';

    // If still empty, try users collection
    if (phoneNumber.isEmpty) {
      print('⚠️  Phone number empty, checking users collection...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        phoneNumber = userDoc.data()?['phoneNumber'] ?? '';
      }
    }

    print('Driver Name: $driverName');
    print('Phone Number: $phoneNumber');

    // AUTO-FIX: Update driver document if name or phone was missing
    bool needsUpdate = false;
    Map<String, dynamic> driverUpdates = {};

    if (driverData['name'] == null || (driverData['name'] as String).isEmpty) {
      driverUpdates['name'] = driverName;
      needsUpdate = true;
      print('✅ Will update driver document with name');
    }

    if (driverData['phoneNumber'] == null || (driverData['phoneNumber'] as String).isEmpty) {
      driverUpdates['phoneNumber'] = phoneNumber;
      needsUpdate = true;
      print('✅ Will update driver document with phone');
    }

    if (needsUpdate) {
      await _firestore.collection('drivers').doc(user.uid).update(driverUpdates);
      print('✅ Driver document updated automatically');
    }

    // Create institution document if it doesn't exist
    final institutionRef = _firestore.collection('institutions').doc(institutionId);
    final institutionDoc = await institutionRef.get();

    if (!institutionDoc.exists) {
      await institutionRef.set({
        'name': institutionName,
        'latitude': institutionLatitude,
        'longitude': institutionLongitude,
        'placeId': placeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Institution document created');
    } else {
      print('✅ Institution already exists');
    }

    // Add driver to institution's drivers subcollection
    final driverInfo = {
      'driverId': user.uid,
      'name': driverName,
      'phoneNumber': phoneNumber,
      'vehicleType': driverData['vehicleType'] ?? 'Car',
      'vehicleNumber': driverData['vehicleNumber'] ?? '',
      'route': route,
      'pickupTimes': pickupTimes ?? [],
      'dropoffTimes': dropoffTimes ?? [],
      'isOnline': false,
      'rating': driverData['rating'] ?? 0.0,
      'totalRides': driverData['totalRides'] ?? 0,
      'registeredAt': FieldValue.serverTimestamp(),
    };

    await institutionRef.collection('drivers').doc(user.uid).set(driverInfo);
    print('✅ Driver added to institution drivers collection');
    print('   Path: institutions/$institutionId/drivers/${user.uid}');

    // Add institution to driver's registered institutions
    await _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .doc(institutionId)
        .set({
      'institutionId': institutionId,
      'institutionName': institutionName,
      'placeId': placeId,
      'route': route,
      'pickupTimes': pickupTimes ?? [],
      'dropoffTimes': dropoffTimes ?? [],
      'registeredAt': FieldValue.serverTimestamp(),
    });

    print('✅ Institution added to driver registered institutions');
    print('═══════════════════════════════════════');
  }

  // Update driver's route at an institution
  Future<void> updateRouteAtInstitution({
    required String institutionId,
    required List<String> route,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update route in institution's drivers subcollection
    await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .doc(user.uid)
        .update({'route': route});

    // Update route in driver's registered institutions
    await _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .doc(institutionId)
        .update({'route': route});
  }

  // Update driver's pickup times at an institution
  Future<void> updatePickupTimesAtInstitution({
    required String institutionId,
    required List<String> pickupTimes,
    required List<String> dropoffTimes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update times in institution's drivers subcollection
    await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .doc(user.uid)
        .update({
      'pickupTimes': pickupTimes,
      'dropoffTimes': dropoffTimes,
    });

    // Update times in driver's registered institutions
    await _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .doc(institutionId)
        .update({
      'pickupTimes': pickupTimes,
      'dropoffTimes': dropoffTimes,
    });
  }

  // Get drivers at an institution
  Future<List<InstitutionDriver>> getDriversAtInstitution(
      String institutionId) async {
    print('═══════════════════════════════════════');
    print('GETTING DRIVERS AT INSTITUTION');
    print('Institution ID: $institutionId');

    final snapshot = await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .get();

    print('Found ${snapshot.docs.length} drivers');

    for (var doc in snapshot.docs) {
      print('  - Driver: ${doc.data()['name']} (ID: ${doc.id})');
    }

    print('═══════════════════════════════════════');

    return snapshot.docs
        .map((doc) => InstitutionDriver.fromMap(doc.data()))
        .toList();
  }

  // Get driver's registered institutions
  Stream<List<Map<String, dynamic>>> getDriverRegisteredInstitutions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Unregister from institution
  Future<void> unregisterFromInstitution(String institutionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Remove from institution's drivers
    await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .doc(user.uid)
        .delete();

    // Remove from driver's registered institutions
    await _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .doc(institutionId)
        .delete();
  }

  // Update driver's online status at institution
  Future<void> updateOnlineStatus({
    required String institutionId,
    required bool isOnline,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .doc(user.uid)
        .update({'isOnline': isOnline});
  }

  // Get institution details
  Future<Map<String, dynamic>?> getInstitutionDetails(
      String institutionId) async {
    final doc =
    await _firestore.collection('institutions').doc(institutionId).get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  // Search institutions by name
  Future<List<Map<String, dynamic>>> searchInstitutions(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('institutions')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  // Check if driver is registered at institution
  Future<bool> isRegisteredAtInstitution(String institutionId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('drivers')
        .doc(user.uid)
        .collection('registeredInstitutions')
        .doc(institutionId)
        .get();

    return doc.exists;
  }

  // Get driver count at institution
  Future<int> getDriverCountAtInstitution(String institutionId) async {
    final snapshot = await _firestore
        .collection('institutions')
        .doc(institutionId)
        .collection('drivers')
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}