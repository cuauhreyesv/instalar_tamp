#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# INSTALAR GD MANUALMENTE EN TERMUX
# =====================================================

echo "========================================="
echo "  INSTALAR GD MANUALMENTE"
echo "========================================="
echo ""

# 1. Instalar dependencias
echo "[1] Instalando dependencias..."

pkg update -y
pkg install -y autoconf automake libtool pkg-config make
pkg install -y php-dev
pkg install -y libpng libjpeg-turbo libwebp libtiff freetype

echo "    ✅ Dependencias instaladas"

# 2. Descargar y compilar GD
echo ""
echo "[2] Descargando y compilando GD..."

cd /tmp
rm -rf gd-src 2>/dev/null

# Clonar el repositorio de GD
git clone --depth 1 https://github.com/libgd/libgd gd-src
cd gd-src

# Compilar
./bootstrap.sh 2>/dev/null

./configure --prefix=/data/data/com.termux/files/usr \
            --enable-shared \
            --disable-static \
            --with-png=/data/data/com.termux/files/usr \
            --with-jpeg=/data/data/com.termux/files/usr \
            --with-webp=/data/data/com.termux/files/usr \
            --with-tiff=/data/data/com.termux/files/usr \
            --with-freetype=/data/data/com.termux/files/usr 2>/dev/null

make -j$(nproc) 2>/dev/null
make install 2>/dev/null

echo "    ✅ GD compilado e instalado"

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
    echo "    Intentando compilar con phpize..."
    
    # Intentar compilar como extensión PHP
    cd /tmp
    rm -rf php-gd-src 2>/dev/null
    git clone --depth 1 https://github.com/php/php-src
    cd php-src/ext/gd
    
    phpize
    ./configure --with-gd
    make
    make install
    
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so compilado como extensión: $GDSO"
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
    echo "    ✅ php.ini creado con ruta de gd.so"
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
    echo "    ✅ php.ini creado"
fi

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
    php -r "echo dl('gd.so') ? '✅ GD cargado' : '❌ GD no cargado';"
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

# 7. Crear archivo de prueba
echo ""
echo "[7] Creando archivo de prueba..."

cat > /sdcard/htdocs/devmx/bordamex/gd_test.php << 'EOF'
<?php
echo "=== GD EN TAMP ===\n";
echo "PHP: " . phpversion() . "\n";
echo "INI: " . php_ini_loaded_file() . "\n";
echo "GD: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromjpeg: " . (function_exists('imagecreatefromjpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagejpeg: " . (function_exists('imagejpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "\n--- Extensiones ---\n";
$exts = get_loaded_extensions();
sort($exts);
foreach ($exts as $ext) {
    echo $ext . "\n";
}
?>
EOF

echo "    ✅ gd_test.php creado"

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""