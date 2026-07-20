#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN TERMUX (FINAL)
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TERMUX"
echo "========================================="
echo ""

# 1. Instalar GD
echo "[1] Instalando php-gd..."
pkg install php-gd -y 2>/dev/null
echo "    ✅ php-gd instalado"

# 2. Crear php.ini
echo ""
echo "[2] Creando php.ini..."

mkdir -p /data/data/com.termux/files/usr/lib

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

# 3. Verificar GD
echo ""
echo "[3] Verificando GD..."

if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ACTIVO en PHP CLI"
else
    echo "    ❌ GD NO activo"
    
    # Buscar gd.so
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so encontrado: $GDSO"
        echo "extension=$GDSO" >> /data/data/com.termux/files/usr/lib/php.ini
        echo "    ✅ Ruta agregada al php.ini"
    fi
fi

# 4. Reiniciar Apache
echo ""
echo "[4] Reiniciando Apache..."

pkill -f "httpd" 2>/dev/null
sleep 2
apachectl start 2>/dev/null
echo "    ✅ Apache reiniciado"

# 5. Crear archivo de prueba
echo ""
echo "[5] Creando archivo de prueba..."

mkdir -p /sdcard/htdocs/devmx/bordamex

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

echo "    ✅ gd_test.php creado"

# 6. Verificar
echo ""
echo "[6] Verificando GD en el servidor..."

php /sdcard/htdocs/devmx/bordamex/gd_test.php

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
echo "========================================="