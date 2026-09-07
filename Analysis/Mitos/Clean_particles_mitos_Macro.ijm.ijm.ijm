// Clean_Particles_mitos_Macro.ijm
//
// Flujo:
//   1) Detecta particulas muy pequenas (tamano 0-0.1, en las unidades
//      calibradas de la imagen) con Analyze Particles, y las anade todas
//      al ROI Manager.
//   2) Combina esas ROIs en una sola seleccion.
//   3) Borra el contenido de esa seleccion eliminando asi esas particulas pequeñas de la imagen.
//   4) Limpia el ROI Manager/overlay
//
// Uso:
//   1. Abre la imagen sobre laque quieres eliminar las particulas pequenas.
//   2. Ejecuta esta macro.
//
// Nota: el rango "size=0-0.1" asume que la imagen esta calibrada en las
// unidades que quieras usar para el filtro de tamano (p.ej. micras^2).
// Ajusta ese rango si necesitas otro umbral de tamano minimo.

// Paso 1: detectamos las particulas pequenas y las anadimos al ROI Manager
// (clear = vacia el Manager antes de empezar; add = anade cada particula
// encontrada como una ROI; composite = evita problemas con particulas que
// tengan agujeros/formas compuestas)
run("Analyze Particles...", "size=0-0.1 clear add composite");

// Paso 2: combinamos todas las ROIs detectadas en una unica seleccion
roiManager("Combine");

// Paso 3: borramos esa seleccion en el slice activo, eliminando
// asi las particulas pequenas de la imagen
setBackgroundColor(0, 0, 0);
run("Clear", "slice");

// Paso 4: limpiamos ROIs/overlay para dejar la imagen visualmente limpia
roiManager("Show All without labels");
roiManager("Show None");
run("Remove Overlay");
