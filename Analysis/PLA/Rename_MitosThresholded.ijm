// Rename_MitosThresholded.ijm
//
// Elimina de cada nombre de archivo el fragmento variable que hay entre el
// primer espacio y ".lif - ", dejando solo la parte fija del inicio pegada
// a la parte fija del final. Ademas, sustituye los guiones "-" por guiones
// bajos "_" SOLO en la parte inicial (A), para que quede un unico tipo de
// separador ahi. El guion de "thresholded-N" (parte B) se deja intacto,
// ya que no es un separador de nombre sino parte del sufijo generado por
// Find Maxima / Analyze Particles. Ejemplo:
//
//   "C2-MAX_260611 PLA TOTAL I - DM - DMEM.lif - DM_DMEM_NDUFV2_NDUFB8_001.tif thresholded-1.tif"
//   ->
//   "C2_MAX_260611DM_DMEM_NDUFV2_NDUFB8_001.tif thresholded-1.tif"
//
// Regla (no depende del texto concreto del experimento, solo de la posicion):
//   A = todo lo que hay ANTES del primer espacio, con "-" sustituido por "_"
//   B = todo lo que hay DESPUES de ".lif - " (sin tocar)
//   nuevo_nombre = A + B
//
// MODO DE PRUEBA (recomendado la primera vez):
//   Con DRY_RUN = true, la macro NO renombra nada; solo escribe en el Log
//   los pares "nombre antiguo -> nombre nuevo" para que los revises.
//   Cuando confirmes que la regla es correcta, cambia DRY_RUN a false y
//   vuelve a ejecutar para renombrar de verdad.

DRY_RUN = false; // cambia a false para renombrar de verdad

dir = getDirectory("Elige la carpeta con los archivos 'thresholded' a renombrar");
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

    spaceIndex = indexOf(oldName, " ");
    lifMarker = ".lif - ";
    lifIndex = indexOf(oldName, lifMarker);

    // Si el archivo no tiene el patron esperado (sin espacio o sin ".lif - "),
    // lo dejamos tal cual y avisamos, en vez de arriesgarnos a corromper el nombre.
    if (spaceIndex == -1 || lifIndex == -1) {
        print("SALTADO (no coincide el patron): " + oldName);
        skippedCount++;
        continue;
    }

    partA = substring(oldName, 0, spaceIndex);
    partA = replace(partA, "-", "_"); // unifica separadores solo en esta parte
    partB = substring(oldName, lifIndex + lengthOf(lifMarker), lengthOf(oldName));
    newName = partA + partB;

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
