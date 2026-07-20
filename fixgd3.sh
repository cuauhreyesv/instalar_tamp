#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# COMPILAR GD PARA TERMUX (CUANDO NO ESTÁ EN REPOSITORIO)
# =====================================================

echo "========================================="
echo "  COMPILAR GD PARA TERMUX"
echo "========================================="
echo ""

# 1. Instalar dependencias de compilación
echo "[1] Instalando dependencias..."

pkg update -y
pkg install -y autoconf automake libtool pkg-config make
pkg install -y php-dev
pkg install -y libgd
pkg install -y libpng libjpeg-turbo libwebp libtiff freetype

echo "    ✅ Dependencias instaladas"

# 2. Crear directorio de trabajo
echo ""
echo "[2] Descargando código fuente de GD..."

cd /tmp
rm -rf gd-src 2>/dev/null
git clone --depth 1 https://github.com/libgd/libgd gd-src
cd gd-src

echo "    ✅ Código descargado"

# 3. Compilar GD
echo ""
echo "[3] Compilando GD..."

./bootstrap.sh 2>/dev/null
./configure --prefix=/data/data/com.termux/files/usr \
            --enable-shared \
            --disable-static \
            --with-png \
            --with-jpeg \
            --with-webp \
            --with-tiff \
            --with-freetype 2>/dev/null

make -j$(nproc) 2>/dev/null
make install 2>/dev/null

echo "    ✅ GD compilado"

# 4. Crear php.ini
echo ""
echo "[4] Creando php.ini..."

mkdir -p /data/data/com.termux/files/usr/lib

cat > /data/data/com.termux/files/usr/lib/php.ini << 'EOF'
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

echo "    ✅ php.ini creado"

# 5. Verificar GD
echo ""
echo "[5] Verificando GD..."

if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP CLI"
else
    echo "    ❌ GD NO activo - buscando alternativa..."
    
    # Buscar gd.so
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so encontrado: $GDSO"
        echo "extension=$GDSO" >> /data/data/com.termux/files/usr/lib/php.ini
        echo "    ✅ Ruta agregada al php.ini"
    fi
fi

# 6. Reiniciar Apache
echo ""
echo "[6] Reiniciando Apache..."

pkill -f "httpd" 2>/dev/null
pkill -f "apache2" 2>/dev/null
sleep 2

if command -v apachectl > /dev/null 2>&1; then
    apachectl start 2>/dev/null
    echo "    ✅ Apache reiniciado"
fi

# 7. Verificar en servidor
echo ""
echo "[7] Verificando GD en el servidor..."

cat > /sdcard/htdocs/devmx/bordamex/gd_test.php << 'EOF'
<?php
echo "=== GD EN TERMUX ===\n";
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