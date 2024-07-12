const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const serviceAccount = require("./path-to-your-service-account-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();
const messaging = admin.messaging();

exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});

exports.saveFCMToken = onRequest(async (request, response) => {
  const { uid, token } = request.body;

  try {
    await firestore.collection('users').doc(uid).update({
      fcm_token: token,
    });
    response.json({ success: true });
  } catch (error) {
    response.status(500).json({ error: 'Failed to save FCM token.' });
  }
});

exports.sendNotification = firestore.document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();

    const payload = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
    };

    try {
      const usersSnapshot = await firestore.collection('users').get();
      const tokens = usersSnapshot.docs.map(doc => doc.data().fcm_token);

      const response = await messaging.sendToDevice(tokens, payload);
      console.log('Notifications sent successfully:', response);
    } catch (error) {
      console.error('Error sending notifications:', error);
    }
  });
