#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# SOLUCIÓN NUCLEAR - FORZAR GD EN TAMP
# =====================================================

echo "========================================="
echo "  SOLUCIÓN NUCLEAR - GD EN TAMP"
echo "========================================="
echo ""

# 1. Repositorio correcto
echo "[1] Configurando repositorio..."
echo "deb https://packages.termux.org/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
apt update -y
echo "    ✅ Repositorio configurado"

# 2. Instalar PHP completo
echo ""
echo "[2] Instalando PHP completo..."
pkg install -y php php-gd php-mysqli php-curl php-mbstring php-json php-fileinfo
echo "    ✅ PHP instalado"

# 3. Verificar GD
echo ""
echo "[3] Verificando GD..."
if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP CLI"
else
    echo "    ❌ GD NO activo - intentando compilar..."
    
    # Compilar GD
    pkg install -y autoconf automake libtool pkg-config make php-dev
    pkg install -y libpng libjpeg-turbo libwebp libtiff freetype
    
    cd /tmp
    rm -rf gd-src
    git clone --depth 1 https://github.com/libgd/libgd gd-src
    cd gd-src
    
    ./bootstrap.sh 2>/dev/null
    ./configure --prefix=/data/data/com.termux/files/usr --enable-shared --with-png --with-jpeg --with-webp --with-tiff --with-freetype 2>/dev/null
    make -j$(nproc) 2>/dev/null
    make install 2>/dev/null
    
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    if [ -n "$GDSO" ]; then
        echo "extension=$GDSO" > /data/data/com.termux/files/usr/lib/php.ini
        echo "    ✅ GD compilado e instalado"
    fi
fi

# 4. Crear php.ini
echo ""
echo "[4] Creando php.ini..."
mkdir -p /data/data/com.termux/files/usr/lib

if [ -n "$GDSO" ]; then
    cat > /data/data/com.termux/files/usr/lib/php.ini << EOF
extension=$GDSO
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
else
    cat > /data/data/com.termux/files/usr/lib/php.ini << 'EOF'
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
fi

echo "    ✅ php.ini creado"

# 5. Enlazar PHP de TAMP
echo ""
echo "[5] Enlazando PHP de TAMP..."
TAMP_PHP="$HOME/tamp-cuauh/php/bin/php"
if [ -f "$TAMP_PHP" ]; then
    mv "$TAMP_PHP" "${TAMP_PHP}.original" 2>/dev/null
    ln -sf /data/data/com.termux/files/usr/bin/php "$TAMP_PHP"
    echo "    ✅ PHP de TAMP enlazado"
fi

# 6. Configurar Apache
echo ""
echo "[6] Configurando Apache..."
HTTPD_CONF="$HOME/tamp-cuauh/apache/conf/httpd.conf"
if [ -f "$HTTPD_CONF" ]; then
    if ! grep -q "PHPRC" "$HTTPD_CONF" 2>/dev/null; then
        echo "" >> "$HTTPD_CONF"
        echo "# PHP Configuration" >> "$HTTPD_CONF"
        echo "SetEnv PHPRC /data/data/com.termux/files/usr/lib/" >> "$HTTPD_CONF"
        echo "SetEnv PHP_INI_SCAN_DIR /data/data/com.termux/files/usr/lib/" >> "$HTTPD_CONF"
        echo "    ✅ Apache configurado"
    else
        echo "    ✅ Apache ya configurado"
    fi
fi

# 7. Reiniciar
echo ""
echo "[7] Reiniciando servicios..."
pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
sleep 2
apachectl start 2>/dev/null
mysqld_safe --user=root &
echo "    ✅ Servicios reiniciados"

# 8. Verificar
echo ""
echo "[8] Verificando GD en el servidor..."

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
echo "📋 Si ves GD: ✅ SI, tus archivos PHP originales"
echo "   funcionarán en TAMP sin modificar"
echo ""