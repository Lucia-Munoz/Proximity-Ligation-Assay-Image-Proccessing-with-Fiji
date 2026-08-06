// FindMaximaPerCell.ijm
//
// Para cada imagen "Maxima" (find maxima, formato C1_MAX_IDENTIFICADOR.tif),
// busca todas las mascaras de celula correspondientes en "mitos per cell"
// (formato C2_MAX_<algo>IDENTIFICADOR.tif thresholded-N.tif) y genera, para
// cada celula N, una copia de la imagen Maxima recortada a la zona de esa
// celula (Analyze Particles sobre la mascara -> combinar ROIs -> Clear
// Outside sobre una copia de Maxima), guardada como
// C1_MAX_IDENTIFICADOR-N.tif en la carpeta de salida.
//
// IMPORTANTE: el ROI Manager se vacia (roiManager("reset")) antes de cada
// celula, para que las ROIs de una celula no se acumulen ni se mezclen con
// las de la celula siguiente.
//
// Uso:
//   1. Ejecuta la macro.
//   2. Elige la carpeta "find maxima" (imagenes C1_MAX_...).
//   3. Elige la carpeta "mitos per cell" (imagenes C2_MAX_... thresholded-N).
//   4. Elige (o crea) la carpeta de salida "find maxima per cell".

run("Close All");
roiManager("reset");

maximaDir = getDirectory("Elige la carpeta 'find maxima' (imagenes C1_MAX_...)");
cellsDir  = getDirectory("Elige la carpeta 'mitos per cell' (imagenes C2_MAX_... thresholded-N)");
outputDir = getDirectory("Elige (o crea) la carpeta de salida 'find maxima per cell'");

maximaList = getFileList(maximaDir);
cellsList  = getFileList(cellsDir);

startMarker = "C1_MAX_";
extMarker = ".tif";

print("\\Clear");

// --- Comprobacion de seguridad: detectar si las carpetas se seleccionaron
// en orden invertido (p.ej. si en el dialogo de "find maxima" se eligio
// por error la carpeta de "mitos per cell", o viceversa) y corregirlo
// automaticamente, para no depender de que el orden se recuerde bien. ---
c1InMaxima = 0;
for (i = 0; i < lengthOf(maximaList); i++) {
    if (indexOf(maximaList[i], startMarker) != -1) c1InMaxima++;
}
c1InCells = 0;
for (i = 0; i < lengthOf(cellsList); i++) {
    if (indexOf(cellsList[i], startMarker) != -1) c1InCells++;
}

if (c1InMaxima == 0 && c1InCells > 0) {
    print("Aviso: las carpetas parecian intercambiadas (la carpeta 'find maxima'");
    print("elegida no contenia archivos C1_MAX_... pero la otra si). Se han");
    print("intercambiado automaticamente para continuar correctamente.");

    tmpDir = maximaDir; maximaDir = cellsDir; cellsDir = tmpDir;
    tmpList = maximaList; maximaList = cellsList; cellsList = tmpList;
} else if (c1InMaxima == 0 && c1InCells == 0) {
    showMessage("Aviso",
        "No se ha encontrado ningun archivo con el patron 'C1_MAX_' en ninguna\n" +
        "de las dos carpetas elegidas. Revisa que hayas seleccionado la carpeta\n" +
        "'find maxima' correcta (con los archivos ya renombrados).");
    exit();
}

print("=== Emparejando Maxima con celulas ===");

setBatchMode(true);

processedCount = 0;
imagesWithoutMatch = 0;
imagesSkipped = 0;

for (m = 0; m < lengthOf(maximaList); m++) {
    maximaName = maximaList[m];
    maximaPath = maximaDir + maximaName;

    if (File.isDirectory(maximaPath)) continue;

    // Extraemos el identificador: lo que hay entre "C1_MAX_" y el ".tif" final
    startIdx = indexOf(maximaName, startMarker);
    if (startIdx == -1) {
        print("SALTADO (Maxima, no coincide patron): " + maximaName);
        imagesSkipped++;
        continue;
    }
    idStart = startIdx + lengthOf(startMarker);
    idEnd = lastIndexOf(maximaName, extMarker);
    if (idEnd == -1 || idEnd <= idStart) {
        print("SALTADO (Maxima, no coincide patron): " + maximaName);
        imagesSkipped++;
        continue;
    }
    identifier = substring(maximaName, idStart, idEnd);

    // Patron de busqueda dentro de la carpeta de celulas
    searchPattern = identifier + ".tif thresholded-";

    // Construimos la lista de indices coincidentes como texto separado por
    // comas y la convertimos a array al final. Evitamos Array.concat con
    // newArray(c) para un unico valor, ya que newArray(c) con un numero
    // crea un array de longitud c lleno de ceros, NO un array que contenga
    // el valor c (bug que causaba que todo emparejase con el indice 0).
    matchIndicesStr = "";
    for (c = 0; c < lengthOf(cellsList); c++) {
        if (indexOf(cellsList[c], searchPattern) != -1) {
            if (matchIndicesStr == "") {
                matchIndicesStr = "" + c;
            } else {
                matchIndicesStr = matchIndicesStr + "," + c;
            }
        }
    }

    if (matchIndicesStr == "") {
        print("SIN CELULAS ENCONTRADAS para: " + maximaName);
        imagesWithoutMatch++;
        continue;
    }

    matchIndices = split(matchIndicesStr, ",");

    // Abrimos la imagen Maxima una sola vez, se reutiliza para cada celula
    open(maximaPath);
    maximaTitle = getTitle();

    for (k = 0; k < lengthOf(matchIndices); k++) {
        cellIndex = parseInt(matchIndices[k]);
        cellName = cellsList[cellIndex];
        cellPath = cellsDir + cellName;

        // Extraemos el numero de celula N de "thresholded-N.tif"
        thPos = indexOf(cellName, "thresholded-");
        afterTh = substring(cellName, thPos + lengthOf("thresholded-"), lengthOf(cellName));
        dotPos = indexOf(afterTh, ".");
        cellNumber = substring(afterTh, 0, dotPos);

        open(cellPath);
        cellTitle = getTitle();

        // Vaciamos el ROI Manager para que esta celula no se mezcle con las anteriores
        roiManager("reset");

        selectWindow(cellTitle);
        // Fijamos el threshold explicitamente (en vez de depender de la
        // autodeteccion de ImageJ) para evitar el error "A threshold has
        // not been set...", que puede aparecer en mascaras con poco
        // contraste bimodal aunque sean binarias (0/255). Asumimos que el
        // fondo es 0 y cualquier valor mayor es senal (mitocondria).
        setThreshold(1, 255);
        run("Analyze Particles...", "clear add composite");

        // --- DIAGNOSTICO: cuantas ROIs se detectaron para esta celula ---
        nRois = roiManager("count");
        print("  [diag] " + cellName + " -> ROIs detectadas: " + nRois);

        selectWindow(maximaTitle);
        dupTitle = "C1_MAX_" + identifier + "-" + cellNumber;
        run("Duplicate...", "title=[" + dupTitle + "]");

        roiManager("Combine");

        // --- DIAGNOSTICO: rectangulo delimitador de la seleccion combinada ---
        getSelectionBounds(selX, selY, selW, selH);
        print("  [diag] " + dupTitle + " -> seleccion combinada: x=" + selX + " y=" + selY + " w=" + selW + " h=" + selH);

        setBackgroundColor(0, 0, 0);
        run("Clear Outside");

        saveAs("Tiff", outputDir + dupTitle + ".tif");
        close(); // cierra el duplicado ya guardado

        selectWindow(cellTitle);
        close();

        print(maximaName + "  +  " + cellName + "  ->  " + dupTitle + ".tif");
        processedCount++;
    }

    selectWindow(maximaTitle);
    close();
}

setBatchMode(false);
roiManager("reset");

showMessage("Listo",
    "Combinaciones Maxima+celula guardadas: " + processedCount +
    "\nImagenes Maxima sin celulas encontradas: " + imagesWithoutMatch +
    "\nImagenes Maxima saltadas (no coincidian con el patron): " + imagesSkipped +
    "\n\nResultados guardados en:\n" + outputDir);
