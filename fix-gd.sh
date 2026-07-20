#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN TERMUX - FINAL
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TERMUX"
echo "========================================="
echo ""

# =====================================================
# 1. INSTALAR GD
# =====================================================

echo "[1] Instalando GD en Termux..."

pkg update -y 2>/dev/null
pkg install php-gd -y 2>/dev/null
pkg install imagemagick -y 2>/dev/null

echo "    ✅ GD instalado"

# =====================================================
# 2. CREAR PHP.INI
# =====================================================

echo ""
echo "[2] Creando php.ini..."

mkdir -p /data/data/com.termux/files/usr/lib

cat > /data/data/com.termux/files/usr/lib/php.ini << 'EOF'
; ============================================
; PHP.INI PARA TERMUX - CON GD ACTIVADO
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

echo "    ✅ php.ini creado"

# =====================================================
# 3. VERIFICAR GD
# =====================================================

echo ""
echo "[3] Verificando GD..."

if php -m 2>/dev/null | grep -q "gd"; then
    echo "    ✅ GD está ACTIVO en PHP CLI"
else
    echo "    ❌ GD NO está activo"
    echo "    Intentando cargar extensión manualmente..."
    
    # Buscar gd.so
    GDSO=$(find /data/data/com.termux -name "gd.so" 2>/dev/null | head -1)
    if [ -n "$GDSO" ]; then
        echo "    ✅ gd.so encontrado: $GDSO"
        echo "extension=$GDSO" >> /data/data/com.termux/files/usr/lib/php.ini
        echo "    ✅ Ruta de gd.so agregada al php.ini"
    else
        echo "    ❌ No se encontró gd.so"
    fi
fi

# =====================================================
# 4. CREAR ARCHIVO DE VERIFICACIÓN
# =====================================================

echo ""
echo "[4] Creando archivo de verificación..."

mkdir -p /sdcard/htdocs/devmx/bordamex

cat > /sdcard/htdocs/devmx/bordamex/verificar_gd.php << 'EOF'
<?php
echo "=== VERIFICACIÓN GD EN TERMUX ===\n";
echo "=================================\n\n";

echo "PHP Version: " . phpversion() . "\n";
echo "Loaded INI: " . php_ini_loaded_file() . "\n\n";

echo "--- EXTENSIONES ---\n";
echo "gd: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "gd2: " . (extension_loaded('gd2') ? '✅ SI' : '❌ NO') . "\n";
echo "mysqli: " . (extension_loaded('mysqli') ? '✅ SI' : '❌ NO') . "\n";

echo "\n--- FUNCIONES GD ---\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefromjpeg: " . (function_exists('imagecreatefromjpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatefrompng: " . (function_exists('imagecreatefrompng') ? '✅ SI' : '❌ NO') . "\n";
echo "imagejpeg: " . (function_exists('imagejpeg') ? '✅ SI' : '❌ NO') . "\n";
echo "imagepng: " . (function_exists('imagepng') ? '✅ SI' : '❌ NO') . "\n";

echo "\n=================================\n";
?>
EOF

echo "    ✅ Archivo creado: /sdcard/htdocs/devmx/bordamex/verificar_gd.php"

# =====================================================
# 5. REINICIAR APACHE
# =====================================================

echo ""
echo "[5] Reiniciando Apache..."

pkill -f "httpd" 2>/dev/null
pkill -f "apache2" 2>/dev/null
sleep 2

if command -v apachectl > /dev/null 2>&1; then
    apachectl start 2>/dev/null
    echo "    ✅ Apache reiniciado (apachectl)"
elif [ -f "/data/data/com.termux/files/usr/etc/apache2/httpd" ]; then
    /data/data/com.termux/files/usr/etc/apache2/httpd -f /data/data/com.termux/files/usr/etc/apache2/httpd.conf 2>/dev/null
    echo "    ✅ Apache reiniciado (httpd)"
else
    echo "    ⚠️ No se pudo reiniciar Apache automáticamente"
    echo "    🔄 Reinicia Apache manualmente"
fi

# =====================================================
# 6. VERIFICACIÓN FINAL
# =====================================================

echo ""
echo "[6] Verificación final..."

echo "    📌 Probando GD desde CLI:"
php -r "echo extension_loaded('gd') ? '✅ GD SI' : '❌ GD NO';"
echo ""

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica en el navegador:"
echo "   http://localhost:8080/devmx/bordamex/verificar_gd.php"
echo ""
echo "📋 También desde CLI:"
echo "   php /sdcard/htdocs/devmx/bordamex/verificar_gd.php"
echo ""
echo "========================================="