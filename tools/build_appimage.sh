#!/usr/bin/env bash
# Gera o AppImage do Caçadores de Portais (Linux x86_64).
# Uso: tools/build_appimage.sh   (pode ser rodado de qualquer diretório)
set -euo pipefail

NOME_JOGO="Caçadores de Portais"
ID="CacadoresDePortais"
BINARIO="${ID}.x86_64"
PRESET="Linux"

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$RAIZ/build"
EXPORT_DIR="$BUILD/appimage/export"
APPDIR="$BUILD/appimage/${ID}.AppDir"
SAIDA="$BUILD/${ID}-x86_64.AppImage"

erro() { echo "ERRO: $*" >&2; exit 1; }

command -v godot >/dev/null 2>&1 \
    || erro "o 'godot' não está no PATH. Instale o Godot 4 ou ajuste o PATH."
command -v rsvg-convert >/dev/null 2>&1 \
    || erro "o 'rsvg-convert' não está no PATH (pacote librsvg)."
command -v desktop-file-validate >/dev/null 2>&1 \
    || erro "o 'desktop-file-validate' não está no PATH (pacote desktop-file-utils)."
[[ -f "$RAIZ/icon.svg" ]] || erro "icon.svg não encontrado em $RAIZ."

echo "==> Exportando o preset '$PRESET' para $EXPORT_DIR"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"
LOG_EXPORT="$BUILD/appimage/export.log"
if ! godot --headless --path "$RAIZ" --export-release "$PRESET" "$EXPORT_DIR/$BINARIO" >"$LOG_EXPORT" 2>&1; then
    tail -n 30 "$LOG_EXPORT" >&2
    erro "a exportação do Godot falhou (log completo em $LOG_EXPORT)."
fi
[[ -f "$EXPORT_DIR/$BINARIO" ]] || erro "a exportação não gerou $BINARIO."
[[ -f "$EXPORT_DIR/${ID}.pck" ]] || erro "a exportação não gerou ${ID}.pck."

echo "==> Montando o AppDir em $APPDIR"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
install -m 755 "$EXPORT_DIR/$BINARIO" "$APPDIR/usr/bin/$BINARIO"
install -m 644 "$EXPORT_DIR/${ID}.pck" "$APPDIR/usr/bin/${ID}.pck"

cat > "$APPDIR/AppRun" <<APPRUN
#!/usr/bin/env bash
# O .pck precisa ficar ao lado do binário (usr/bin).
AQUI="\$(dirname "\$(readlink -f "\${BASH_SOURCE[0]}")")"
exec "\$AQUI/usr/bin/$BINARIO" "\$@"
APPRUN
chmod 755 "$APPDIR/AppRun"

cat > "$APPDIR/${ID}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$NOME_JOGO
Comment=MMORPG de masmorras em primeira pessoa
Exec=AppRun
Icon=$ID
Terminal=false
Categories=Game;RolePlaying;
DESKTOP

rsvg-convert -w 256 -h 256 "$RAIZ/icon.svg" -o "$APPDIR/${ID}.png"
ln -s "${ID}.png" "$APPDIR/.DirIcon"

echo "==> Validando o .desktop"
desktop-file-validate "$APPDIR/${ID}.desktop"

if ! command -v appimagetool >/dev/null 2>&1; then
    cat >&2 <<AVISO

AVISO: o AppDir está pronto em:
  $APPDIR
mas o 'appimagetool' não está instalado, então o AppImage NÃO foi gerado.
Instale-o (por exemplo: paru -S appimagetool-bin) e rode este script de novo.
AVISO
    exit 2
fi

echo "==> Gerando $SAIDA"
rm -f "$SAIDA"
ARCH=x86_64 appimagetool "$APPDIR" "$SAIDA"
echo "AppImage gerado: $SAIDA"
