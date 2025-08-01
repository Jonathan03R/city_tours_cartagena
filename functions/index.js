// functions/index.js

// 1) SDK de Admin para acceder a Firestore y FCM
const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "citytourscartagena", // 👈 Asegúrate que esté bien escrito
});

// 2) Triggers y logger modular de Functions v2
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

/**
 * sendNewReservaNotification
 * Se dispara cuando se crea un documento en /reservas/{reservaId}
 */
exports.sendNewReservaNotification = onDocumentCreated(
    "reservas/{reservaId}",
    async (event) => {
    // Datos de la reserva recién creada
      const reservaId = event.params.reservaId;
      const newReserva = event.data.data();

      console.log("▶️ Nueva reserva detectada:", reservaId, newReserva);

      try {
      // Envía la notificación al topic "nuevas-reservas"
        const message = {
          notification: {
            title: "🎉 ¡Nueva Reserva!",
            body: `Reserva de ${newReserva.nombreCliente}`,
          },
          android: {
            notification: {
              sound: "default", // ✅ sonido solo para Android
            },
          },
          data: {
            reservaId,
            screen: "reservas",
          },
          topic: "nuevas-reservas",
        };


        const response = await admin.messaging().send(message);

        // eslint-disable-next-line max-len
        console.log(`✅ Notificación enviada a topic 'nuevas-reservas'`, response);
        return response;
      } catch (err) {
        console.error("❌ Error enviando notificación:", err);
        throw err;
      }
    },
);
