const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Admin SDK (This gives the code 'superpower' access)
admin.initializeApp();

// This is the function name we call from Flutter
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  
  // 1. Security Check: Ensure the person calling this is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can delete accounts."
    );
  }

  const uidToDelete = data.uid;

  try {
    // 2. Delete the user from Firebase Authentication (The Login)
    await admin.auth().deleteUser(uidToDelete);

    // 3. Delete the user's details from Firestore (The Database)
    await admin.firestore().collection("users").doc(uidToDelete).delete();

    return { success: true, message: "User deleted successfully." };
  } catch (error) {
    console.error("Error deleting user:", error);
    // If something goes wrong, tell the Flutter app
    return { success: false, error: error.message };
  }
});