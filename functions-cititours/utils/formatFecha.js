module.exports = function formatFecha(fecha) {
  const date = fecha.toDate();
  return date.toLocaleDateString("es-PE", {
    weekday: "short",
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};
