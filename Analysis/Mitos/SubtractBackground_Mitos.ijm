// SubtractBackground_Batch.ijm
//
// Para cada imagen de la carpeta de entrada:
//   1) Aplica Subtract Background (rolling=rollingRadius).
//   2) Guarda el resultado con el mismo nombre en la carpeta de salida.
//
// Uso:
//   1. Ejecuta la macro.
//   2. Elige la carpeta con las imagenes a procesar.
//   3. Elige (o crea) la carpeta de salida.

// ---- Parametros (cambia aqui si necesitas otro valor) ----
rollingRadius = 20;

inputDir = getDirectory("Elige la carpeta con las imagenes a procesar");
outputDir = getDirectory("Elige (o crea) la carpeta de salida");

fileList = getFileList(inputDir);

setBatchMode(true);

processedCount = 0;

for (i = 0; i < lengthOf(fileList); i++) {
    currentPath = inputDir + fileList[i];

    if (File.isDirectory(currentPath)) {
        continue;
    }

    open(currentPath);
    title = getTitle();

    run("Subtract Background...", "rolling=" + rollingRadius);

    saveAs("Tiff", outputDir + title);
    close();

    processedCount++;
}

setBatchMode(false);

showMessage("Listo",
    "Imagenes procesadas: " + processedCount +
    "\n\nResultados guardados en:\n" + outputDir);
