#!/bin/sh
# permaudit.sh: auditor sencillo de permisos peligrosos en un directorio (POSIX sh).
# Solo LEE: no modifica nada. Úsalo en tu propio equipo.
# Uso: ./permaudit.sh [directorio] [-x]      (por defecto: directorio actual)
#   -x   no cruzar a otros sistemas de archivos

XDEV=""
DIR="."
for arg in "$@"; do
    case $arg in
        -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        -x) XDEV="-xdev";;
        *)  DIR=$arg;;
    esac
done
[ -d "$DIR" ] || { echo "No existe el directorio: $DIR" >&2; exit 2; }

if [ -t 1 ]; then
    ESC=$(printf '\033')
    R="${ESC}[31m"; Y="${ESC}[33m"; G="${ESC}[32m"; B="${ESC}[1m"; N="${ESC}[0m"
else
    R=""; Y=""; G=""; B=""; N=""
fi

TOTAL=0

# seccion "Título" "Consejo" color -- args de find
seccion() {
    titulo=$1; consejo=$2; color=$3; shift 3
    printf '%s%s%s\n' "$B" "$titulo" "$N"
    # shellcheck disable=SC2086  # $XDEV vacío o "-xdev" a propósito
    OUT=$(find "$DIR" $XDEV "$@" -exec ls -ld -- {} + 2>/dev/null)
    if [ -z "$OUT" ]; then
        n=0
        printf '  %sOK, nada encontrado%s\n' "$G" "$N"
    else
        n=$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')
        printf '%s\n' "$OUT" | sed "s/^/  ${color}/; s/\$/${N}/"
        printf '  -> %s hallazgo(s). %s\n' "$n" "$consejo"
    fi
    echo
    TOTAL=$((TOTAL + n))
}

printf '%sPERMAudit%s: analizando '"'%s'"'\n\n' "$B" "$N" "$DIR"

seccion "[ALTO] Archivos escribibles por cualquiera (o+w)" \
    "Quita el permiso: chmod o-w <archivo>" "$R" \
    -type f -perm -0002

seccion "[ALTO] Directorios escribibles por cualquiera sin sticky bit" \
    "Añade sticky o quita permiso: chmod +t <dir>  /  chmod o-w <dir>" "$R" \
    -type d -perm -0002 ! -perm -1000

seccion "[MEDIO] Archivos SUID / SGID" \
    "Revisa que cada uno sea legítimo; quita con chmod u-s,g-s si no" "$Y" \
    -type f \( -perm -4000 -o -perm -2000 \)

seccion "[MEDIO] Claves privadas legibles por otros usuarios" \
    "Protégelas: chmod 600 <clave>" "$Y" \
    -type f \( -name 'id_rsa' -o -name 'id_ed25519' -o -name 'id_ecdsa' -o -name '*.pem' -o -name '*.key' \) \
    \( -perm -0040 -o -perm -0004 \)

seccion "[BAJO] Archivos sin propietario o grupo válido" \
    "Asígnalos a un usuario existente: chown usuario:grupo <archivo>" "$Y" \
    \( -nouser -o -nogroup \)

if [ "$TOTAL" -eq 0 ]; then
    printf '%s%sResultado: sin hallazgos.%s\n' "$G" "$B" "$N"; exit 0
else
    printf '%sResultado: %s hallazgo(s) en total.%s\n' "$B" "$TOTAL" "$N"; exit 1
fi
