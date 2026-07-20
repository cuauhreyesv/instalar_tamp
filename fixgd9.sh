#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# INSTALAR GD EN TERMUX - DEFINITIVO
# =====================================================

echo "========================================="
echo "  INSTALAR GD EN TERMUX"
echo "========================================="
echo ""

# 1. Buscar e instalar php-gd
echo "[1] Instalando php-gd..."

# Intentar con pkg
pkg install php-gd -y 2>/dev/null

# Si falla, intentar con apt
apt install php-gd -y 2>/dev/null

# 2. Buscar gd.so
echo ""
echo "[2] Buscando gd.so..."

GDSO=""
# Buscar en varias ubicaciones
GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
if [ -z "$GDSO" ]; then
    GDSO=$(find / -name "gd.so" 2>/dev/null | head -1)
fi

if [ -n "$GDSO" ]; then
    echo "    ✅ gd.so encontrado: $GDSO"
else
    echo "    ❌ No se encontró gd.so"
    echo ""
    echo "    📌 Instalando php-gd desde compilación..."
    
    # Instalar dependencias de compilación
    pkg install -y autoconf automake libtool pkg-config make
    pkg install -y php-dev
    pkg install -y libgd libpng libjpeg-turbo libwebp libtiff freetype
    
    # Descargar y compilar GD
    cd /tmp
    rm -rf gd-src 2>/dev/null
    git clone --depth 1 https://github.com/libgd/libgd gd-src
    cd gd-src
    
    ./bootstrap.sh 2>/dev/null
    ./configure --prefix=/data/data/com.termux/files/usr \
                --enable-shared \
                --with-png \
                --with-jpeg \
                --with-webp \
                --with-tiff \
                --with-freetype 2>/dev/null
    
    make -j$(nproc) 2>/dev/null
    make install 2>/dev/null
    
    # Buscar gd.so compilado
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so compilado: $GDSO"
    else
        echo "    ❌ No se pudo compilar GD"
    fi
fi

# 3. Actualizar php.ini con la ruta correcta
echo ""
echo "[3] Actualizando php.ini..."

if [ -n "$GDSO" ]; then
    # Crear php.ini con la ruta exacta
    cat > /data/data/com.termux/files/usr/lib/php.ini << EOF
extension=$GDSO
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
    echo "    ✅ php.ini actualizado con ruta de gd.so"
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
    echo "    ✅ php.ini creado (sin ruta específica)"
fi

# 4. Verificar GD
echo ""
echo "[4] Verificando GD..."

if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP CLI"
    php -r "echo 'GD version: ' . gd_info()['GD Version'] . '\n';"
else
    echo "    ❌ GD NO activo"
    echo ""
    echo "    📌 Intentando cargar manualmente..."
    
    # Intentar cargar con dl()
    php -r "dl('gd.so'); echo extension_loaded('gd') ? '✅ GD cargado' : '❌ GD no cargado';" 2>/dev/null
fi

# 5. Verificar en el servidor web
echo ""
echo "[5] Verificando en el servidor web..."

# Crear archivo de prueba simple
cat > /sdcard/htdocs/devmx/bordamex/gd_test.php << 'EOF'
<?php
echo "=== GD EN TAMP ===\n";
echo "PHP: " . phpversion() . "\n";
echo "INI: " . php_ini_loaded_file() . "\n";
echo "GD: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromjpeg: " . (function_exists('imagecreatefromjpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagejpeg: " . (function_exists('imagejpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "\n--- Extensiones cargadas ---\n";
$exts = get_loaded_extensions();
sort($exts);
echo implode(', ', $exts) . "\n";
?>
EOF

echo "    ✅ gd_test.php creado"

# 6. Reiniciar servicios
echo ""
echo "[6] Reiniciando servicios..."

pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
sleep 2

apachectl start 2>/dev/null
mysqld_safe --user=root &

echo "    ✅ Servicios reiniciados"

# 7. Resumen
echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""
echo "📋 Si aún ves GD: ❌ NO, ejecuta:"
echo "   php -m | grep gd"
echo "   php -r 'phpinfo();' | grep gd"
echo ""
echo "📋 Si GD no aparece, instala ImageMagick:"
echo "   pkg install imagemagick"
echo "   Y modifica tu código para usar ImageMagick"
echo ""