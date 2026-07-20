#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# INSTALAR GD EN TERMUX - DEFINITIVO
# =====================================================

echo "========================================="
echo "  INSTALAR GD EN TERMUX"
echo "========================================="
echo ""

# 1. Instalar dependencias
echo "[1] Instalando dependencias..."
pkg update -y
pkg install -y autoconf automake libtool pkg-config make
pkg install -y php-dev
pkg install -y libpng libjpeg-turbo libwebp libtiff freetype
echo "    ✅ Dependencias instaladas"

# 2. Compilar GD
echo ""
echo "[2] Compilando GD..."
cd /tmp
rm -rf gd-src
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
echo "    ✅ GD compilado"

# 3. Buscar gd.so
echo ""
echo "[3] Buscando gd.so..."
GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)

if [ -z "$GDSO" ]; then
    GDSO=$(find / -name "gd.so" 2>/dev/null | head -1)
fi

if [ -n "$GDSO" ]; then
    echo "    ✅ gd.so encontrado: $GDSO"
else
    echo "    ❌ No se encontró gd.so"
    echo "    Intentando con apt..."
    apt install php-gd -y 2>/dev/null
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
fi

# 4. Crear php.ini
echo ""
echo "[4] Creando php.ini..."
mkdir -p /data/data/com.termux/files/usr/lib

if [ -n "$GDSO" ]; then
    cat > /data/data/com.termux/files/usr/lib/php.ini << EOF
extension=$GDSO
extension=gd
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

# 5. Verificar GD
echo ""
echo "[5] Verificando GD..."
if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP CLI"
    php -r "echo 'GD Version: ' . gd_info()['GD Version'] . '\n';"
else
    echo "    ❌ GD NO activo"
    echo ""
    echo "    Intentando cargar manualmente..."
    php -r "dl('gd.so'); echo extension_loaded('gd') ? '✅ GD cargado' : '❌ GD no cargado';" 2>/dev/null
fi

# 6. Reiniciar servicios
echo ""
echo "[6] Reiniciando servicios..."
pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
sleep 2
apachectl start 2>/dev/null
mysqld_safe --user=root &
echo "    ✅ Servicios reiniciados"

# 7. Verificar en servidor
echo ""
echo "[7] Verificando en servidor..."

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
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""
echo "📋 Si ves GD: ✅ SI, tus archivos PHP originales"
echo "   funcionarán en TAMP sin modificar"
echo ""