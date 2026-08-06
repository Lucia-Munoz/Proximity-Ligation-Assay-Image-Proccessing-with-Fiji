// Threshold_DefaultDark_Batch.ijm
//
// Para cada imagen de la carpeta de entrada:
//   1) Convierte a 8 bits.
//   2) Aplica el threshold automatico "Default dark" (fondo oscuro, objeto
//      claro) y lo fija en el rango 1-255.
//   3) Convierte a mascara binaria (Convert to Mask).
//   4) Guarda el resultado con el mismo nombre en la carpeta de salida.
//
// Uso:
//   1. Ejecuta la macro.
//   2. Elige la carpeta con las imagenes a procesar.
//   3. Elige (o crea) la carpeta de salida.

inputDir = getDirectory("Elige la carpeta con las imagenes a procesar");
outputDir = getDirectory("Elige (o crea) la carpeta de salida");

fileList = getFileList(inputDir);

setOption("BlackBackground", true);

setBatchMode(true);

processedCount = 0;

for (i = 0; i < lengthOf(fileList); i++) {
    currentPath = inputDir + fileList[i];

    if (File.isDirectory(currentPath)) {
        continue;
    }

    open(currentPath);
    title = getTitle();

    run("8-bit");
    setAutoThreshold("Default dark no-reset");
    setThreshold(1, 255, "raw");
    run("Convert to Mask");

    saveAs("Tiff", outputDir + title);
    close();

    processedCount++;
}

setBatchMode(false);

showMessage("Listo",
    "Imagenes procesadas: " + processedCount +
    "\n\nResultados guardados en:\n" + outputDir);
