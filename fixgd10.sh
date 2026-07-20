#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# FORZAR GD EN TAMP - USANDO PHP DE TERMUX
# =====================================================

echo "========================================="
echo "  FORZAR GD EN TAMP"
echo "========================================="
echo ""

# 1. Verificar PHP de Termux
echo "[1] Verificando PHP de Termux..."

TERMUX_PHP="/data/data/com.termux/files/usr/bin/php"

if [ ! -f "$TERMUX_PHP" ]; then
    echo "    ❌ PHP de Termux no encontrado"
    exit 1
fi
echo "    ✅ PHP de Termux: $TERMUX_PHP"

# 2. Verificar GD en PHP de Termux
echo ""
echo "[2] Verificando GD en PHP de Termux..."

if $TERMUX_PHP -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD está activo en PHP de Termux"
else
    echo "    ❌ GD no está activo en PHP de Termux"
    echo "    Instalando php-gd..."
    pkg install php-gd -y 2>/dev/null
fi

# 3. Reemplazar PHP de TAMP
echo ""
echo "[3] Reemplazando PHP de TAMP..."

TAMP_PHP=""
if [ -f "$HOME/tamp-cuauh/php/bin/php" ]; then
    TAMP_PHP="$HOME/tamp-cuauh/php/bin/php"
    TAMP_DIR="$HOME/tamp-cuauh"
elif [ -f "$HOME/tamp/php/bin/php" ]; then
    TAMP_PHP="$HOME/tamp/php/bin/php"
    TAMP_DIR="$HOME/tamp"
else
    echo "    ❌ No se encontró PHP de TAMP"
    exit 1
fi

# Hacer backup
mv "$TAMP_PHP" "${TAMP_PHP}.original" 2>/dev/null

# Crear enlace simbólico
ln -sf "$TERMUX_PHP" "$TAMP_PHP"
echo "    ✅ PHP de TAMP reemplazado: $TAMP_PHP"

# 4. Crear php.ini
echo ""
echo "[4] Creando php.ini para TAMP..."

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
EOF

echo "    ✅ php.ini creado"

# 5. Configurar Apache
echo ""
echo "[5] Configurando Apache..."

HTTPD_CONF=""
if [ -f "$TAMP_DIR/apache/conf/httpd.conf" ]; then
    HTTPD_CONF="$TAMP_DIR/apache/conf/httpd.conf"
fi

if [ -n "$HTTPD_CONF" ]; then
    # Verificar si ya está configurado
    if ! grep -q "PHPRC" "$HTTPD_CONF" 2>/dev/null; then
        echo "" >> "$HTTPD_CONF"
        echo "# PHP Configuration" >> "$HTTPD_CONF"
        echo "SetEnv PHPRC $TAMP_DIR/php/lib/" >> "$HTTPD_CONF"
        echo "SetEnv PHP_INI_SCAN_DIR $TAMP_DIR/php/lib/" >> "$HTTPD_CONF"
        echo "    ✅ httpd.conf configurado"
    else
        echo "    ✅ httpd.conf ya configurado"
    fi
fi

# 6. Verificar GD en TAMP
echo ""
echo "[6] Verificando GD en TAMP..."

if $TAMP_PHP -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP de TAMP"
else
    echo "    ❌ GD NO activo en PHP de TAMP"
fi

# 7. Reiniciar servicios
echo ""
echo "[7] Reiniciando servicios..."

pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
pkill -f "pyftpdlib" 2>/dev/null
sleep 2

if [ -f "$HOME/iniciarservicios" ]; then
    bash "$HOME/iniciarservicios"
else
    apachectl start 2>/dev/null
    mysqld_safe --user=root &
fi

echo "    ✅ Servicios reiniciados"

# 8. Crear archivo de prueba
echo ""
echo "[8] Creando archivo de prueba..."

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

echo "    ✅ gd_test.php creado"

# 9. Verificar
echo ""
echo "[9] Verificando GD en el servidor..."

sleep 2
$TAMP_PHP /sdcard/htdocs/devmx/bordamex/gd_test.php

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""
echo "📋 Si ves GD: ✅ SI, tus archivos PHP originales"
echo "   funcionarán sin modificar"
echo ""