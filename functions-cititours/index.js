const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp({});
setGlobalOptions({ maxInstances: 10 });

// 📦 Importa y exporta funciones
exports.sendNewReservaNotification = require("./notificaciones/nuevaReserva").onNuevaReserva;
