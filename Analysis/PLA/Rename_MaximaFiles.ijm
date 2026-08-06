// Rename_MaximaFiles.ijm
//
// Renombra los archivos de la carpeta "find maxima" al mismo formato que
// los archivos "thresholded" ya renombrados, para poder emparejarlos por
// identificador comun. Ejemplo:
//
//   "MAX_DM_DMEM_NDUFV2_NDUFB8_001_decon_Ch0.ics.tif Maxima.tif"
//   ->
//   "C1_MAX_DM_DMEM_NDUFV2_NDUFB8_001.tif"
//
// Regla:
//   identificador = lo que hay ENTRE "MAX_" y "_decon"
//   nuevo_nombre  = "C1_MAX_" + identificador + ".tif"
//
// El prefijo "C1_" asume que todas las imagenes Maxima proceden del mismo
// canal (Ch0 -> canal 1). Si tuvieras Maxima de otros canales, avisa para
// adaptar la macro y que use el numero de canal real en vez de fijarlo.
//
// MODO DE PRUEBA (recomendado la primera vez):
//   Con DRY_RUN = true, la macro NO renombra nada; solo escribe en el Log
//   los pares "nombre antiguo -> nombre nuevo" para que los revises.
//   Cuando confirmes que la regla es correcta, cambia DRY_RUN a false y
//   vuelve a ejecutar para renombrar de verdad.

DRY_RUN = false; // cambia a false para renombrar de verdad

PREFIX = "C1_MAX_";
startMarker = "MAX_";
endMarker = "_decon";

dir = getDirectory("Elige la carpeta 'find maxima' con los archivos a renombrar");
fileList = getFileList(dir);

print("\\Clear");
if (DRY_RUN) {
    print("=== MODO DE PRUEBA: no se renombra ningun archivo ===");
} else {
    print("=== RENOMBRANDO ARCHIVOS ===");
}

renamedCount = 0;
skippedCount = 0;

for (i = 0; i < lengthOf(fileList); i++) {
    oldName = fileList[i];
    oldPath = dir + oldName;

    if (File.isDirectory(oldPath)) {
        continue; // ignoramos subcarpetas
    }

    startIndex = indexOf(oldName, startMarker);
    endIndex = indexOf(oldName, endMarker);

    // Si el archivo no tiene el patron esperado, lo saltamos en vez de
    // arriesgarnos a generar un nombre incorrecto.
    if (startIndex == -1 || endIndex == -1 || endIndex <= (startIndex + lengthOf(startMarker))) {
        print("SALTADO (no coincide el patron): " + oldName);
        skippedCount++;
        continue;
    }

    identifier = substring(oldName, startIndex + lengthOf(startMarker), endIndex);
    newName = PREFIX + identifier + ".tif";

    print(oldName + "  ->  " + newName);

    if (!DRY_RUN) {
        newPath = dir + newName;
        success = File.rename(oldPath, newPath);
        if (!success) {
            print("  *** ERROR al renombrar este archivo ***");
        } else {
            renamedCount++;
        }
    }
}

if (DRY_RUN) {
    showMessage("Modo de prueba completado",
        "Revisa la ventana Log para comprobar los nombres nuevos.\n" +
        "Si son correctos, cambia DRY_RUN a false en la macro y ejecutala de nuevo.");
} else {
    showMessage("Renombrado completado",
        "Archivos renombrados: " + renamedCount + "\n" +
        "Archivos saltados (no coincidian con el patron): " + skippedCount);
}
