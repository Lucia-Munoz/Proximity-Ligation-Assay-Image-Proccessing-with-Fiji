// AnalyzeParticles_Summarize.ijm
//
// Flujo:
//   1) Detecta todas las particulas de la imagen abierta con Analyze Particles.
//   2) Genera un resumen (en la tabla "Summary") con el recuento total y según las medidas promedio/totales configuradas en Set Measurements
//      (area, area total, tamano medio, %area, etc.).
//
// Uso:
//   1. Abre las imágenes que quieras anañizar.
//   2. (Opcional) Ajusta que medidas quieres en Analyze > Set Measurements...
//   3. Ejecuta esta macro.
//   4. Revisa la tabla "Summary"
//
// Nota: al no incluir "size=..." ni "circularity=...", se cuentan TODAS
// las particulas detectadas, sin filtrar por tamano ni forma.
// clear       -> vacia la tabla de Resultados antes de empezar
// summarize   -> en vez de (o ademas de) los resultados por particula,
//                anade una fila de resumen a la tabla "Summary"
// composite   -> evita problemas con particulas que tengan agujeros o
//                formas compuestas
run("Analyze Particles...", "clear summarize composite");
