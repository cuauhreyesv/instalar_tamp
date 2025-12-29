#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# CONFIGURADOR DEFINITIVO ZONA HORARIA PHP
# Para Termux/TAMP Server
# ============================================

echo "🔧 CONFIGURACIÓN DEFINITIVA PHP - GMT-6"

# 1. DETENER APACHE (temporalmente)
echo "⏸️  Deteniendo Apache..."
apachectl stop 2>/dev/null || pkill -f httpd
sleep 2

# 2. CONFIGURAR ARCHIVOS php.ini
echo "📄 Configurando archivos php.ini..."

# Lista de posibles ubicaciones
PHP_INI_PATHS=(
    "/data/data/com.termux/files/usr/etc/php.ini"
    "/data/data/com.termux/files/usr/lib/php.ini"
    "/data/data/com.termux/files/usr/php.ini"
    "$HOME/tamp-cuauh/php.ini"
    "$HOME/tamp-cuauh/apache/php.ini"
    "/sdcard/php.ini"
)

for php_ini in "${PHP_INI_PATHS[@]}"; do
    if [ -f "$php_ini" ]; then
        echo "   🔧 Procesando: $php_ini"
        # Backup
        cp "$php_ini" "${php_ini}.backup"
        # Configurar
        sed -i 's/^;*date.timezone.*/date.timezone = America\/Mexico_City/' "$php_ini"
        echo "   ✅ Configurado"
    else
        # Si no existe, crear
        echo "   📝 Creando: $php_ini"
        mkdir -p "$(dirname "$php_ini")"
        echo "[PHP]" > "$php_ini"
        echo "date.timezone = America/Mexico_City" >> "$php_ini"
        echo "   ✅ Creado"
    fi
done

# 3. CREAR .user.ini EN DIRECTORIOS ESTRATÉGICOS
echo "🌐 Creando .user.ini..."
DIRECTORIOS_WEB=(
    "/sdcard/htdocs"
    "/storage/emulated/0/htdocs"
    "$HOME/tamp-cuauh/apache/htdocs"
    "/data/data/com.termux/files/usr/share/apache2/htdocs"
)

for dir in "${DIRECTORIOS_WEB[@]}"; do
    if [ -d "$dir" ]; then
        echo "date.timezone = America/Mexico_City" > "$dir/.user.ini"
        echo "   ✅ $dir/.user.ini"
        
        # También en subdirectorios importantes
        find "$dir" -type d -name "hotelsoft" -exec sh -c 'echo "date.timezone = America/Mexico_City" > "$1/.user.ini"' _ {} \;
    fi
done

# 4. CONFIGURAR PHP CLI TAMBIÉN
echo "💻 Configurando PHP CLI..."
echo "export PHP_INI_SCAN_DIR=\"/data/data/com.termux/files/usr/etc/php.d:\${PHP_INI_SCAN_DIR}\"" >> ~/.bashrc
echo "alias php='php -d date.timezone=America/Mexico_City'" >> ~/.bashrc

# 5. REINICIAR APACHE
echo "🔄 Reiniciando Apache..."
apachectl start 2>/dev/null || httpd -k start
sleep 3

# 6. VERIFICACIÓN
echo ""
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════"

# Verificar PHP CLI
echo "🧪 PHP CLI:"
php -r "echo 'Zona horaria: ' . date_default_timezone_get() . '\n'; echo 'Fecha: ' . date('Y-m-d H:i:s') . '\n';"

# Verificar PHP via web
echo ""
echo "🌐 Creando test web..."
cat > /sdcard/htdocs/test-php-config.php << 'WEB_TEST'
<?php
echo "<h1>✅ Test Configuración PHP</h1>";
echo "<p><strong>Zona horaria:</strong> " . date_default_timezone_get() . "</p>";
echo "<p><strong>Fecha/Hora:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>Offset GMT:</strong> " . (date('Z') / 3600) . " horas</p>";
echo "<p><strong>Archivo php.ini cargado:</strong> " . php_ini_loaded_file() . "</p>";

// Test de zona horaria
$fecha_utc = gmdate('Y-m-d H:i:s');
$fecha_local = date('Y-m-d H:i:s');
echo "<p><strong>UTC:</strong> $fecha_utc</p>";
echo "<p><strong>Local (GMT-6):</strong> $fecha_local</p>";

// Diferencia
$diff = (strtotime($fecha_local) - strtotime($fecha_utc)) / 3600;
echo "<p><strong>Diferencia:</strong> $diff horas " . ($diff == -6 ? "✅ CORRECTO" : "❌ INCORRECTO") . "</p>";
?>
WEB_TEST

echo "📊 Test web creado: http://192.168.1.200:8080/test-php-config.php"
echo ""
echo "🎯 Si muestra -6 horas y fecha correcta, ¡CONFIGURACIÓN EXITOSA!"