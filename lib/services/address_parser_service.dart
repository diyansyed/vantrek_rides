// /// Service to extract area/sector from address - FULLY DYNAMIC
// class AddressParserService {
//   /// Extract area code from address dynamically
//   /// Works with ANY sector format without hardcoded lists
//   /// Example: "Street 12 House 20 G-11/3" → "G-11"
//   static String? extractAreaCode(String address) {
//     if (address.isEmpty) return null;
//
//     final upperAddress = address.toUpperCase();
//     print('🔍 Parsing address: "$address"');
//     print('🔍 Uppercase: "$upperAddress"');
//
//     // Pattern 1: Sector with dash: G-11/3, F-7, I-8/4, E-11
//     // Matches: Any letter + dash + numbers (+ optional /numbers)
//     final withDashPattern = RegExp(r'\b([A-Z]-\d+)(?:/\d+)?\b');
//     final withDashMatch = withDashPattern.firstMatch(upperAddress);
//     if (withDashMatch != null) {
//       final result = withDashMatch.group(1)!;
//       print('✅ Found sector with dash: "$result"');
//       return result;
//     }
//
//     // Pattern 2: Sector without dash but with slash: G7/3, F10/2
//     // Matches: Letter + numbers + slash + numbers
//     final withSlashPattern = RegExp(r'\b([A-Z])(\d+)/\d+\b');
//     final withSlashMatch = withSlashPattern.firstMatch(upperAddress);
//     if (withSlashMatch != null) {
//       final letter = withSlashMatch.group(1)!;
//       final number = withSlashMatch.group(2)!;
//       final result = '$letter-$number';
//       print('✅ Found sector with slash (added dash): "$result"');
//       return result;
//     }
//
//     // Pattern 3: Sector without dash or slash: G11, F7, I8
//     // Matches: Single letter + numbers
//     final noDashPattern = RegExp(r'\b([A-Z])(\d+)\b');
//     final noDashMatch = noDashPattern.firstMatch(upperAddress);
//     if (noDashMatch != null) {
//       final letter = noDashMatch.group(1)!;
//       final number = noDashMatch.group(2)!;
//       final result = '$letter-$number';
//       print('✅ Found sector without dash (added dash): "$result"');
//       return result;
//     }
//
//     print('❌ No sector pattern found in address');
//     return null;
//   }
//
//   /// Check if driver routes contain the user's area
//   /// Uses case-insensitive matching
//   static bool driverServesArea(List<String> driverRoutes, String? userArea) {
//     if (userArea == null || userArea.isEmpty) return true;
//     if (driverRoutes.isEmpty) return false;
//
//     final userAreaUpper = userArea.toUpperCase();
//
//     for (var route in driverRoutes) {
//       final routeUpper = route.toUpperCase();
//
//       // Exact match
//       if (routeUpper == userAreaUpper) {
//         return true;
//       }
//
//       // Normalized match (remove dash and compare)
//       final routeNormalized = routeUpper.replaceAll('-', '');
//       final userNormalized = userAreaUpper.replaceAll('-', '');
//       if (routeNormalized == userNormalized) {
//         return true;
//       }
//     }
//
//     return false;
//   }
//
//   /// Extract multiple possible area codes from address
//   /// For more flexible matching
//   static List<String> extractAllAreaCodes(String address) {
//     final codes = <String>[];
//
//     final mainCode = extractAreaCode(address);
//     if (mainCode != null) {
//       codes.add(mainCode);
//
//       // Also add nearby sectors (optional for better matching)
//       // Example: G-11 → also match G-10, G-12
//       // This can be enabled if you want more flexible matching
//     }
//
//     return codes;
//   }
//
//   /// Check if address matches any of the driver's routes
//   static bool addressMatchesRoutes(
//       String userAddress,
//       List<String> driverRoutes,
//       ) {
//     final userAreaCode = extractAreaCode(userAddress);
//     if (userAreaCode == null) return false;
//
//     // Check if driver serves this area
//     for (var route in driverRoutes) {
//       if (route.toUpperCase() == userAreaCode.toUpperCase()) {
//         return true;
//       }
//
//       // Also match if driver route contains the area
//       // Example: Driver route "G-11" matches "G-11/3"
//       if (userAreaCode.toUpperCase().contains(route.toUpperCase())) {
//         return true;
//       }
//     }
//
//     return false;
//   }
//
//   /// Get human-readable area name
//   static String getAreaDisplayName(String areaCode) {
//     switch (areaCode.toUpperCase()) {
//       case 'BLUE AREA':
//         return 'Blue Area';
//       case 'BAHRIA TOWN':
//         return 'Bahria Town';
//       case 'DHA':
//         return 'DHA';
//       case 'SADDAR':
//         return 'Saddar';
//       case 'SATELLITE TOWN':
//         return 'Satellite Town';
//       default:
//         return areaCode;
//     }
//   }
// }