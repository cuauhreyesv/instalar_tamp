#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN TAMP - SIN MODIFICAR TUS PHP
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TAMP"
echo "========================================="
echo ""

# 1. Instalar php-gd
echo "[1] Instalando php-gd..."
pkg install php-gd -y 2>/dev/null

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
    echo "    ❌ GD NO activo - buscando gd.so..."
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so encontrado: $GDSO"
        echo "extension=$GDSO" >> /data/data/com.termux/files/usr/lib/php.ini
        echo "    ✅ Ruta agregada al php.ini"
    fi
fi

# 4. Configurar variables de entorno para Apache
echo ""
echo "[4] Configurando Apache..."

# Crear script de inicio con variables de entorno
cat > ~/start_services_with_gd.sh << 'START_EOF'
#!/data/data/com.termux/files/usr/bin/bash
export PHPRC=/data/data/com.termux/files/usr/lib/
export PHP_INI_SCAN_DIR=/data/data/com.termux/files/usr/lib/

pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
pkill -f "pyftpdlib" 2>/dev/null
sleep 2

apachectl start 2>/dev/null
mysqld_safe --user=root &
cd /sdcard/htdocs
python3 -m pyftpdlib -p 2221 -u android -P android -w &
echo "✅ Servicios con GD activos"
START_EOF

chmod +x ~/start_services_with_gd.sh

# 5. Reiniciar con GD
echo ""
echo "[5] Reiniciando servicios con GD..."
~/start_services_with_gd.sh

# 6. Verificar
echo ""
echo "[6] Verificando GD en el servidor..."

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
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""
echo "📋 Si ves GD: ✅ SI, tus archivos PHP originales"
echo "   funcionarán sin modificar"
echo ""