# Cambios

Todos los cambios importantes de Elkünun. Autor: App-Zilla.

## [1.1.0] — 2026-11-21

### Cambiado
- Nuevo estilo pixel art: casillas, cajas, araucarias y el zorro culpeo, nítidos a cualquier tamaño de ventana y en todos los temas.
- Fuente pixel Public Pixel (CC0) en títulos y botones.
- Nuevo icono en pixel art.
- La pantalla de inicio muestra el zorro del icono, redibujado en pixel art.
- Barrido irregular de izquierda a derecha al entrar en un nivel y al pasar al siguiente (se omite con «Reducir movimiento»).
- Las franjas de telar de arriba y abajo solo aparecen en la pantalla de inicio.
- La selección de nivel muestra de fondo, muy tenue, al zorro eligiendo piso en un ascensor.

### Licencia
- La app, el `.dmg` y el `.zip` incluyen el texto de la licencia MIT y la de la fuente Public Pixel (CC0).
- El código fuente pasa a ser público en GitHub.

## [1.0.0] — 2026-11-18

Primera versión.

### Juego
- Rompecabezas de empujar cajas con un zorro culpeo: solo se empuja, una caja a la vez.
- Campaña de 60 niveles generados por procedimiento, de 1 a 4 cajas y dificultad creciente, que se desbloquean de 10 en 10.
- Nivel aleatorio fácil, medio o difícil (según lo desbloqueado en la campaña), con códigos para compartir del tipo `2-9F3A0C1D`.
- Cada nivel tiene solución garantizada y se indica el mínimo de empujes.
- Deshacer y rehacer ilimitados, reiniciar, pausa y pistas (el siguiente empuje).
- Aviso cuando una caja queda en un fondo de saco («!») y cuando el puzle ya no tiene solución.
- Reloj de la partida, mejores marcas y tiempos por nivel, y pantalla de mejores puntajes.
- La partida en curso se guarda y se puede continuar al volver a abrir el juego.
- Teclado (flechas o WASD, Z, ⇧Z, R, H, Esc) y clic para caminar.

### Aspecto y sonido
- Gráficos geométricos inspirados con respeto en los textiles mapuches, en modo claro y oscuro.
- Muros como bloques en damero tenue, suelo en damero y araucarias alrededor del almacén.
- Zorro animado (respira, camina, empuja y mueve la cola).
- Música ambiental andina y efectos de sonido sintetizados por el propio juego.
- Icono propio: zorro facetado con la caja roja del juego.

### Accesibilidad e idiomas
- Español e inglés.
- Contraste alto, reducir animaciones y descripción del tablero para VoiceOver.

### Requisitos
- Mac con Apple silicon y macOS 14 (Sonoma) o posterior.
- Firma *ad hoc*, sin notarización: la primera vez hay que abrirlo desde Ajustes del Sistema › Privacidad y seguridad › «Abrir igualmente».
