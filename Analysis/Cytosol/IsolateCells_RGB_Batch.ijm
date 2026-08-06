// IsolateCells_RGB_Batch.ijm
//
// Para CADA imagen actualmente abierta que sea una imagen RGB "label"
// (cada celula tiene un color propio, no un valor de etiqueta con LUT),
// esta macro:
//   1) Recorre la imagen pixel a pixel.
//   2) Cada vez que encuentra un pixel de un color no visitado y distinto
//      del fondo, usa doWand() en ese punto (igual que si hicieras click
//      con la varita magica) para seleccionar automaticamente esa celula.
//   3) Duplica la imagen original completa, aisla esa celula (borra el
//      resto a negro) y la guarda como TIFF.
//   4) Marca esos pixeles como "visitados" para no procesar la misma
//      celula dos veces.
// Este proceso se repite para todas las imagenes que tengas abiertas.
//
// Esto reemplaza el proceso manual de usar la varita en cada celula:
// aqui se detectan y aislan todas las celulas automaticamente, en todas
// las imagenes abiertas, en una sola pasada.
//
// IMPORTANTE:
//   - Esta version es para imagenes RGB reales (bitDepth 24), donde cada
//     celula es un bloque de pixeles de color solido y uniforme.
//   - Se asume que el fondo es un color solido (por defecto negro
//     puro, 0,0,0). Si tu fondo es otro color, cambia bgR/bgG/bgB abajo.
//   - Al ser un recorrido pixel a pixel, en imagenes muy grandes puede
//     tardar bastante (varios segundos a un par de minutos POR imagen).
//
// Uso:
//   1. Abre todas las imagenes RGB label que quieras procesar.
//   2. Ejecuta esta macro.
//   3. Elige la carpeta de salida cuando se te pida (una unica vez,
//      valida para todas las imagenes).

// ---- Parametros ----
bgR = 0; bgG = 0; bgB = 0; // color de fondo a ignorar (por defecto negro)
minMeanToSave = 0.5;       // si la imagen aislada tiene un brillo medio por
                            // debajo de esto, se considera "solo negra"
                            // (ruido/artefacto) y no se guarda
minAreaPixels = 20;        // regiones mas pequenas que esto (en pixeles) se
                            // ignoran directamente (ruido/artefactos de borde)

// ---- Paso 0: comprobaciones iniciales ----
nImgs = nImages;
if (nImgs == 0) {
    showMessage("No hay imagenes abiertas", "Abre una o mas imagenes RGB label antes de ejecutar esta macro.");
    exit();
}

// Capturamos los titulos de todas las imagenes abiertas ANTES de tocar nada,
// porque los indices de ventana cambian al crear/cerrar imagenes auxiliares.
titles = newArray(nImgs);
for (i = 0; i < nImgs; i++) {
    selectImage(i + 1); // selectImage es 1-based
    titles[i] = getTitle();
}

dir = getDirectory("Elige una carpeta para guardar las celulas aisladas");

bgPacked = (bgR << 16) + (bgG << 8) + bgB;

setBatchMode(true);
setBackgroundColor(0, 0, 0);

totalSaved = 0;
skippedImages = "";

// ---- Procesamos cada imagen abierta, una por una ----
for (imgIndex = 0; imgIndex < titles.length; imgIndex++) {
    originalTitle = titles[imgIndex];
    selectWindow(originalTitle);

    if (bitDepth() != 24) {
        // Esta imagen no es RGB: la saltamos, sin interrumpir el resto del lote
        skippedImages = skippedImages + originalTitle + "\n";
        continue;
    }

    // Nombre base saneado (mismo criterio que en los otros macros del flujo)
    baseName = originalTitle;
    knownExtensions = newArray(".ome.tif", ".ome.tiff", ".tif", ".tiff", ".lif",
                                ".czi", ".nd2", ".lsm", ".oib", ".oif", ".jpg",
                                ".jpeg", ".png", ".bmp", ".gif");
    for (e = 0; e < knownExtensions.length; e++) {
        ext = knownExtensions[e];
        extLen = lengthOf(ext);
        nameLen = lengthOf(baseName);
        if (nameLen > extLen) {
            candidate = substring(baseName, nameLen - extLen, nameLen);
            if (toLowerCase(candidate) == ext) {
                baseName = substring(baseName, 0, nameLen - extLen);
                e = knownExtensions.length;
            }
        }
    }
    baseName = replace(baseName, "[\\\\/:]", "-");

    w = getWidth();
    h = getHeight();

    // Imagen auxiliar para llevar la cuenta de que pixeles ya pertenecen a
    // una celula ya procesada (0 = no visitado, 255 = ya procesado).
    // Se crea de nuevo para cada imagen.
    newImage("visited_mask", "8-bit black", w, h, 1);
    visitedTitle = getTitle();

    roiManager("reset");

    n = 0;
    for (y = 0; y < h; y++) {
        x = 0;
        while (x < w) {
            selectWindow(visitedTitle);
            vPix = getPixel(x, y);

            if (vPix == 0) {
                selectWindow(originalTitle);
                colorVal = getPixel(x, y);

                if (colorVal != bgPacked) {
                    // Seleccionamos automaticamente toda la celula de este color,
                    // igual que un click manual con la varita magica en (x, y).
                    // IMPORTANTE: especificamos tolerance=0 y "8-connected" de forma
                    // explicita. Si se llama a doWand(x,y) sin estos parametros,
                    // ImageJ usa la tolerancia configurada en Edit > Options > Wand
                    // Tool, que puede no ser 0 y fusionar celulas de distinto color/
                    // nivel de gris en una sola seleccion.
                    doWand(x, y, 0, "8-connected");
                    roiManager("add");
                    idx = roiManager("count") - 1;

                    // Marcamos esos pixeles como visitados (esto se hace SIEMPRE,
                    // sea o no ruido, para no volver a escanear esta region)
                    selectWindow(visitedTitle);
                    roiManager("select", idx);
                    setColor(255);
                    fill();
                    getSelectionBounds(bx, by, bw, bh);
                    run("Select None");

                    // Comprobamos el area de la region encontrada. Regiones muy
                    // pequenas suelen ser ruido/artefactos de borde (pixeles casi
                    // negros pero no exactamente 0) en vez de celulas reales:
                    // las descartamos sin llegar a duplicar/guardar nada.
                    selectWindow(originalTitle);
                    roiManager("select", idx);
                    getStatistics(regionArea);
                    run("Select None");

                    if (regionArea >= minAreaPixels) {
                        // Duplicamos la imagen ORIGINAL completa (sin seleccion activa)
                        selectWindow(originalTitle);
                        run("Select None");
                        newName = baseName + "_cell" + (n + 1);
                        run("Duplicate...", "title=[" + newName + "]");

                        // Aplicamos la misma seleccion sobre la copia y borramos fuera
                        roiManager("select", idx);
                        run("Clear Outside");
                        run("Select None");

                        // Comprobacion final: si tras aislar la celula la imagen
                        // resultante es completamente (o casi) negra, la
                        // descartamos y no la guardamos.
                        getStatistics(area, meanVal);
                        if (meanVal > minMeanToSave) {
                            saveAs("Tiff", dir + newName + ".tif");
                            n++;
                        }
                        close();
                    }

                    // Saltamos el resto de la fila actual dentro del bounding box
                    // de esta region para no reescanear pixeles ya marcados
                    // (optimizacion; la correctitud la garantiza el visited_mask)
                    x = bx + bw;
                    continue;
                }
            }
            x++;
        }
    }

    // Limpieza para esta imagen antes de pasar a la siguiente
    selectWindow(visitedTitle);
    close();
    roiManager("reset");

    totalSaved = totalSaved + n;
}

setBatchMode(false);

msg = "Se han guardado " + totalSaved + " celulas aisladas en total en:\n" + dir;
if (skippedImages != "") {
    msg = msg + "\n\nImagenes NO procesadas (no son RGB de 24-bit):\n" + skippedImages;
}
showMessage("Listo", msg);
