// CytosolMask_to_NucleousPerCell.ijm
//
// Para cada mascara de citosol por celula (carpeta "citosol per cell 8bit",
// formato limpio C3_MAX_<resto>-<N>.tif), selecciona el area no vacia de
// esa mascara y la aplica sobre la imagen COMPLETA de nucleos
// correspondiente (carpeta "nucleos thresholded", formato limpio
// C4-MAX_<resto>.tif, recortando (Clear Outside) y
// guardando el resultado como C4_MAX_<resto>.tif thresholded-N.tif.
//
// IMPORTANTE - requisito previo:
//   Este macro asume nombres ya limpios (sin ".lif -", sin espacios raros).
//  
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
nucleousDir   = getDirectory("Elige la carpeta 'nucleous thresholded' (imagenes completas C4-MAX_....tif thresholded.tif)");
outputDir  = getDirectory("Elige (o crea) la carpeta de salida para 'nucleous per cell'");

citosolList = getFileList(citosolDir);
nucleousList   = getFileList(nucleousDir);

citosolMarker = "C3-MAX_";
nucleousMarker   = "C4-MAX_";

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
    nucleousExpectedName = nucleousMarker + restPart + ".tif";

    // Buscamos ese nombre exacto en la carpeta de mitos
    nucleousIndex = -1;
    for (j = 0; j < lengthOf(nucleousList); j++) {
        if (nucleousList[j] == nucleousExpectedName) {
            nucleousIndex = j;
            j = lengthOf(nucleousList); // salir del bucle
        }
    }

    if (nucleousIndex == -1) {
        print("SIN COINCIDENCIA en 'nucleous thresholded' para: " + citosolName);
        print("  (se esperaba encontrar: " + nucleousExpectedName + ")");
        noMatchCount++;
        continue;
    }

    nucleousPath = nucleousDir + nucleousList[nucleousIndex];

    // --- Paso 1: crear la seleccion a partir de la mascara de citosol ---
    open(citosolPath);
    citosolTitle = getTitle();
    setThreshold(1, 255);
    run("Create Selection");
    close(); // cerramos la mascara de citosol; la seleccion queda "recordada" por Fiji

    // --- Paso 2: aplicar esa seleccion sobre una copia de la imagen completa de mitos ---
    open(nucleousPath);
    nucleousTitle = getTitle();

    dupTitle = nucleousMarker + restPart + ".tif thresholded-" + cellNumber;
    run("Duplicate...", "title=[" + dupTitle + "]");

    run("Restore Selection");
    setBackgroundColor(0, 0, 0);
    run("Clear Outside");

    saveAs("Tiff", outputDir + dupTitle + ".tif");
    close(); // cierra el duplicado ya guardado

    selectWindow(nucleousTitle);
    close();

    print(citosolName + "  +  " + nucleousList[nucleousIndex] + "  ->  " + dupTitle + ".tif");
    processedCount++;
}

setBatchMode(false);

showMessage("Listo",
    "Archivos 'nucleous per cell' generados: " + processedCount +
    "\nMascaras de citosol saltadas (nombre no valido): " + skippedCitosol +
    "\nMascaras de citosol sin imagen de mitos correspondiente: " + noMatchCount +
    "\n\nResultados guardados en:\n" + outputDir);
