// Segmentar_nucleous_Macro.ijm
// Flujo:
//   1) Aplica un desenfoque Gaussiano a las imágenes abiertas
//   2) Aplica un umbral LOCAL automatico.
//
// Uso:
//   1. Abre las imágenes.
//   2. Ejecuta esta macro.
//   3. El resultado es una imagen binaria (blanco = senal detectada).
//
// Parametros a tener en cuenta si necesitas ajustar el resultado:
//   - sigma=4        -> radio del desenfoque Gaussiano (px). Mas alto =
//                        mas suavizado, menos ruido pero tambien menos
//                        detalle fino.
//   - radius=200      -> tamano de la ventana local (px) sobre la que se
//                        calcula el umbral en cada zona. Mas alto = umbral
//                        mas "global"/uniforme; mas bajo = se adapta mas
//                        a variaciones locales pero es mas sensible a
//                        ruido.
//   - parameter_1=-3 -> desplazamiento del umbral respecto a la media
//                        local (mean - 3 en este caso, con method=Mean).
//                        Valores mas negativos = umbral mas permisivo
//                        (detecta mas senal); menos negativos/positivos
//                        = mas estricto.
//   - white           -> el objeto de interes se considera mas brillante
//                        que el fondo (senal en blanco sobre fondo negro
//                        tras la binarizacion).

// Paso 1: suavizamos la imagen para reducir ruido antes de umbralizar
run("Gaussian Blur...", "sigma=4");

// Paso 2: umbral local automatico (metodo de la media local +/- offset)
run("Auto Local Threshold", "method=Mean radius=200 parameter_1=-3 parameter_2=0 white");
