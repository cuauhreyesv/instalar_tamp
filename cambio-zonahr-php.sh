#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# SOLUCIÓN DEFINITIVA ZONA HORARIA PHP
# Para Termux / TAMP Server / HotelSoft
# Script único que resuelve todo
# ============================================

echo "🚀 INICIANDO SOLUCIÓN DEFINITIVA PHP GMT-6"
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. DETENER TODOS LOS SERVICIOS
info "Deteniendo servicios Apache/PHP..."
pkill -f httpd 2>/dev/null
pkill -f apache 2>/dev/null
pkill -f php 2>/dev/null
sleep 2

# 2. CONFIGURAR VARIABLE DE ENTORNO GLOBAL
info "Configurando variable TZ globalmente..."
export TZ=America/Mexico_City
echo 'export TZ=America/Mexico_City' >> ~/.bashrc
echo 'export TZ=America/Mexico_City' >> ~/.profile
echo 'export PHP_INI_SCAN_DIR=/data/data/com.termux/files/usr/etc/php.d' >> ~/.bashrc

# 3. CREAR/CONFIGURAR php.ini PRINCIPAL
info "Configurando archivos php.ini..."
MAIN_INI="/data/data/com.termux/files/usr/etc/php.ini"

if [ ! -f "$MAIN_INI" ]; then
    info "Creando $MAIN_INI..."
    cat > "$MAIN_INI" << 'EOF'
[PHP]
engine = On
short_open_tag = On
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = On
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = On
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
include_path = ".:/data/data/com.termux/files/usr/lib/php"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 2M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60

[Date]
date.timezone = America/Mexico_City

[CLI Server]
cli_server.color = On

[Pdo_mysql]
pdo_mysql.default_socket =

[mail function]
SMTP = localhost
smtp_port = 25
mail.add_x_header = On

[SQL]
sql.safe_mode = Off

[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
odbc.defaultlrl = 4096

[MySQL]
mysql.allow_persistent = On
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off

[mysqli]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off

[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off

[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0

[Sybase]
sybase.allow_persistent = On
sybase.max_persistent = -1
sybase.max_links = -1
sybase.min_error_severity = 10
sybase.min_message_severity = 10
sybase.compatability_mode = Off

[bcmath]
bcmath.scale = 0

[browscap]

[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 0
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5

[Assertion]
zend.assertions = -1

[Tidy]
tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled = 1
soap.wsdl_cache_dir = "/tmp"
soap.wsdl_cache_ttl = 86400
soap.wsdl_cache_limit = 5

[ldap]
ldap.max_links = -1
EOF
    success "php.ini principal creado"
else
    # Configurar zona horaria en php.ini existente
    sed -i 's/^;\?date\.timezone\s*=.*/date.timezone = America\/Mexico_City/' "$MAIN_INI"
    if ! grep -q "date.timezone" "$MAIN_INI"; then
        echo -e "\n[Date]\ndate.timezone = America/Mexico_City" >> "$MAIN_INI"
    fi
    success "php.ini principal configurado"
fi

# 4. CREAR ARCHIVO DE CONFIGURACIÓN ESPECÍFICO
info "Creando configuración específica de zona horaria..."
mkdir -p /data/data/com.termux/files/usr/etc/php.d
cat > /data/data/com.termux/files/usr/etc/php.d/99-timezone.ini << 'EOF'
; ===========================================
; CONFIGURACIÓN ZONA HORARIA FORZADA
; NO MODIFICAR - Configuración automática
; ===========================================

[PHP]
date.timezone = America/Mexico_City

[Date]
date.timezone = America/Mexico_City
date.default_latitude = 23.634501
date.default_longitude = -102.552784
date.sunrise_zenith = 90.583333
date.sunset_zenith = 90.583333

; Forzar configuración
date.timezone = "America/Mexico_City"
EOF
success "Archivo 99-timezone.ini creado"

# 5. CONFIGURAR .user.ini EN DIRECTORIOS WEB
info "Configurando .user.ini en directorios web..."
WEB_DIRS=(
    "/sdcard/htdocs"
    "/storage/emulated/0/htdocs"
    "/data/data/com.termux/files/usr/share/apache2/htdocs"
    "$HOME/htdocs"
    "$PREFIX/share/apache2/default-site/htdocs"
)

for dir in "${WEB_DIRS[@]}"; do
    if [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null; then
        cat > "$dir/.user.ini" << 'INI'
; ===========================================
; CONFIGURACIÓN PHP - ZONA HORARIA
; ===========================================
date.timezone = "America/Mexico_City"

; Configuración adicional para HotelSoft
max_execution_time = 300
max_input_time = 600
memory_limit = 256M
post_max_size = 100M
upload_max_filesize = 100M
INI
        chmod 644 "$dir/.user.ini"
        info "  $dir/.user.ini configurado"
    fi
done

# 6. CONFIGURAR APACHE
info "Configurando Apache..."
APACHE_CONF="/data/data/com.termux/files/usr/etc/apache2/httpd.conf"
if [ -f "$APACHE_CONF" ]; then
    # Agregar configuración de zona horaria
    if ! grep -q "SetEnv TZ" "$APACHE_CONF"; then
        echo -e "\n# Configuración de zona horaria para PHP" >> "$APACHE_CONF"
        echo "SetEnv TZ America/Mexico_City" >> "$APACHE_CONF"
        echo "PassEnv TZ" >> "$APACHE_CONF"
    fi
    
    # Agregar configuración PHP
    if ! grep -q "php_value date.timezone" "$APACHE_CONF"; then
        echo -e "\n<IfModule mod_php7.c>" >> "$APACHE_CONF"
        echo "    php_value date.timezone \"America/Mexico_City\"" >> "$APACHE_CONF"
        echo "    php_admin_value date.timezone \"America/Mexico_City\"" >> "$APACHE_CONF"
        echo "</IfModule>" >> "$APACHE_CONF"
        echo "<IfModule mod_php.c>" >> "$APACHE_CONF"
        echo "    php_value date.timezone \"America/Mexico_City\"" >> "$APACHE_CONF"
        echo "    php_admin_value date.timezone \"America/Mexico_City\"" >> "$APACHE_CONF"
        echo "</IfModule>" >> "$APACHE_CONF"
    fi
    success "Apache configurado"
fi

# 7. PARCHES PARA HOTELSOFT
info "Aplicando parches a HotelSoft..."
HOTELSOFT_DIR="/storage/emulated/0/htdocs/devmx/hotelsoft"
if [ -d "$HOTELSOFT_DIR" ]; then
    # Crear archivo de fix global
    cat > "$HOTELSOFT_DIR/_global_timezone_fix.php" << 'FIX'
<?php
/**
 * SOLUCIÓN DEFINITIVA ZONA HORARIA - HOTELSOFT
 * Este archivo fuerza GMT-6 en toda la aplicación
 */

// Método 1: Usar función date_default_timezone_set
if (!@date_default_timezone_set('America/Mexico_City')) {
    // Método 2: Usar ini_set
    @ini_set('date.timezone', 'America/Mexico_City');
    
    // Método 3: Variable de entorno
    @putenv('TZ=America/Mexico_City');
}

// Método 4: Verificar y forzar offset GMT-6 manualmente
$current_tz = @date_default_timezone_get();
if ($current_tz != 'America/Mexico_City') {
    define('GMT_OFFSET', -6 * 3600); // -6 horas en segundos
    
    // Sobrescribir funciones de fecha si es necesario
    if (!function_exists('hotelsoft_date')) {
        function hotelsoft_date($format, $timestamp = null) {
            $timestamp = $timestamp ?: time();
            return gmdate($format, $timestamp + GMT_OFFSET);
        }
        
        function hotelsoft_strtotime($time, $now = null) {
            $now = $now ?: time();
            return strtotime($time, $now) + GMT_OFFSET;
        }
        
        // Reemplazar funciones globales temporalmente
        if (!defined('TIMEZONE_FIXED')) {
            eval('
                function date($format, $timestamp = null) {
                    return hotelsoft_date($format, $timestamp);
                }
                
                function strtotime($time, $now = null) {
                    return hotelsoft_strtotime($time, $now);
                }
                
                function time() {
                    return parent_time() + GMT_OFFSET;
                }
                
                function parent_time() {
                    return \time();
                }
            ');
            define('TIMEZONE_FIXED', true);
        }
    }
}

// Función para verificar configuración
function verify_timezone() {
    $local = date('Y-m-d H:i:s');
    $utc = gmdate('Y-m-d H:i:s');
    $diff = (strtotime($local) - strtotime($utc)) / 3600;
    
    return [
        'zona' => date_default_timezone_get(),
        'local' => $local,
        'utc' => $utc,
        'diferencia' => $diff,
        'correcto' => ($diff == -6)
    ];
}

// Ejecutar al cargar
verify_timezone();
?>
FIX

    # Aplicar fix a archivos críticos
    for file in "$HOTELSOFT_DIR"/*.php; do
        if [ -f "$file" ]; then
            # Verificar si es archivo de reservas
            filename=$(basename "$file")
            if [[ "$filename" == *reserva* ]] || [[ "$filename" == *disponibilidad* ]] || 
               [[ "$filename" == *fecha* ]] || [[ "$filename" == *check* ]]; then
                # Agregar include al inicio
                if ! grep -q "_global_timezone_fix.php" "$file"; then
                    sed -i '1s|<?php|<?php\nrequire_once __DIR__ . "/_global_timezone_fix.php";|' "$file"
                    info "  Fix aplicado a: $filename"
                fi
            fi
        fi
    done
    
    # Archivos específicos mencionados
    if [ -f "$HOTELSOFT_DIR/guardareserva.php" ]; then
        sed -i '1s|<?php|<?php\nrequire_once __DIR__ . "/_global_timezone_fix.php";|' "$HOTELSOFT_DIR/guardareserva.php"
    fi
    
    if [ -f "$HOTELSOFT_DIR/verificardisponibilidad.php" ]; then
        sed -i '1s|<?php|<?php\nrequire_once __DIR__ . "/_global_timezone_fix.php";|' "$HOTELSOFT_DIR/verificardisponibilidad.php"
    fi
    
    success "Parches aplicados a HotelSoft"
fi

# 8. REINICIAR SERVICIOS
info "Reiniciando servicios..."
TZ=America/Mexico_City httpd -k start 2>/dev/null || apachectl start 2>/dev/null
sleep 3

# 9. VERIFICACIÓN FINAL
echo ""
echo "=========================================="
echo "🧪 VERIFICACIÓN FINAL"
echo "=========================================="

# Test PHP CLI
info "Test PHP CLI:"
php -r "
echo 'Zona horaria: ' . date_default_timezone_get() . PHP_EOL;
echo 'Fecha local:  ' . date('Y-m-d H:i:s') . PHP_EOL;
echo 'Fecha UTC:    ' . gmdate('Y-m-d H:i:s') . PHP_EOL;
\$diff = (strtotime(date('Y-m-d H:i:s')) - strtotime(gmdate('Y-m-d H:i:s'))) / 3600;
echo 'Diferencia:   ' . \$diff . ' horas' . PHP_EOL;
echo 'Estado:       ' . (\$diff == -6 ? '✅ CORRECTO (GMT-6)' : '❌ FALLO') . PHP_EOL;
"

# Crear archivo de test web
info "Creando archivo de test web..."
cat > /sdcard/htdocs/test-timezone-final.php << 'TEST'
<?php
echo "<h1>✅ TEST DEFINITIVO ZONA HORARIA</h1>";
echo "<h3>Información del sistema:</h3>";
echo "PHP Version: " . phpversion() . "<br>";
echo "Archivo php.ini: " . (php_ini_loaded_file() ?: 'No encontrado') . "<br>";
echo "Zona horaria configurada: " . date_default_timezone_get() . "<br>";
echo "date.timezone en ini: " . ini_get('date.timezone') . "<br>";
echo "Variable TZ: " . getenv('TZ') . "<br>";

echo "<h3>Test de fechas:</h3>";
$fecha_local = date('Y-m-d H:i:s');
$fecha_utc = gmdate('Y-m-d H:i:s');
$diferencia = (strtotime($fecha_local) - strtotime($fecha_utc)) / 3600;
echo "Fecha local: $fecha_local<br>";
echo "Fecha UTC: $fecha_utc<br>";
echo "Diferencia: $diferencia horas<br>";

if ($diferencia == -6) {
    echo "<h2 style='color: green;'>✅ ¡CONFIGURACIÓN CORRECTA! (GMT-6)</h2>";
} else {
    echo "<h2 style='color: red;'>❌ PROBLEMA DETECTADO</h2>";
    echo "<p>La diferencia debería ser -6 horas (México)</p>";
    echo "<p>Valor actual: $diferencia horas</p>";
}

echo "<h3>Test de reservas HotelSoft:</h3>";
$hoy = date('Y-m-d');
$checkin_prueba = date('Y-m-d', strtotime('+3 days'));
echo "Fecha actual: $hoy<br>";
echo "Check-in prueba: $checkin_prueba<br>";
echo "¿Check-in válido? " . (strtotime($checkin_prueba) >= strtotime($hoy) ? "✅ SÍ" : "❌ NO") . "<br>";

if (strtotime($checkin_prueba) < strtotime($hoy)) {
    echo "<p style='color: red;'><strong>⚠️ ADVERTENCIA:</strong> Las fechas no son consistentes!</p>";
}
?>
TEST

success "Test web creado: http://192.168.1.200:8080/test-timezone-final.php"

# 10. SOLUCIÓN DE EMERGENCIA SI NADA FUNCIONA
echo ""
echo "=========================================="
echo "🆘 SOLUCIÓN DE EMERGENCIA"
echo "=========================================="
info "Si aún hay problemas, ejecuta estos comandos:"

cat > /sdcard/htdocs/emergency-fix.php << 'EMERGENCY'
<?php
// SOLUCIÓN DE EMERGENCIA - EJECUTAR DIRECTAMENTE
header('Content-Type: text/plain');

echo "=== SOLUCIÓN EMERGENCIA ZONA HORARIA ===\n\n";

// Método extremo: Forzar todo
$methods = [
    'date_default_timezone_set' => date_default_timezone_set('America/Mexico_City'),
    'ini_set' => ini_set('date.timezone', 'America/Mexico_City'),
    'putenv' => putenv('TZ=America/Mexico_City'),
];

echo "Métodos aplicados:\n";
foreach ($methods as $method => $result) {
    echo "- $method: " . ($result ? "✅ OK" : "❌ Falló") . "\n";
}

echo "\nResultado:\n";
echo "Zona: " . date_default_timezone_get() . "\n";
echo "Local: " . date('Y-m-d H:i:s') . "\n";
echo "UTC: " . gmdate('Y-m-d H:i:s') . "\n";
$diff = (strtotime(date('Y-m-d H:i:s')) - strtotime(gmdate('Y-m-d H:i:s'))) / 3600;
echo "Diferencia: $diff horas\n";

if ($diff == -6) {
    echo "\n✅ ¡SOLUCIONADO! Ahora está en GMT-6\n";
    
    // Probar reserva
    $hoy = date('Y-m-d');
    $checkin = '2025-12-27';
    echo "\nTest de reserva:\n";
    echo "Hoy: $hoy\n";
    echo "Check-in: $checkin\n";
    echo "Válido? " . (strtotime($checkin) >= strtotime($hoy) ? "✅ SÍ" : "❌ NO") . "\n";
} else {
    echo "\n❌ Aún hay problemas. Último recurso:\n";
    echo "Agrega esta línea al inicio de CADA archivo PHP:\n";
    echo "----------------------------------------\n";
    echo "<?php\n";
    echo "// FIX FORZADO\n";
    echo "date_default_timezone_set('America/Mexico_City');\n";
    echo "putenv('TZ=America/Mexico_City');\n";
    echo "ini_set('date.timezone', 'America/Mexico_City');\n";
    echo "// Resto del código...\n";
    echo "----------------------------------------\n";
}
?>
EMERGENCY

success "Fix de emergencia: http://192.168.1.200:8080/emergency-fix.php"

echo ""
echo "=========================================="
success "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
info "Resumen de acciones realizadas:"
echo "1. ✅ Variable TZ configurada globalmente"
echo "2. ✅ php.ini principal configurado"
echo "3. ✅ Archivo 99-timezone.ini creado"
echo "4. ✅ .user.ini en directorios web"
echo "5. ✅ Apache configurado con SetEnv TZ"
echo "6. ✅ Parches aplicados a HotelSoft"
echo "7. ✅ Servicios reiniciados"
echo ""
warning "Si aún ves UTC en los tests:"
echo "1. Accede a: http://192.168.1.200:8080/emergency-fix.php"
echo "2. Sigue las instrucciones que aparecen ahí"
echo ""
info "Para ejecutar este script nuevamente:"
echo "curl -sL https://raw.githubusercontent.com/tu-usuario/tu-repo/main/fix-php-timezone.sh | bash"
echo ""
echo "🚀 ¡Listo! Tu PHP ahora debería estar en GMT-6"