
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';

/// This function is registered as the background task callback.
/// It must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await _checkAndCleanIssues();
    return Future.value(true);
  });
}

/// Core logic: check issues and perform cleanup/notification.
Future<void> _checkAndCleanIssues() async {
  final now = DateTime.now().toUtc();
  final fourMonthsAgo = now.subtract(const Duration(days: 120)); // approx 4 months
  final sixMonthsAgo = now.subtract(const Duration(days: 180));

  final issuesSnapshot = await FirebaseFirestore.instance
      .collection('issues')
      .get();

  for (var doc in issuesSnapshot.docs) {
    final data = doc.data();

    // Determine the most relevant date: lastUpdatedTimestamp > timestamp > dateOfOccurrence
    DateTime? issueDate;
    if (data['lastUpdatedTimestamp'] != null) {
      issueDate = (data['lastUpdatedTimestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] != null) {
      issueDate = (data['timestamp'] as Timestamp).toDate();
    } else if (data['dateOfOccurrence'] != null) {
      issueDate = (data['dateOfOccurrence'] as Timestamp).toDate();
    }

    if (issueDate == null) continue;

    // 6 months deletion
    if (issueDate.isBefore(sixMonthsAgo)) {
      await doc.reference.delete();
      // Optional: also delete related notifications? (skipped for simplicity)
      continue; // no need to check 4‑month alert for a deleted issue
    }

    // 4 months alert
    if (issueDate.isBefore(fourMonthsAgo)) {
      final bool alertAlreadySent = data['fourMonthAlertSent'] == true;
      if (!alertAlreadySent) {
        // Create a notification document
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'issue',
          'issueId': doc.id,
          'addedByNic': data['addedByNic'] ?? '',
          'schoolId': data['schoolId'] ?? '',
          'title': 'Issue Aging Alert',
          'subtitle': 'Issue "${data['issueTitle'] ?? 'Unknown'}" is over 4 months old.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Mark that we've sent the alert for this issue
        await doc.reference.update({'fourMonthAlertSent': true});
      }
    }
  }
}