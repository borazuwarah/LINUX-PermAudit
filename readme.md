# PERMAudit 🛡️

Auditor sencillo de permisos peligrosos para sistemas Unix/Linux.
Recorre un directorio y señala los archivos y carpetas con permisos que suelen ser un problema de seguridad.

- **Solo lee**: no modifica ningún permiso ni archivo.
- Sin dependencias: solo `find`, `ls` y utilidades estándar.
- Disponible en **POSIX sh** y en **bash**, con el mismo resultado.

> ⚠️ Úsalo únicamente en tu propio equipo o en sistemas donde tengas autorización.

## Qué revisa

| Nivel | Comprobación | Por qué importa |
|---|---|---|
| 🔴 Alto | Archivos escribibles por cualquier usuario (`o+w`) | Cualquiera podría modificarlos |
| 🔴 Alto | Directorios escribibles por cualquiera **sin sticky bit** | Un usuario puede borrar o reemplazar archivos de otros |
| 🟡 Medio | Archivos con **SUID / SGID** | Se ejecutan con los privilegios del propietario o grupo: conviene que sean legítimos |
| 🟡 Medio | Claves privadas legibles por otros (`id_rsa`, `id_ed25519`, `id_ecdsa`, `*.pem`, `*.key`) | Una clave expuesta compromete el acceso |
| 🟢 Bajo | Archivos sin propietario o grupo válido | Suelen ser restos de usuarios eliminados |

Para cada hallazgo se muestra la línea de `ls -ld` y una sugerencia de cómo corregirlo (por ejemplo `chmod o-w <archivo>`).

## Uso

```bash
# POSIX sh
./permaudit.sh                  # analiza el directorio actual
./permaudit.sh /home/usuario    # analiza otro directorio
./permaudit.sh /var -x          # sin cruzar a otros sistemas de archivos

# bash
./permaudit.bash
./permaudit.bash /home/usuario
./permaudit.bash /var -x
```

Si hace falta, dales permiso de ejecución primero:

```bash
chmod +x permaudit.sh permaudit.bash
```

### Opciones

| Opción | Descripción |
|---|---|
| `[directorio]` | Directorio a analizar (por defecto, el actual) |
| `-x` | No cruzar a otros sistemas de archivos (`find -xdev`) |
| `-h`, `--help` | Muestra la ayuda |

### Códigos de salida

| Código | Significado |
|---|---|
| `0` | Sin hallazgos |
| `1` | Hay al menos un hallazgo |
| `2` | El directorio no existe |

Esto permite usarlo en scripts, tareas programadas o CI:

```bash
./permaudit.sh /srv/app || echo "Revisar permisos"
```

## Ejemplo de salida

```console
PERMAudit: analizando '/tmp/prueba'

[ALTO] Archivos escribibles por cualquiera (o+w)
  -rw-rw-rw- 1 user user 0 Nov 18 14:46 /tmp/prueba/a.txt
  -> 1 hallazgo(s). Quita el permiso: chmod o-w <archivo>

[ALTO] Directorios escribibles por cualquiera sin sticky bit
  OK, nada encontrado

[MEDIO] Archivos SUID / SGID
  OK, nada encontrado

[MEDIO] Claves privadas legibles por otros usuarios
  -rw-r--r-- 1 user user 0 Nov 18 14:46 /tmp/prueba/id_rsa
  -> 1 hallazgo(s). Protégelas: chmod 600 <clave>

[BAJO] Archivos sin propietario o grupo válido
  OK, nada encontrado

Resultado: 2 hallazgo(s) en total.
```

Los colores (rojo, amarillo y verde) solo se muestran cuando la salida es una terminal.

## Notas y limitaciones

- Probado con `find` de GNU/Linux (con `dash` y `bash`). En macOS/BSD debería funcionar, pero no está verificado.
- Ejecútalo con tu usuario normal. Sobre `/` o `/etc` aparecerán muchos SUID legítimos (`sudo`, `passwd`...): revisa cada caso antes de quitar nada.
- Si no tienes permiso para leer alguna carpeta, se omite sin mostrar errores, así que ejecutarlo sin privilegios puede dejar zonas sin revisar.
- En la versión `sh`, un archivo con un salto de línea en el nombre aparecería partido en dos líneas. Es un caso muy raro y no afecta al análisis.
- Un hallazgo no siempre es un fallo: es un punto a revisar.

## Licencia

MIT
