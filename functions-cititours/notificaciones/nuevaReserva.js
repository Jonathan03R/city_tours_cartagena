const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { Timestamp } = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const formatFecha = require("../utils/formatFecha");

const logoUrl = "https://res.cloudinary.com/dtjscibjc/image/upload/v1753754305/ysfcjrmtahtsanfxonn7.jpg";

exports.onNuevaReserva = onDocumentCreated("reservas/{reservaId}", async (event) => {
  const reservaId = event.params.reservaId;
  const newReserva = event.data.data();

  const nombreCliente = newReserva.nombreCliente || "Cliente";
  const pax = newReserva.pax || 1;
  const turno = newReserva.turno || "turno";

  const fechaReserva = newReserva.fechaReserva instanceof Timestamp
    ? formatFecha(newReserva.fechaReserva)
    : "sin fecha";

  console.log("▶️ Nueva reserva detectada:", reservaId, newReserva);

  const message = {
    topic: "pruebas",
    notification: {
      title: `🎉 ¡Nueva reserva!`,
      body: `Cliente: ${nombreCliente} (${pax} pax, ${turno}, ${fechaReserva})`,
      image: logoUrl,
    },
    android: {
      notification: {
        sound: "default",
        imageUrl: logoUrl,
        title: `🎉 ¡Nueva reserva!`,
        body: `Cliente: ${nombreCliente} (${pax} pax, ${turno}, ${fechaReserva})`,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: `🎉 ¡Nueva reserva!`,
            body: `Cliente: ${nombreCliente} (${pax} pax, ${turno}, ${fechaReserva})`,
          },
          sound: "default",
          badge: 1,
          "mutable-content": 1,
        },
      },
      fcm_options: {
        image: logoUrl,
      },
    },
    webpush: {
      headers: {
        Urgency: "high",
      },
    },
    data: {
      reservaId,
      screen: "reservas",
      nombreCliente,
      turno,
      fechaReserva,
      pax: pax.toString(),
    },
    fcmOptions: {
      analyticsLabel: "nueva_reserva",
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ Notificación enviada a topic 'nuevas-reservas'`, response);
    return response;
  } catch (err) {
    console.error("❌ Error enviando notificación:", err);
    throw err;
  }
});
