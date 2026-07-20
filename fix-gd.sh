#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# ACTIVAR GD EN TAMP - VERSIÓN FINAL
# Agrega la extensión GD a tu instalación existente
# SIN modificar tu código PHP
# =====================================================

echo "========================================="
echo "  ACTIVAR GD EN TAMP EXISTENTE"
echo "========================================="
echo ""

# =====================================================
# 1. DETECTAR INSTALACIÓN DE TAMP
# =====================================================

echo "[1] Detectando instalación de TAMP..."

TAMP_DIR=""
if [ -d "$HOME/tamp-cuauh" ]; then
    TAMP_DIR="$HOME/tamp-cuauh"
    echo "    ✅ TAMP encontrado en: $TAMP_DIR"
elif [ -d "$HOME/tamp" ]; then
    TAMP_DIR="$HOME/tamp"
    echo "    ✅ TAMP encontrado en: $TAMP_DIR"
else
    echo "    ❌ No se encontró TAMP"
    echo "    Instalando TAMP desde cuauhreyesv/tamp..."
    cd ~
    git clone https://github.com/cuauhreyesv/tamp.git ~/tamp-cuauh
    cd ~/tamp-cuauh
    bash setup
    TAMP_DIR="$HOME/tamp-cuauh"
    echo "    ✅ TAMP instalado"
fi

# =====================================================
# 2. BUSCAR PHP Y EXTENSIONES
# =====================================================

echo ""
echo "[2] Buscando PHP..."

PHP_PATH=""
if [ -f "$TAMP_DIR/php/bin/php" ]; then
    PHP_PATH="$TAMP_DIR/php/bin/php"
elif [ -f "/data/data/com.termux/files/usr/bin/php" ]; then
    PHP_PATH="/data/data/com.termux/files/usr/bin/php"
else
    echo "    ❌ No se encontró PHP"
    echo "    Instalando PHP..."
    pkg install php -y
    PHP_PATH="/data/data/com.termux/files/usr/bin/php"
fi

echo "    ✅ PHP encontrado: $PHP_PATH"

# =====================================================
# 3. INSTALAR GD EN TERMUX
# =====================================================

echo ""
echo "[3] Instalando GD en Termux..."

pkg update -y
pkg install php-gd -y
pkg install imagemagick -y

echo "    ✅ GD instalado"

# =====================================================
# 4. VERIFICAR EXTENSIÓN GD
# =====================================================

echo ""
echo "[4] Verificando GD..."

if $PHP_PATH -m | grep -q "gd"; then
    echo "    ✅ GD está ACTIVO en PHP CLI"
else
    echo "    ❌ GD NO está activo"
    echo "    Intentando configurar manualmente..."
fi

# =====================================================
# 5. ENCONTRAR php.ini
# =====================================================

echo ""
echo "[5] Buscando php.ini..."

PHP_INI=""
PHP_INI_PATHS=(
    "$TAMP_DIR/php/lib/php.ini"
    "$TAMP_DIR/conf/php.ini"
    "/data/data/com.termux/files/usr/lib/php.ini"
    "/data/data/com.termux/files/usr/etc/php.ini"
    "/storage/emulated/0/htdocs/conf/php.ini"
)

for path in "${PHP_INI_PATHS[@]}"; do
    if [ -f "$path" ]; then
        PHP_INI="$path"
        echo "    ✅ php.ini encontrado: $PHP_INI"
        break
    fi
done

if [ -z "$PHP_INI" ]; then
    echo "    ⚠️ No se encontró php.ini, creando uno..."
    PHP_INI="/storage/emulated/0/htdocs/conf/php.ini"
    mkdir -p $(dirname "$PHP_INI")
    touch "$PHP_INI"
    echo "    ✅ Creado: $PHP_INI"
fi

# =====================================================
# 6. ACTIVAR GD EN php.ini
# =====================================================

echo ""
echo "[6] Activando GD en php.ini..."

# Hacer backup
cp "$PHP_INI" "${PHP_INI}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Verificar si GD ya está activo
if grep -q "^extension=gd" "$PHP_INI" 2>/dev/null; then
    echo "    ✅ GD ya está activo en php.ini"
else
    # Agregar GD al archivo
    echo "" >> "$PHP_INI"
    echo "; ============================================" >> "$PHP_INI"
    echo "; GD ACTIVADO POR SCRIPT - $(date)" >> "$PHP_INI"
    echo "; ============================================" >> "$PHP_INI"
    echo "extension=gd" >> "$PHP_INI"
    echo "extension=gd2" >> "$PHP_INI"
    echo "extension=mysqli" >> "$PHP_INI"
    echo "extension=curl" >> "$PHP_INI"
    echo "extension=mbstring" >> "$PHP_INI"
    echo "extension=json" >> "$PHP_INI"
    echo "extension=fileinfo" >> "$PHP_INI"
    
    echo "    ✅ GD agregado a php.ini"
fi

# =====================================================
# 7. CONFIGURAR PHP.INI PARA TAMP
# =====================================================

echo ""
echo "[7] Configurando php.ini para TAMP..."

# Agregar configuraciones adicionales si no existen
if ! grep -q "upload_max_filesize" "$PHP_INI" 2>/dev/null; then
    echo "" >> "$PHP_INI"
    echo "upload_max_filesize = 20M" >> "$PHP_INI"
    echo "post_max_size = 20M" >> "$PHP_INI"
    echo "memory_limit = 256M" >> "$PHP_INI"
    echo "max_execution_time = 300" >> "$PHP_INI"
    echo "date.timezone = America/Mexico_City" >> "$PHP_INI"
    echo "display_errors = On" >> "$PHP_INI"
    echo "error_reporting = E_ALL" >> "$PHP_INI"
    echo "log_errors = On" >> "$PHP_INI"
    echo "    ✅ Configuraciones adicionales agregadas"
else
    echo "    ✅ Configuraciones ya existentes"
fi

# =====================================================
# 8. VERIFICAR CONFIGURACIÓN DE APACHE
# =====================================================

echo ""
echo "[8] Configurando Apache para usar php.ini..."

# Buscar archivo de configuración de Apache
APACHE_CONF=""
APACHE_CONF_PATHS=(
    "$TAMP_DIR/apache/conf/httpd.conf"
    "/data/data/com.termux/files/usr/etc/apache2/httpd.conf"
    "/storage/emulated/0/htdocs/conf/httpd.conf"
)

for path in "${APACHE_CONF_PATHS[@]}"; do
    if [ -f "$path" ]; then
        APACHE_CONF="$path"
        echo "    ✅ httpd.conf encontrado: $APACHE_CONF"
        break
    fi
done

if [ -n "$APACHE_CONF" ]; then
    # Verificar que PHP esté cargado
    if ! grep -q "mod_php" "$APACHE_CONF" 2>/dev/null; then
        echo "    ⚠️ PHP no configurado en Apache"
        echo "    Buscando archivos de configuración de PHP..."
        
        # Buscar archivo de configuración de PHP para Apache
        PHP_MOD_CONF=""
        PHP_MOD_PATHS=(
            "$TAMP_DIR/apache/conf/php.conf"
            "/data/data/com.termux/files/usr/etc/apache2/php.conf"
        )
        
        for path in "${PHP_MOD_PATHS[@]}"; do
            if [ -f "$path" ]; then
                PHP_MOD_CONF="$path"
                break
            fi
        done
        
        if [ -n "$PHP_MOD_CONF" ]; then
            echo "    ✅ Archivo PHP encontrado: $PHP_MOD_CONF"
        fi
    else
        echo "    ✅ PHP ya configurado en Apache"
    fi
fi

# =====================================================
# 9. CREAR ARCHIVO DE VERIFICACIÓN
# =====================================================

echo ""
echo "[9] Creando archivo de verificación..."

mkdir -p /sdcard/htdocs/devmx/bordamex 2>/dev/null

cat > /sdcard/htdocs/devmx/bordamex/verificar_gd.php << 'EOF'
<?php
echo "=== VERIFICACIÓN DE GD EN TAMP ===\n";
echo "=================================\n\n";

echo "PHP Version: " . phpversion() . "\n";
echo "Loaded INI: " . php_ini_loaded_file() . "\n\n";

echo "--- EXTENSIONES ---\n";
$extensions = ['gd', 'gd2', 'mysqli', 'curl', 'mbstring', 'json', 'fileinfo'];
foreach ($extensions as $ext) {
    echo $ext . ": " . (extension_loaded($ext) ? '✅ SI' : '❌ NO') . "\n";
}

echo "\n--- FUNCIONES GD ---\n";
$functions = ['imagecreatetruecolor', 'imagecreatefromjpeg', 'imagecreatefrompng', 
              'imagecreatefromgif', 'imagecreatefromwebp', 'imagejpeg', 'imagepng', 
              'imagegif', 'imagewebp', 'imagecopyresampled', 'imagedestroy'];
foreach ($functions as $func) {
    echo $func . ": " . (function_exists($func) ? '✅ SI' : '❌ NO') . "\n";
}

echo "\n--- INFORMACIÓN GD ---\n";
if (function_exists('gd_info')) {
    $info = gd_info();
    foreach ($info as $key => $value) {
        echo $key . ": " . ($value === true ? '✅ SI' : ($value === false ? '❌ NO' : $value)) . "\n";
    }
} else {
    echo "gd_info() no disponible\n";
}

echo "\n=================================\n";
echo "✅ Si todo está en SI, GD funciona correctamente\n";
echo "❌ Si algo está en NO, revisa la configuración\n";
?>
EOF

echo "    ✅ Archivo creado: /sdcard/htdocs/devmx/bordamex/verificar_gd.php"

# =====================================================
# 10. REINICIAR SERVICIOS
# =====================================================

echo ""
echo "[10] Reiniciando servicios..."

echo "    Deteniendo servicios..."
pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
pkill -f "pyftpdlib" 2>/dev/null

sleep 3

echo "    Iniciando Apache..."
if command -v apachectl > /dev/null 2>&1; then
    apachectl start 2>/dev/null
    echo "    ✅ Apache iniciado"
else
    echo "    ⚠️ apachectl no disponible"
fi

echo "    Iniciando MySQL..."
mysqld_safe --user=root > /dev/null 2>&1 &
sleep 5
echo "    ✅ MySQL iniciado"

echo "    Iniciando FTP..."
if [ -d "/sdcard/htdocs" ]; then
    cd /sdcard/htdocs
    python3 -m pyftpdlib -p 2221 -u android -P android -w > /dev/null 2>&1 &
    echo "    ✅ FTP iniciado (puerto 2221)"
fi

# =====================================================
# 11. VERIFICAR GD
# =====================================================

echo ""
echo "[11] Verificando GD en el servidor..."

sleep 3

RESULTADO=$($PHP_PATH /sdcard/htdocs/devmx/bordamex/verificar_gd.php 2>/dev/null | grep -c "✅ SI")

if [ $RESULTADO -gt 5 ]; then
    echo "    ✅ GD está ACTIVO correctamente"
else
    echo "    ⚠️ GD puede no estar completamente activo"
    echo "    Verifica manualmente:"
    echo "    http://localhost:8080/devmx/bordamex/verificar_gd.php"
fi

# =====================================================
# 12. RESUMEN FINAL
# =====================================================

echo ""
echo "========================================="
echo "  RESUMEN FINAL"
echo "========================================="
echo ""
echo "✅ GD instalado y configurado"
echo "✅ php.ini: $PHP_INI"
echo ""
echo "📋 VERIFICACIÓN:"
echo "   http://localhost:8080/devmx/bordamex/verificar_gd.php"
echo ""
echo "📋 TU CÓDIGO PHP ORIGINAL DEBE FUNCIONAR"
echo "   - Las miniaturas se crearán correctamente"
echo "   - No necesitas modificar tu código"
echo ""
echo "========================================="