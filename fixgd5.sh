# =====================================================
# FORZAR GD EN TAMP - SOLUCIÓN MANUAL
# =====================================================

# 1. Encontrar el PHP real de TAMP
echo "[1] Buscando PHP de TAMP..."
TAMP_PHP=""
if [ -f "$HOME/tamp-cuauh/php/bin/php" ]; then
    TAMP_PHP="$HOME/tamp-cuauh/php/bin/php"
elif [ -f "$HOME/tamp/php/bin/php" ]; then
    TAMP_PHP="$HOME/tamp/php/bin/php"
else
    echo "❌ No se encontró PHP de TAMP"
    exit 1
fi
echo "✅ PHP de TAMP: $TAMP_PHP"

# 2. Verificar GD en PHP de TAMP
echo ""
echo "[2] Verificando GD en PHP de TAMP..."
if $TAMP_PHP -m 2>/dev/null | grep -q "gd"; then
    echo "✅ GD ya está activo"
    exit 0
else
    echo "❌ GD NO está activo"
fi

# 3. Buscar gd.so en el sistema
echo ""
echo "[3] Buscando gd.so..."
GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
if [ -z "$GDSO" ]; then
    GDSO=$(find / -name "gd.so" 2>/dev/null | head -1)
fi

if [ -z "$GDSO" ]; then
    echo "❌ No se encontró gd.so"
    echo "Instalando php-gd en Termux..."
    pkg install php-gd -y
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
fi

if [ -n "$GDSO" ]; then
    echo "✅ gd.so encontrado: $GDSO"
else
    echo "❌ No se pudo encontrar gd.so"
    exit 1
fi

# 4. Crear php.ini para TAMP
echo ""
echo "[4] Creando php.ini para TAMP..."
mkdir -p ~/tamp-cuauh/php/lib

cat > ~/tamp-cuauh/php/lib/php.ini << 'EOF'
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

echo "✅ php.ini creado"

# 5. Forzar el php.ini en Apache
echo ""
echo "[5] Configurando Apache para usar php.ini..."

# Buscar httpd.conf
HTTPD_CONF=""
if [ -f ~/tamp-cuauh/apache/conf/httpd.conf ]; then
    HTTPD_CONF=~/tamp-cuauh/apache/conf/httpd.conf
elif [ -f ~/tamp/apache/conf/httpd.conf ]; then
    HTTPD_CONF=~/tamp/apache/conf/httpd.conf
fi

if [ -n "$HTTPD_CONF" ]; then
    # Agregar configuración PHP
    echo "" >> "$HTTPD_CONF"
    echo "# PHP Configuration - GD" >> "$HTTPD_CONF"
    echo "SetEnv PHPRC ~/tamp-cuauh/php/lib/" >> "$HTTPD_CONF"
    echo "SetEnv PHP_INI_SCAN_DIR ~/tamp-cuauh/php/lib/" >> "$HTTPD_CONF"
    echo "✅ httpd.conf configurado"
else
    echo "⚠️ No se encontró httpd.conf"
fi

# 6. Crear script de inicio con variables de entorno
echo ""
echo "[6] Creando script de inicio con GD..."

cat > ~/start_tamp_with_gd.sh << 'START_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# INICIAR TAMP CON GD
# ============================================

# Configurar variables de entorno
export PHPRC=~/tamp-cuauh/php/lib/
export PHP_INI_SCAN_DIR=~/tamp-cuauh/php/lib/

# Detener servicios
pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
pkill -f "pyftpdlib" 2>/dev/null

sleep 2

# Iniciar Apache
apachectl start 2>/dev/null

# Iniciar MySQL
mysqld_safe --user=root &

# Iniciar FTP
cd /sdcard/htdocs
python3 -m pyftpdlib -p 2221 -u android -P android -w &

echo "✅ Servicios iniciados con GD"
echo "🌐 Web: http://localhost:8080"
START_EOF

chmod +x ~/start_tamp_with_gd.sh

# 7. Reiniciar servicios con GD
echo ""
echo "[7] Reiniciando servicios con GD..."

# Detener todo
pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
pkill -f "pyftpdlib" 2>/dev/null
sleep 2

# Iniciar con variables de entorno
export PHPRC=~/tamp-cuauh/php/lib/
export PHP_INI_SCAN_DIR=~/tamp-cuauh/php/lib/

apachectl start 2>/dev/null
mysqld_safe --user=root &
cd /sdcard/htdocs
python3 -m pyftpdlib -p 2221 -u android -P android -w &

echo "✅ Servicios reiniciados"

# 8. Verificar GD
echo ""
echo "[8] Verificando GD..."

# Probar con PHP CLI
echo "📌 Probando GD en PHP CLI:"
$TAMP_PHP -r "echo extension_loaded('gd') ? '✅ GD SI' : '❌ GD NO';"
echo ""

# Crear archivo de prueba
cat > /sdcard/htdocs/devmx/bordamex/gd_test.php << 'EOF'
<?php
echo "=== GD EN TAMP ===\n";
echo "PHP: " . phpversion() . "\n";
echo "INI: " . php_ini_loaded_file() . "\n";
echo "GD: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
?>
EOF

echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/gd_test.php"
echo ""
echo "📋 O desde CLI:"
echo "   $TAMP_PHP /sdcard/htdocs/devmx/bordamex/gd_test.php"