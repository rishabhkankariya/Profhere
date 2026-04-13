const {setGlobalOptions} = require("firebase-functions");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

setGlobalOptions({maxInstances: 10, region: "asia-south1"});

/**
 * Triggered when a faculty document is updated.
 * Sends a push notification to students subscribed to 'faculty_{id}'
 * when the faculty status changes to 'available'.
 */
exports.onFacultyStatusUpdate = onDocumentUpdated(
    "faculty/{facultyId}",
    async (event) => {
      const newValue = event.data.after.data();
      const previousValue = event.data.before.data();
      const facultyId = event.params.facultyId;

      logger.info(`Status update for faculty ${facultyId}: ` +
          `${previousValue.status} -> ${newValue.status}`);

      if (newValue.status === "available" &&
          previousValue.status !== "available") {
        const message = {
          notification: {
            title: "Faculty Available! 🔔",
            body: `${newValue.name} is now available in ` +
                `Cabin ${newValue.cabin_id || "N/A"}.`,
          },
          android: {
            notification: {
              channel_id: "faculty_updates",
              priority: "high",
            },
          },
          topic: `faculty_${facultyId}`,
        };

        try {
          await admin.messaging().send(message);
          logger.info(`Successfully sent notification for: ${newValue.name}`);
        } catch (error) {
          logger.error("Error sending notification:", error);
        }
      }
      return null;
    });
