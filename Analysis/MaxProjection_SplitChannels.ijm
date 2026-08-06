// MaxProjection_then_SplitChannels.ijm
//
// Flujo:
//   1) Para cada imagen actualmente abierta: proyeccion de maxima intensidad (Z Project)
//      y guardado como TIFF en la carpeta elegida.
//   2) Cierre de TODAS las imagenes originales.
//   3) Reapertura de cada proyeccion guardada.
//   4) Separacion de canales (Split Channels) sobre cada proyeccion, guardando
//      cada canal en su PROPIA subcarpeta dentro de "output" (una carpeta por canal,
//      p.ej. "output/C1", "output/C2", etc.), asi todas las imagenes del mismo
//      canal quedan juntas sin importar de que proyeccion vengan.
//
// Uso:
//   1. Abre todas las imagenes/stacks que quieras procesar.
//   2. Ejecuta esta macro (Plugins > Macros > Run..., o pegala en el editor de macros y dale a Run).
//   3. Elige la carpeta de salida cuando se te pida.

// ---- Paso 0: comprobaciones iniciales ----
outputDir = getDirectory("Elige una carpeta para guardar las proyecciones de maxima intensidad");

n = nImages;
if (n == 0) {
    showMessage("No hay imagenes abiertas", "Abre una o mas imagenes/stacks antes de ejecutar esta macro.");
    exit();
}

// Capturamos los titulos de todas las imagenes abiertas ANTES de tocar nada,
// porque los indices de ventana cambian al abrir/cerrar proyecciones.
titles = newArray(n);
for (i = 0; i < n; i++) {
    selectImage(i + 1); // selectImage es 1-based
    titles[i] = getTitle();
}

setBatchMode(true); // acelera el proceso y evita el parpadeo de ventanas

// Aqui guardaremos las rutas completas de cada proyeccion guardada,
// para poder reabrirlas en el paso 3 sin volver a preguntar por la carpeta.
projFiles = newArray(titles.length);

// Paso 1: max projection de cada imagen abierta
for (i = 0; i < titles.length; i++) {
    title = titles[i];
    selectWindow(title);

    // Preferimos el titulo de la ventana como nombre base: para archivos
    // multi-serie (.lif, .czi con varias series), Bio-Formats anade un
    // sufijo de serie al titulo de la ventana (p.ej. "file.lif - SeriesName"),
    // algo que getInfo("image.filename") NO incluye (solo devuelve el
    // nombre del archivo contenedor). Solo recurrimos a getInfo si el
    // titulo esta vacio.
    baseName = title;
    if (baseName == "") {
        fname = getInfo("image.filename");
        if (fname != "" && fname != "null") {
            baseName = fname;
        }
    }

    // Solo quitamos una extension final si una extension de imagen conocida
    // esta justo al FINAL del nombre. Esto evita cortar texto valioso en
    // nombres como "file.lif - SeriesName", donde el "." esta en medio y
    // no marca una extension real.
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
                e = knownExtensions.length; // salir del bucle
            }
        }
    }

    // Saneamos caracteres invalidos/problematicos en nombres de archivo
    // (p.ej. separadores de ruta o ":" sueltos de nombres de serie)
    baseName = replace(baseName, "[\\\\/:]", "-");

    saveName = "MAX_" + baseName + ".tif";
    newTitle = "MAX_" + baseName;

    // Usamos getDimensions en vez de nSlices, ya que nSlices devuelve el
    // numero TOTAL de imagenes del stack (canales x z-slices x frames) en
    // hyperstacks, mientras que Z Project espera solo el rango de indices
    // de Z (1 a zDepth). Usar nSlices directamente provoca un error
    // "out of range" en hyperstacks multicanal/multiframe.
    getDimensions(imgWidth, imgHeight, channels, zDepth, frames);

    if (zDepth > 1) {
        // Proyeccion de maxima intensidad sobre todos los Z-slices
        // (Z Project la aplica automaticamente tambien sobre canales/frames)
        run("Z Project...", "start=1 stop=" + zDepth + " projection=[Max Intensity]");
        rename(newTitle); // aseguramos que la ventana resultante tenga el nombre correcto
    } else {
        // Solo hay un Z-slice: duplicamos para tener igualmente una
        // "proyeccion" que guardar, con el mismo criterio de nombrado.
        run("Duplicate...", "title=[" + newTitle + "] duplicate");
    }

    // La imagen activa ahora es la proyeccion (o duplicado) que queremos guardar
    projTitle = getTitle();
    selectWindow(projTitle);

    savePath = outputDir + saveName;
    saveAs("Tiff", savePath);
    projFiles[i] = savePath; // guardamos la ruta para reabrirla despues

    // Cerramos la ventana de la proyeccion (la imagen original sigue abierta)
    close();
}

// Paso 2: cerrar las imagenes originales
close("*");

// Paso 3: reabrir las proyecciones guardadas y separar canales
output_dir = outputDir + "channels" + File.separator;
File.makeDirectory(output_dir);

for (i = 0; i < projFiles.length; i++) {
    open(projFiles[i]);

    getDimensions(width, height, channels, slices, frames);

    // Si es una imagen multicanal, o RGB, separamos canales
    if ((channels > 1) || (bitDepth() == 24)) {
        run("Split Channels");
    }

    // Guardamos cada imagen generada en una subcarpeta propia segun su canal.
    // Tras "Split Channels", ImageJ nombra cada ventana con el prefijo
    // "C1-", "C2-", etc. Usamos ese prefijo como nombre de subcarpeta para
    // que, por ejemplo, todos los "C1" de todas las proyecciones queden
    // juntos en output/channels/C1, todos los "C2" en output/channels/C2, etc.
    ch_nbr = nImages;
    for (c = 1; c <= ch_nbr; c++) {
        selectImage(c);
        currentImage_name = getTitle();

        // Extraemos el prefijo de canal (p.ej. "C1") si existe
        channelLabel = "C1"; // valor por defecto cuando no hubo split (un solo canal)
        dashIndex = indexOf(currentImage_name, "-");
        if (startsWith(currentImage_name, "C") && dashIndex > 1) {
            prefix = substring(currentImage_name, 0, dashIndex); // p.ej. "C1"
            isChannelPrefix = true;
            for (k = 1; k < lengthOf(prefix); k++) {
                digit = substring(prefix, k, k + 1);
                if (digit < "0" || digit > "9") {
                    isChannelPrefix = false;
                }
            }
            if (isChannelPrefix) {
                channelLabel = prefix;
            }
        }

        // Creamos (si no existe) la subcarpeta para este canal
        channelDir = output_dir + channelLabel + File.separator;
        if (!File.exists(channelDir)) {
            File.makeDirectory(channelDir);
        }

        saveAs("Tiff", channelDir + currentImage_name);
    }

    // Cerramos todo antes de pasar a la siguiente proyeccion
    run("Close All");
}

setBatchMode(false);

showMessage("Listo",
    "Proyecciones de maxima intensidad guardadas en:\n" + outputDir +
    "\n\nCanales separados guardados (uno por subcarpeta) en:\n" + output_dir);
