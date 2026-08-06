// CytosolMask_to_MitosPerCell.ijm
//
// Para cada mascara de citosol por celula (carpeta "citosol per cell 8bit",
// formato limpio C3_MAX_<resto>-<N>.tif), selecciona el area no vacia de
// esa mascara y la aplica sobre la imagen COMPLETA de mitocondrias
// correspondiente (carpeta "mitos thresholded", formato limpio
// C2_MAX_<resto>.tif thresholded.tif), recortando (Clear Outside) y
// guardando el resultado como C2_MAX_<resto>.tif thresholded-N.tif.
//
// IMPORTANTE - requisito previo:
//   Este macro asume nombres ya limpios (sin ".lif -", sin espacios raros).
//   Si aun no lo has hecho, ejecuta primero el macro de renombrado
//   (Rename_MitosThresholded.ijm) sobre las carpetas "citosol per cell 8bit"
//   y "mitos thresholded", con DRY_RUN=true primero para verificar.
//
// Cambio respecto al Recorder: en vez de doWand(x,y) con una coordenada fija
// (que solo sirve para la imagen concreta donde se grabo), se usa
// setThreshold + "Create Selection" sobre la mascara de citosol, que
// selecciona automaticamente toda el area no-fondo, sea cual sea su forma
// o posicion.
//
// Uso:
//   1. Ejecuta la macro.
//   2. Elige la carpeta "citosol per cell 8bit" (mascaras C3_MAX_...-N.tif).
//   3. Elige la carpeta "mitos thresholded" (imagenes completas C2_MAX_....tif thresholded.tif).
//   4. Elige (o crea) la carpeta de salida para los "mitos per cell" resultantes.

run("Close All");

citosolDir = getDirectory("Elige la carpeta 'citosol per cell 8bit' (mascaras C3_MAX_...-N.tif)");
mitosDir   = getDirectory("Elige la carpeta 'mitos thresholded' (imagenes completas C2_MAX_....tif thresholded.tif)");
outputDir  = getDirectory("Elige (o crea) la carpeta de salida para 'mitos per cell'");

citosolList = getFileList(citosolDir);
mitosList   = getFileList(mitosDir);

citosolMarker = "C3-MAX_";
mitosMarker   = "C2-MAX_";

print("\\Clear");
print("=== Recortando mitos por celula usando mascaras de citosol ===");

setBatchMode(true);

processedCount = 0;
skippedCitosol = 0;
noMatchCount = 0;

for (i = 0; i < lengthOf(citosolList); i++) {
    citosolName = citosolList[i];
    citosolPath = citosolDir + citosolName;

    if (File.isDirectory(citosolPath)) continue;

    // Comprobamos que el nombre tiene el prefijo esperado (nombres ya limpios)
    startIdx = indexOf(citosolName, citosolMarker);
    if (startIdx == -1) {
        print("SALTADO (no empieza por 'C3-MAX_', ¿has renombrado esta carpeta?): " + citosolName);
        skippedCitosol++;
        continue;
    }

    // Todo lo que hay despues de "C3_MAX_" es "<resto>-<N>.tif"
    afterPrefix = substring(citosolName, startIdx + lengthOf(citosolMarker), lengthOf(citosolName));

    // El numero de celula es lo que hay tras el ULTIMO "-" y antes del ".tif"
    lastDash = lastIndexOf(afterPrefix, "-");
    if (lastDash == -1) {
        print("SALTADO (no se encuentra '-N' en el nombre): " + citosolName);
        skippedCitosol++;
        continue;
    }
    restPart = substring(afterPrefix, 0, lastDash); // "<resto>" (fecha + identificador), sin numero de celula

    afterDash = substring(afterPrefix, lastDash + 1, lengthOf(afterPrefix));
    dotPos = indexOf(afterDash, ".");
    if (dotPos == -1) {
        print("SALTADO (formato inesperado tras el guion): " + citosolName);
        skippedCitosol++;
        continue;
    }
    cellNumber = substring(afterDash, 0, dotPos);

    // Nombre esperado del archivo de mitocondrias COMPLETO (mismo resto, canal C2)
    mitosExpectedName = mitosMarker + restPart + ".tif thresholded.tif";

    // Buscamos ese nombre exacto en la carpeta de mitos
    mitosIndex = -1;
    for (j = 0; j < lengthOf(mitosList); j++) {
        if (mitosList[j] == mitosExpectedName) {
            mitosIndex = j;
            j = lengthOf(mitosList); // salir del bucle
        }
    }

    if (mitosIndex == -1) {
        print("SIN COINCIDENCIA en 'mitos thresholded' para: " + citosolName);
        print("  (se esperaba encontrar: " + mitosExpectedName + ")");
        noMatchCount++;
        continue;
    }

    mitosPath = mitosDir + mitosList[mitosIndex];

    // --- Paso 1: crear la seleccion a partir de la mascara de citosol ---
    open(citosolPath);
    citosolTitle = getTitle();
    setThreshold(1, 255);
    run("Create Selection");
    close(); // cerramos la mascara de citosol; la seleccion queda "recordada" por Fiji

    // --- Paso 2: aplicar esa seleccion sobre una copia de la imagen completa de mitos ---
    open(mitosPath);
    mitosTitle = getTitle();

    dupTitle = mitosMarker + restPart + ".tif thresholded-" + cellNumber;
    run("Duplicate...", "title=[" + dupTitle + "]");

    run("Restore Selection");
    setBackgroundColor(0, 0, 0);
    run("Clear Outside");

    saveAs("Tiff", outputDir + dupTitle + ".tif");
    close(); // cierra el duplicado ya guardado

    selectWindow(mitosTitle);
    close();

    print(citosolName + "  +  " + mitosList[mitosIndex] + "  ->  " + dupTitle + ".tif");
    processedCount++;
}

setBatchMode(false);

showMessage("Listo",
    "Archivos 'mitos per cell' generados: " + processedCount +
    "\nMascaras de citosol saltadas (nombre no valido): " + skippedCitosol +
    "\nMascaras de citosol sin imagen de mitos correspondiente: " + noMatchCount +
    "\n\nResultados guardados en:\n" + outputDir);
