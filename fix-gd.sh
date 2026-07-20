#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN TAMP - VERSIÓN CORREGIDA
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TAMP - CORREGIDO"
echo "========================================="
echo ""

# =====================================================
# 1. ENCONTRAR PHP DE TAMP
# =====================================================

echo "[1] Buscando PHP de TAMP..."

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

echo "    ✅ PHP de TAMP: $TAMP_PHP"

# =====================================================
# 2. VERIFICAR GD EN PHP DE TAMP
# =====================================================

echo ""
echo "[2] Verificando GD en PHP de TAMP..."

if $TAMP_PHP -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD ya está activo en PHP de TAMP"
    exit 0
else
    echo "    ❌ GD NO está activo en PHP de TAMP"
    echo "    🔧 Instalando GD..."
fi

# =====================================================
# 3. INSTALAR GD EN TERMUX
# =====================================================

echo ""
echo "[3] Instalando GD en Termux..."

pkg update -y 2>/dev/null
pkg install php-gd -y 2>/dev/null
pkg install imagemagick -y 2>/dev/null

echo "    ✅ GD instalado en Termux"

# =====================================================
# 4. BUSCAR GD.SO
# =====================================================

echo ""
echo "[4] Buscando gd.so..."

GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)

if [ -z "$GDSO" ]; then
    GDSO=$(find / -name "gd.so" 2>/dev/null | head -1)
fi

if [ -n "$GDSO" ]; then
    echo "    ✅ gd.so encontrado: $GDSO"
else
    echo "    ❌ No se encontró gd.so"
    echo "    Intentando crear extensión manualmente..."
    exit 1
fi

# =====================================================
# 5. CREAR PHP.INI PARA TAMP
# =====================================================

echo ""
echo "[5] Creando php.ini para TAMP..."

mkdir -p $TAMP_DIR/php/lib

cat > $TAMP_DIR/php/lib/php.ini << 'EOF'
; ============================================
; PHP.INI PARA TAMP - CON GD
; ============================================

; EXTENSIONES
extension=gd
extension=gd2
extension=mysqli
extension=curl
extension=mbstring
extension=json
extension=fileinfo

; CONFIGURACIÓN
date.timezone = America/Mexico_City
upload_max_filesize = 20M
post_max_size = 20M
memory_limit = 256M
max_execution_time = 300
display_errors = On
error_reporting = E_ALL
log_errors = On
error_log = /sdcard/htdocs/php_errors.log

; SUBIDA DE ARCHIVOS
file_uploads = On
EOF

echo "    ✅ php.ini creado en: $TAMP_DIR/php/lib/php.ini"

# =====================================================
# 6. COPIAR GD.SO A TAMP (SI ES NECESARIO)
# =====================================================

echo ""
echo "[6] Copiando gd.so a TAMP..."

mkdir -p $TAMP_DIR/php/lib/extensions

if [ -f "$GDSO" ]; then
    cp "$GDSO" $TAMP_DIR/php/lib/extensions/gd.so 2>/dev/null
    chmod 644 $TAMP_DIR/php/lib/extensions/gd.so
    echo "    ✅ gd.so copiado a TAMP"
    
    # Agregar ruta al php.ini
    echo "" >> $TAMP_DIR/php/lib/php.ini
    echo "extension=$TAMP_DIR/php/lib/extensions/gd.so" >> $TAMP_DIR/php/lib/php.ini
    echo "    ✅ Ruta de extensión agregada al php.ini"
fi

# =====================================================
# 7. VERIFICAR QUE PHP USA EL php.ini CORRECTO
# =====================================================

echo ""
echo "[7] Verificando configuración de PHP..."

# Crear script de prueba para verificar que el php.ini se carga
cat > /tmp/test_php_ini.php << 'EOF'
<?php
$ini = php_ini_loaded_file();
echo "INI: " . ($ini ? $ini : "NINGUNO") . "\n";
echo "GD: " . (extension_loaded('gd') ? "SI" : "NO") . "\n";
?>
EOF

echo "    📌 Probando PHP con php.ini..."
$TAMP_PHP -c $TAMP_DIR/php/lib/php.ini /tmp/test_php_ini.php

# =====================================================
# 8. CONFIGURAR APACHE PARA USAR EL php.ini
# =====================================================

echo ""
echo "[8] Configurando Apache para usar php.ini..."

# Buscar httpd.conf
APACHE_CONF=""
if [ -f "$TAMP_DIR/apache/conf/httpd.conf" ]; then
    APACHE_CONF="$TAMP_DIR/apache/conf/httpd.conf"
elif [ -f "/data/data/com.termux/files/usr/etc/apache2/httpd.conf" ]; then
    APACHE_CONF="/data/data/com.termux/files/usr/etc/apache2/httpd.conf"
fi

if [ -n "$APACHE_CONF" ]; then
    echo "    ✅ httpd.conf encontrado: $APACHE_CONF"
    
    # Verificar que el php.ini está configurado
    if ! grep -q "PHP_INI_SCAN_DIR" "$APACHE_CONF" 2>/dev/null; then
        echo "    📌 Agregando configuración PHP al httpd.conf..."
        
        cat >> "$APACHE_CONF" << 'APACHE_EOF'

# ============================================
# CONFIGURACIÓN PHP PARA TAMP
# ============================================
SetEnv PHP_INI_SCAN_DIR $TAMP_DIR/php/lib/
SetEnv PHPRC $TAMP_DIR/php/lib/
APACHE_EOF
        echo "    ✅ Configuración PHP agregada a Apache"
    else
        echo "    ✅ PHP ya configurado en Apache"
    fi
fi

# =====================================================
# 9. REINICIAR APACHE
# =====================================================

echo ""
echo "[9] Reiniciando Apache..."

pkill -f "httpd" 2>/dev/null
sleep 2

if [ -f "$TAMP_DIR/apache/bin/apachectl" ]; then
    $TAMP_DIR/apache/bin/apachectl start 2>/dev/null
    echo "    ✅ Apache reiniciado"
elif command -v apachectl > /dev/null 2>&1; then
    apachectl start 2>/dev/null
    echo "    ✅ Apache reiniciado"
fi

# =====================================================
# 10. VERIFICAR GD EN EL SERVIDOR
# =====================================================

echo ""
echo "[10] Verificando GD en el servidor..."

cat > /sdcard/htdocs/devmx/bordamex/verificar_gd.php << 'EOF'
<?php
echo "=== VERIFICACIÓN DE GD EN TAMP ===\n";
echo "=================================\n\n";

echo "PHP Version: " . phpversion() . "\n";
echo "Loaded INI: " . php_ini_loaded_file() . "\n\n";

echo "--- EXTENSIONES ---\n";
echo "gd: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "gd2: " . (extension_loaded('gd2') ? '✅ SI' : '❌ NO') . "\n";
echo "mysqli: " . (extension_loaded('mysqli') ? '✅ SI' : '❌ NO') . "\n";
echo "curl: " . (extension_loaded('curl') ? '✅ SI' : '❌ NO') . "\n";
echo "mbstring: " . (extension_loaded('mbstring') ? '✅ SI' : '❌ NO') . "\n";
echo "json: " . (extension_loaded('json') ? '✅ SI' : '❌ NO') . "\n";

echo "\n--- FUNCIONES GD ---\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromjpeg: " . (function_exists('imagecreatefromjpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefrompng: " . (function_exists('imagecreatefrompng') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromwebp: " . (function_exists('imagecreatefromwebp') ? '✅ SI' : '❌ NO') . "\n";
echo "imagejpeg: " . (function_exists('imagejpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagepng: " . (function_exists('imagepng') ? '✅ SI' : '❌ NO') . "\n";
echo "imagewebp: " . (function_exists('imagewebp') ? '✅ SI' : '❌ NO') . "\n";

echo "\n=================================\n";
?>
EOF

echo "    ✅ Archivo de verificación creado"

# =====================================================
# 11. VERIFICACIÓN FINAL
# =====================================================

echo ""
echo "[11] Verificación final..."

# Probar con el PHP de TAMP
echo "    📌 Probando con PHP de TAMP..."
$TAMP_PHP -c $TAMP_DIR/php/lib/php.ini /sdcard/htdocs/devmx/bordamex/verificar_gd.php

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/verificar_gd.php"
echo ""
echo "📋 Si GD aparece en ✅ SI, tu código PHP original funcionará"
echo ""
echo "========================================="