// Cristae_macro.ijm
//
// Flujo:
//   1) Toma el perfil de intensidad a lo largo de una linea dibujada manualmente sobre la mitocondria.
//   2) Detecta los maximos locales (picos) de ese perfil, que corresponden a las crestas mitocondriales.
//   3) Genera una tabla de Resultados con la posicion e intensidad de cada pico, y la distancia al pico anterior (en pixeles y en unidades
//      calibradas de la imagen).
//   4) Anade una fila de resumen (media, desviacion estandar, min y max de las distancias) a una tabla aparte "Cristae Summary", pensada para
//      ir acumulando resultados de varias imagenes/lineas y exportarlos juntos.
//   5) Muestra un grafico del perfil de intensidad con los picos marcados en rojo, para verificar visualmente que la deteccion es correcta.
//
// Uso:
//   1. Dibuja una linea a lo largo de la mitocondria que quieras analizar (herramienta Line o Segmented Line).
//   2. Ejecuta esta macro.
//   3. Revisa la tabla "Results" (picos individuales), la tabla
//      "Cristae Summary" (resumen por imagen) y el grafico generado.

// ---- Comprobacion inicial: debe haber una linea dibujada ----
if (selectionType() == -1) {
    exit("Please draw a line along the mitochondrion first.");
}

// Tamano de pixel calibrado, para poder expresar distancias en unidades
// reales (p.ej. micras) ademas de en pixeles
getPixelSize(unit, pw, ph);

// ---- OBTENEMOS EL PERFIL DE INTENSIDAD A LO LARGO DE LA LINEA ----
profile = getProfile();
n = profile.length;

if (n < 3) {
    exit("Line too short.");
}

// ---- DETECTAMOS LOS MAXIMOS LOCALES (picos) DEL PERFIL ----
// Un punto es pico si es mayor que el anterior y mayor o igual que el
// siguiente (deteccion simple, sin suavizado ni umbral de prominencia)
peaks = newArray(0);
for (i = 1; i < n - 1; i++) {
    if (profile[i] > profile[i-1] && profile[i] >= profile[i+1]) {
        peaks = Array.concat(peaks, i);
    }
}

nPeaks = peaks.length;
if (nPeaks < 2) {
    exit("Fewer than 2 peaks detected.");
}

// ---- TABLA DE PICOS (Results) ----
run("Clear Results");
for (i = 0; i < nPeaks; i++) {
    setResult("Peak #", i, i + 1);
    setResult("Position (px)", i, peaks[i]);
    setResult("Position (" + unit + ")", i, peaks[i] * pw);
    setResult("Intensity", i, profile[peaks[i]]);
    if (i > 0) {
        distPx = peaks[i] - peaks[i-1];
        setResult("Distance to previous (px)", i, distPx);
        setResult("Distance to previous (" + unit + ")", i, distPx * pw);
    }
}
updateResults();

// ---- ESTADISTICAS RESUMEN DE LAS DISTANCIAS ENTRE PICOS ----
distances = newArray(nPeaks - 1);
for (i = 1; i < nPeaks; i++) {
    distances[i-1] = (peaks[i] - peaks[i-1]) * pw;
}
Array.getStatistics(distances, dMin, dMax, dMean, dStdDev);

// ---- TABLA RESUMEN (ventana aparte, facil de copiar a Excel) ----
// Se anade una fila nueva por cada ejecucion, acumulando resultados de
// distintas lineas/imagenes en la misma tabla
summaryTable = "Cristae Summary";
if (!isOpen(summaryTable)) {
    Table.create(summaryTable);
}
selectWindow(summaryTable);
row = Table.size;

Table.set("Image", row, getTitle());
Table.set("N Peaks", row, nPeaks);
Table.set("N Intervals", row, distances.length);
Table.set("Mean Distance (" + unit + ")", row, dMean);
Table.set("StdDev (" + unit + ")", row, dStdDev);
Table.set("Min Distance (" + unit + ")", row, dMin);
Table.set("Max Distance (" + unit + ")", row, dMax);
Table.update;

// ---- GRAFICO DEL PERFIL CON LOS PICOS MARCADOS ----
Plot.create("Cristae Profile with Detected Peaks", "Distance along line (px)", "Intensity");
xVals = newArray(n);
for (i = 0; i < n; i++) xVals[i] = i;
Plot.add("line", xVals, profile);

peakY = newArray(nPeaks);
peakX = newArray(nPeaks);
for (i = 0; i < nPeaks; i++) {
    peakX[i] = peaks[i];
    peakY[i] = profile[peaks[i]];
}
Plot.setColor("red");
Plot.add("circle", peakX, peakY);
Plot.setColor("black");
Plot.show();

print("Done. See Results table, Cristae Summary table, and plot.");

Plot.setColor("black");

Plot.show();

 

print("Done. See Results table, Cristae Summary table, and plot.");
