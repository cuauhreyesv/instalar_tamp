#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN EL PHP DE TAMP
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TAMP"
echo "========================================="
echo ""

# 1. Encontrar PHP de TAMP
echo "[1] Buscando PHP de TAMP..."

TAMP_DIR=""
if [ -d "$HOME/tamp-cuauh" ]; then
    TAMP_DIR="$HOME/tamp-cuauh"
elif [ -d "$HOME/tamp" ]; then
    TAMP_DIR="$HOME/tamp"
else
    echo "    ❌ No se encontró TAMP"
    exit 1
fi

TAMP_PHP="$TAMP_DIR/php/bin/php"
echo "    ✅ PHP de TAMP: $TAMP_PHP"

# 2. Crear php.ini
echo ""
echo "[2] Creando php.ini para TAMP..."

mkdir -p "$TAMP_DIR/php/lib"

cat > "$TAMP_DIR/php/lib/php.ini" << 'EOF'
extension=gd
extension=gd2
extension=mysqli
extension=curl
extension=mbstring
extension=json
extension=fileinfo

date.timezone = America/Mexico_City
upload_max_filesize = 20M
post_max_size = 20M
memory_limit = 256M
max_execution_time = 300
display_errors = On
error_reporting = E_ALL
log_errors = On
error_log = /sdcard/htdocs/php_errors.log
EOF

echo "    ✅ php.ini creado"

# 3. Buscar gd.so
echo ""
echo "[3] Buscando gd.so..."

GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)

if [ -z "$GDSO" ]; then
    GDSO=$(find / -name "gd.so" 2>/dev/null | head -1)
fi

if [ -n "$GDSO" ]; then
    mkdir -p "$TAMP_DIR/php/lib/extensions"
    cp "$GDSO" "$TAMP_DIR/php/lib/extensions/gd.so"
    echo "extension=$TAMP_DIR/php/lib/extensions/gd.so" >> "$TAMP_DIR/php/lib/php.ini"
    echo "    ✅ gd.so copiado"
else
    echo "    ⚠️ No se encontró gd.so"
fi

# 4. Verificar GD
echo ""
echo "[4] Verificando GD..."

if $TAMP_PHP -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP de TAMP"
else
    echo "    ❌ GD NO activo"
fi

# 5. Reiniciar TAMP
echo ""
echo "[5] Reiniciando TAMP..."

pkill -f "httpd" 2>/dev/null
sleep 2

if [ -f "$TAMP_DIR/apache/bin/apachectl" ]; then
    $TAMP_DIR/apache/bin/apachectl start 2>/dev/null
    echo "    ✅ Apache reiniciado"
fi

# 6. Crear archivo de verificación
echo ""
echo "[6] Creando verificación..."

cat > /sdcard/htdocs/devmx/bordamex/gd_test.php << 'EOF'
<?php
echo "=== GD EN TAMP ===\n";
echo "PHP: " . phpversion() . "\n";
echo "INI: " . php_ini_loaded_file() . "\n";
echo "GD: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromjpeg: " . (function_exists('imagecreatefromjpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagejpeg: " . (function_exists('imagejpeg') ? '✅ SI' : '❌ NO') . "\n";
?>
EOF

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""