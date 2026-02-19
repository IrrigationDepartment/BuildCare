import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;

    final issues = await firestore.collection('issues').get();
    for (var doc in issues.docs) {
      final data = doc.data();
      Timestamp? ts = data['lastUpdatedTimestamp'] ?? data['timestamp'];
      if (ts == null) continue;

      DateTime addedDate = ts.toDate();
      int diffInMonths = (now.year - addedDate.year) * 12 + now.month - addedDate.month;

      if (diffInMonths >= 6) {
        // AUTO DELETE
        await firestore.collection('notifications').add({
          'title': "Issue Expired",
          'subtitle': "Issue '${data['issueTitle']}' was deleted automatically.",
          'type': 'issue_deleted',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'addedByNic': data['addedByNic'],
        });
        await doc.reference.delete();
      } else if (diffInMonths >= 5 && data['expiryWarningSent'] != true) {
        // EXPIRE SOON
        await firestore.collection('notifications').add({
          'title': "Expiring Soon",
          'subtitle': "Issue '${data['issueTitle']}' will expire in 1 month.",
          'type': 'issue',
          'issueId': doc.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'addedByNic': data['addedByNic'],
        });
        await doc.reference.update({'expiryWarningSent': true});
      }
    }
    return Future.value(true);
  });
}