// FindMaxima_Batch.ijm
//
// Flujo:
//   1) Pide una carpeta con las imagenes a procesar.
//   2) Crea (si no existe) una subcarpeta "find maxima" dentro de esa carpeta.
//   3) Para cada imagen de la carpeta: aplica Find Maxima (prominence=10,
//      output=[Single Points]) y guarda el resultado en "find maxima",
//      con el mismo nombre + " Maxima.tif" (igual que el Recorder de Fiji).
//


//Parámetros 
prominence = 10; 

// Paso 0: Elegir carpeta de entrada y preparar la de salida 
dir = getDirectory("Elige la carpeta con las imagenes a procesar");
fileList = getFileList(dir);

output_dir = dir + "find maxima" + File.separator;
File.makeDirectory(output_dir);

setBatchMode(true);

// Paso 1: procesar cada archivo de la carpeta
for (i = 0; i < lengthOf(fileList); i++) {
    current_imagePath = dir + fileList[i];

    // Nos aseguramos de que no es una carpeta (p.ej. la propia "find maxima")
    if (!File.isDirectory(current_imagePath)) {

        open(current_imagePath);
        originalTitle = getTitle();

        run("Find Maxima...", "prominence=" + prominence + " output=[Single Points]");

        // El nombre de la ventana resultante es "<original> Maxima"
        saveName = originalTitle + " Maxima.tif";
        saveAs("Tiff", output_dir + saveName);

        // Cerramos la imagen de maximos y la original
        close(); // cierra la imagen de maximos (activa tras el saveAs)
        if (isOpen(originalTitle)) {
            selectWindow(originalTitle);
            close();
        }
    }
}

setBatchMode(false);

showMessage("Listo", "Find Maxima aplicado a todas las imagenes.\nResultados guardados en:\n" + output_dir);
