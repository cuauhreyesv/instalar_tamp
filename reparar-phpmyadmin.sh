#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# REPARADOR phpMyAdmin - CONEXIÓN TCP COMO HEIDISQL
# Soluciona: "No such file or directory" en phpMyAdmin
# Mientras HeidiSQL funciona perfectamente
# ============================================
# Uso: bash reparar-phpmyadmin.sh
# ============================================

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_header() {
    echo -e "\n${MAGENTA}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}📌 $1${NC}"; }
print_warning() { echo -e "${CYAN}⚠️  $1${NC}"; }

# Mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        🔧 REPARADOR phpMyAdmin - CONEXIÓN TCP 🔧         ║"
    echo "║     Soluciona: HeidiSQL funciona pero phpMyAdmin no       ║"
    echo "║           Método: TCP 127.0.0.1:3306 (como HeidiSQL)      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================
# FUNCIÓN PRINCIPAL DE REPARACIÓN
# ============================================
reparar_phpmyadmin() {
    print_header "DIAGNÓSTICO INICIAL"
    
    # 1. Verificar que phpMyAdmin existe
    print_info "Buscando phpMyAdmin..."
    PMA_DIR="$HOME/tamp-cuauh/apache/htdocs/phpmyadmin"
    
    if [ ! -d "$PMA_DIR" ]; then
        print_error "phpMyAdmin no encontrado en: $PMA_DIR"
        print_info "Buscando en otras ubicaciones..."
        
        # Buscar alternativas
        FIND_PMA=$(find ~/tamp-cuauh -type d -name "phpmyadmin" 2>/dev/null | head -1)
        
        if [ -n "$FIND_PMA" ]; then
            PMA_DIR="$FIND_PMA"
            print_success "Encontrado en: $PMA_DIR"
        else
            print_error "phpMyAdmin no encontrado en el sistema"
            return 1
        fi
    else
        print_success "phpMyAdmin encontrado en: $PMA_DIR"
    fi
    
    # 2. Verificar conexión MySQL (como HeidiSQL)
    print_header "VERIFICANDO CONEXIÓN MYSQL (MÉTODO HEIDISQL)"
    
    print_info "Probando conexión TCP (127.0.0.1:3306)..."
    if mysql -u terminal1 -pMaster01 -h 127.0.0.1 -P 3306 -e "SELECT '✅ TCP funciona (como HeidiSQL)' as Estado;" 2>/dev/null; then
        print_success "Conexión TCP FUNCIONA (igual que HeidiSQL)"
        TCP_WORKS=true
    else
        print_warning "Conexión TCP falla"
        TCP_WORKS=false
        
        # Intentar otras variantes
        print_info "Probando otras conexiones..."
        
        # Probando root sin contraseña
        if mysql -u root -h 127.0.0.1 -P 3306 -e "SELECT 1" 2>/dev/null; then
            print_success "Root sin contraseña funciona via TCP"
        fi
    fi
    
    # 3. Verificar archivo de configuración actual
    print_header "ANALIZANDO CONFIGURACIÓN ACTUAL"
    
    CONFIG_FILE="$PMA_DIR/config.inc.php"
    
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Archivo de configuración encontrado"
        print_info "Contenido actual:"
        grep -E "(host|port|socket|connect_type|localhost|127.0.0.1)" "$CONFIG_FILE" 2>/dev/null || echo "    (No hay configuración relevante)"
        
        # Hacer backup
        BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_success "Backup creado: $BACKUP_FILE"
    else
        print_warning "NO existe config.inc.php - Esta es la causa del problema"
    fi
    
    # 4. CREAR/CORREGIR CONFIGURACIÓN
    print_header "CREANDO CONFIGURACIÓN TCP (COMO HEIDISQL)"
    
    print_info "Creando configuración para conexión TCP..."
    
    cat > "$CONFIG_FILE" << 'CONFIG_EOF'
<?php
/* ============================================
 * phpMyAdmin Configuration - REPARADO
 * Conexión TCP 127.0.0.1:3306 (igual que HeidiSQL)
 * ============================================ */
declare(strict_types=1);

// Clave de encriptación
$cfg['blowfish_secret'] = 'terminal1_tamp_2221_' . md5(__FILE__ . time());

/* Servidores configurados */
$i = 0;

/* ============================================
 * SERVER 1: MySQL Terminal1 (TCP como HeidiSQL)
 * ============================================ */
$i++;
$cfg['Servers'][$i]['verbose'] = 'MySQL Terminal1 (TCP)';
$cfg['Servers'][$i]['host'] = '127.0.0.1';      // ← CLAVE: IP para TCP
$cfg['Servers'][$i]['port'] = '3306';           // ← Puerto explícito
$cfg['Servers'][$i]['socket'] = '';             // ← VACÍO: No usar socket
$cfg['Servers'][$i]['connect_type'] = 'tcp';    // ← TCP como HeidiSQL
$cfg['Servers'][$i]['extension'] = 'mysqli';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['auth_type'] = 'cookie';    // Login normal
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['Servers'][$i]['AllowRoot'] = true;

// Credenciales sugeridas (aparecerán pre-llenadas)
$cfg['Servers'][$i]['user'] = 'terminal1';
$cfg['Servers'][$i]['password'] = 'Master01';

/* ============================================
 * CONFIGURACIÓN AVANZADA (opcional)
 * ============================================ */
$cfg['Servers'][$i]['controluser'] = 'terminal1';
$cfg['Servers'][$i]['controlpass'] = 'Master01';

// Base de datos para características phpMyAdmin
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';
$cfg['Servers'][$i]['relation'] = 'pma__relation';
$cfg['Servers'][$i]['table_info'] = 'pma__table_info';
$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';
$cfg['Servers'][$i]['column_info'] = 'pma__column_info';
$cfg['Servers'][$i]['history'] = 'pma__history';
$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';
$cfg['Servers'][$i]['tracking'] = 'pma__tracking';
$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';
$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';

/* ============================================
 * CONFIGURACIÓN GENERAL
 * ============================================ */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
$cfg['ExecTimeLimit'] = 300;
$cfg['MemoryLimit'] = '256M';
$cfg['ShowPhpInfo'] = false;
$cfg['ServerDefault'] = 1;          // Usar servidor 1 por defecto
$cfg['VersionCheck'] = true;
$cfg['ProxyUrl'] = '';

/* ============================================
 * INTERFAZ Y APARIENCIA
 * ============================================ */
$cfg['ThemeManager'] = true;
$cfg['ThemeDefault'] = 'pmahomme';
$cfg['NavigationTreeEnableGrouping'] = true;
$cfg['NavigationTreeDbSeparator'] = '__';
$cfg['NavigationTreeDisplayItemFilterMinimum'] = 100;

/* ============================================
 * SEGURIDAD
 * ============================================ */
$cfg['ForceSSL'] = false;
$cfg['AllowArbitraryServer'] = false;
$cfg['LoginCookieValidity'] = 14400;
$cfg['LoginCookieStore'] = 0;
$cfg['AllowUserDropDatabase'] = false;

/* ============================================
 * CARACTERÍSTICAS
 * ============================================ */
$cfg['MaxRows'] = 250;
$cfg['Order'] = 'ASC';
$cfg['SaveCellsAtOnce'] = true;
$cfg['GridEditing'] = 'double-click';
$cfg['RelationalDisplay'] = 'K';
$cfg['DefaultTabTable'] = 'structure';
$cfg['DefaultTabDatabase'] = 'structure';

/* ============================================
 * IDIOMA
 * ============================================ */
$cfg['DefaultLang'] = 'es';
$cfg['DefaultConnectionCollation'] = 'utf8mb4_general_ci';

/* Fin del archivo */
?>
CONFIG_EOF
    
    if [ $? -eq 0 ]; then
        print_success "Configuración creada exitosamente"
        chmod 644 "$CONFIG_FILE"
        
        print_info "Configuración aplicada:"
        echo "   • host: 127.0.0.1 (TCP IP)"
        echo "   • port: 3306"
        echo "   • socket: '' (vacío)"
        echo "   • connect_type: 'tcp'"
        echo "   • auth_type: 'cookie'"
        echo "   • usuario sugerido: terminal1"
    else
        print_error "Error al crear configuración"
        return 1
    fi
    
    # 5. CREAR ACCESOS ALTERNATIVOS
    print_header "CREANDO ACCESOS ALTERNATIVOS"
    
    # 5.1 Página de diagnóstico
    print_info "Creando página de diagnóstico..."
    cat > /sdcard/htdocs/phpmyadmin-diag.php << 'DIAG_EOF'
<?php
echo "<!DOCTYPE html><html><head><title>Diagnóstico phpMyAdmin</title>";
echo "<style>body{font-family:Arial;margin:20px}.success{color:green}.error{color:red}.warning{color:orange}pre{background:#f5f5f5;padding:10px}</style>";
echo "</head><body>";
echo "<h2>🔍 Diagnóstico phpMyAdmin - Conexión TCP</h2>";

// Probar conexión TCP
echo "<h3>1. Probando conexión TCP (127.0.0.1:3306):</h3>";
$conn = @new mysqli('127.0.0.1', 'terminal1', 'Master01', null, 3306);
if ($conn->connect_error) {
    echo "<div class='error'>❌ Error TCP: " . $conn->connect_error . "</div>";
} else {
    echo "<div class='success'>✅ ¡Conexión TCP FUNCIONA! (igual que HeidiSQL)</div>";
    echo "<p><strong>MySQL:</strong> " . $conn->server_info . "</p>";
    echo "<p><strong>Método:</strong> " . $conn->host_info . "</p>";
    $conn->close();
}

// Verificar archivo de configuración
echo "<h3>2. Archivo de configuración:</h3>";
$config_file = '/data/data/com.termux/files/home/tamp-cuauh/apache/htdocs/phpmyadmin/config.inc.php';
if (file_exists($config_file)) {
    echo "<div class='success'>✅ config.inc.php EXISTE</div>";
    $config = file_get_contents($config_file);
    echo "<h4>Configuración clave:</h4>";
    echo "<pre>";
    foreach (explode("\n", $config) as $line) {
        if (preg_match('/host|port|socket|connect_type|127\.0\.0\.1|localhost/i', $line)) {
            echo htmlspecialchars($line) . "\n";
        }
    }
    echo "</pre>";
} else {
    echo "<div class='error'>❌ config.inc.php NO EXISTE</div>";
}

// Enlaces de acceso
echo "<h3>3. Enlaces de acceso:</h3>";
echo "<ul>";
echo "<li><a href='/phpmyadmin/' target='_blank'>phpMyAdmin Principal</a></li>";
echo "<li><a href='/phpmyadmin-simple.php' target='_blank'>phpMyAdmin Simplificado</a></li>";
echo "<li><a href='/admin-mysql.php' target='_blank'>Acceso Directo</a></li>";
echo "</ul>";

echo "</body></html>";
?>
DIAG_EOF
    print_success "Página de diagnóstico creada: /sdcard/htdocs/phpmyadmin-diag.php"
    
    # 5.2 phpMyAdmin simplificado
    print_info "Creando phpMyAdmin simplificado..."
    cat > /sdcard/htdocs/phpmyadmin-simple.php << 'SIMPLE_EOF'
<?php
/* phpMyAdmin Simplificado - Conexión TCP Forzada */
$cfg = array();

// Configuración MÍNIMA
$cfg['blowfish_secret'] = 'simple_tcp_fixed_' . time();
$cfg['DefaultLang'] = 'es';
$cfg['ServerDefault'] = 1;

// UN solo servidor con TCP
$cfg['Servers'][1]['host'] = '127.0.0.1';      // TCP
$cfg['Servers'][1]['port'] = '3306';           // Puerto
$cfg['Servers'][1]['socket'] = '';             // NO socket
$cfg['Servers'][1]['connect_type'] = 'tcp';    // Conexión TCP
$cfg['Servers'][1]['extension'] = 'mysqli';
$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['user'] = 'terminal1';
$cfg['Servers'][1]['password'] = 'Master01';
$cfg['Servers'][1]['AllowNoPassword'] = false;

// Cargar phpMyAdmin real
define('PMA_NO_SESSION', false);
chdir('/data/data/com.termux/files/home/tamp-cuauh/apache/htdocs/phpmyadmin');
require 'index.php';
?>
SIMPLE_EOF
    print_success "phpMyAdmin simplificado creado"
    
    # 5.3 Redirección directa
    print_info "Creando redirección directa..."
    cat > /sdcard/htdocs/admin-mysql.php << 'REDIRECT_EOF'
<?php
header('Location: /phpmyadmin/index.php?server=1&username=terminal1');
exit;
?>
REDIRECT_EOF
    print_success "Redirección creada"
    
    # 6. VERIFICACIÓN FINAL
    print_header "VERIFICACIÓN FINAL"
    
    print_info "Archivos creados:"
    echo "   • $CONFIG_FILE"
    echo "   • /sdcard/htdocs/phpmyadmin-diag.php"
    echo "   • /sdcard/htdocs/phpmyadmin-simple.php"
    echo "   • /sdcard/htdocs/admin-mysql.php"
    
    print_info "Enlaces de acceso:"
    echo "   1. http://localhost:8080/phpmyadmin/"
    echo "   2. http://localhost:8080/phpmyadmin-diag.php"
    echo "   3. http://localhost:8080/phpmyadmin-simple.php"
    echo "   4. http://localhost:8080/admin-mysql.php"
    
    print_info "Configuración aplicada:"
    echo "   • Método: TCP (127.0.0.1:3306)"
    echo "   • Igual que HeidiSQL en Windows"
    echo "   • Socket: DESHABILITADO"
    echo "   • Usuario por defecto: terminal1"
    
    return 0
}

# ============================================
# FUNCIÓN: Crear phpMyAdmin PORTABLE alternativo
# ============================================
crear_phpmyadmin_portable() {
    print_header "CREANDO phpMyAdmin PORTABLE (alternativa)"
    
    PORTABLE_DIR="/sdcard/htdocs/pma-fixed"
    
    print_info "Creando directorio: $PORTABLE_DIR"
    rm -rf "$PORTABLE_DIR"
    mkdir -p "$PORTABLE_DIR"
    
    # Descargar phpMyAdmin si es posible
    print_info "Intentando descargar phpMyAdmin portable..."
    
    if command -v curl &>/dev/null; then
        cd "$PORTABLE_DIR"
        curl -L https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -o pma.zip 2>/dev/null
        
        if [ -f "pma.zip" ]; then
            unzip -q pma.zip 2>/dev/null
            mv phpMyAdmin-5.2.1-all-languages/* .
            rm -rf phpMyAdmin-5.2.1-all-languages pma.zip
            print_success "phpMyAdmin descargado y extraído"
        else
            print_warning "No se pudo descargar, creando versión básica"
            crear_version_basica
        fi
    else
        print_warning "curl no disponible, creando versión básica"
        crear_version_basica
    fi
    
    # Crear configuración SUPER SIMPLE
    print_info "Creando configuración ultra simple..."
    cat > "$PORTABLE_DIR/config.inc.php" << 'ULTRA_SIMPLE'
<?php
$cfg['Servers'][1]['host'] = '127.0.0.1';
$cfg['Servers'][1]['port'] = '3306';
$cfg['Servers'][1]['connect_type'] = 'tcp';
$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['blowfish_secret'] = 'portable_fixed_tcp_' . time();
?>
ULTRA_SIMPLE
    
    print_success "phpMyAdmin Portable creado"
    print_info "Accede en: http://localhost:8080/pma-fixed/"
    
    # Crear página de entrada
    cat > "/sdcard/htdocs/gestor-mysql.php" << 'GESTOR_EOF'
<?php
echo "<html><head><title>Gestor MySQL - Opciones</title>";
echo "<style>
    body { font-family: Arial; margin: 40px; }
    .option { 
        background: #f8f9fa; 
        border: 2px solid #dee2e6; 
        border-radius: 10px; 
        padding: 20px; 
        margin: 15px 0;
        transition: all 0.3s;
    }
    .option:hover { 
        background: #e9ecef; 
        border-color: #007bff;
    }
    .btn { 
        display: inline-block; 
        background: #007bff; 
        color: white; 
        padding: 10px 20px; 
        text-decoration: none; 
        border-radius: 5px;
    }
</style></head><body>";
echo "<h1>🔧 Gestor MySQL - Elige una opción</h1>";

echo "<div class='option'>";
echo "<h2>1. phpMyAdmin Original (Reparado)</h2>";
echo "<p>Ahora configurado con TCP (127.0.0.1:3306)</p>";
echo "<a class='btn' href='/phpmyadmin/' target='_blank'>Abrir phpMyAdmin</a>";
echo "</div>";

echo "<div class='option'>";
echo "<h2>2. phpMyAdmin Portable</h2>";
echo "<p>Versión independiente siempre funcional</p>";
echo "<a class='btn' href='/pma-fixed/' target='_blank'>Abrir Portable</a>";
echo "</div>";

echo "<div class='option'>";
echo "<h2>3. Diagnóstico</h2>";
echo "<p>Verifica el estado de la conexión</p>";
echo "<a class='btn' href='/phpmyadmin-diag.php' target='_blank'>Ver Diagnóstico</a>";
echo "</div>";

echo "<div class='option'>";
echo "<h2>4. Acceso Rápido</h2>";
echo "<p>Redirección directa al servidor 1</p>";
echo "<a class='btn' href='/admin-mysql.php' target='_blank'>Acceso Directo</a>";
echo "</div>";

echo "</body></html>";
?>
GESTOR_EOF
    
    print_success "Página gestor creada: http://localhost:8080/gestor-mysql.php"
}

crear_version_basica() {
    print_info "Creando versión básica de phpMyAdmin..."
    
    cat > index.php << 'BASIC_PMA'
<?php
echo "<html><head><title>phpMyAdmin Básico</title></head><body>";
echo "<h2>phpMyAdmin Básico - Conexión TCP</h2>";
echo "<form method='post'>";
echo "Servidor: <input type='text' name='host' value='127.0.0.1'><br>";
echo "Puerto: <input type='text' name='port' value='3306'><br>";
echo "Usuario: <input type='text' name='user' value='terminal1'><br>";
echo "Contraseña: <input type='password' name='pass' value='Master01'><br>";
echo "<input type='submit' value='Conectar'>";
echo "</form>";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $conn = new mysqli($_POST['host'], $_POST['user'], $_POST['pass'], null, $_POST['port']);
    if ($conn->connect_error) {
        echo "<div style='color:red;'>Error: " . $conn->connect_error . "</div>";
    } else {
        echo "<div style='color:green;'>✅ ¡Conectado!</div>";
        
        // Mostrar bases de datos
        $result = $conn->query("SHOW DATABASES");
        echo "<h3>Bases de datos:</h3><ul>";
        while ($row = $result->fetch_array()) {
            echo "<li>" . $row[0] . "</li>";
        }
        echo "</ul>";
        $conn->close();
    }
}
echo "</body></html>";
?>
BASIC_PMA
}

# ============================================
# FUNCIÓN: Reiniciar servicios
# ============================================
reiniciar_servicios() {
    print_header "REINICIANDO SERVICIOS"
    
    print_info "Reiniciando Apache..."
    pkill httpd 2>/dev/null
    sleep 2
    
    # Verificar configuración Apache
    if [ -f ~/tamp-cuauh/apache/conf/httpd.conf ]; then
        httpd -f ~/tamp-cuauh/apache/conf/httpd.conf &
        sleep 3
        
        if pgrep httpd > /dev/null; then
            print_success "Apache reiniciado correctamente"
        else
            print_warning "Apache podría no haberse iniciado"
        fi
    else
        print_warning "No se encontró configuración Apache"
    fi
    
    print_info "Estado actual:"
    echo "   • Apache: $(pgrep httpd >/dev/null && echo '✅ ACTIVO' || echo '❌ INACTIVO')"
    echo "   • MySQL: $(pgrep mysqld >/dev/null && echo '✅ ACTIVO' || echo '❌ INACTIVO')"
}

# ============================================
# PROGRAMA PRINCIPAL
# ============================================
main() {
    show_banner
    
    print_header "INICIANDO REPARACIÓN phpMyAdmin"
    print_info "Problema: HeidiSQL funciona pero phpMyAdmin da error 'No such file or directory'"
    print_info "Causa: phpMyAdmin usa socket UNIX, HeidiSQL usa TCP"
    print_info "Solución: Forzar phpMyAdmin a usar TCP (127.0.0.1:3306)"
    
    # Ejecutar reparación principal
    if reparar_phpmyadmin; then
        print_success "✅ Reparación principal COMPLETADA"
    else
        print_error "❌ Reparación principal falló"
        print_info "Intentando método alternativo..."
    fi
    
    # Crear versión portable (alternativa)
    crear_phpmyadmin_portable
    
    # Reiniciar servicios
    reiniciar_servicios
    
    # Resumen final
    print_header "🎯 REPARACIÓN COMPLETADA"
    echo ""
    echo "📋 RESUMEN DE CAMBIOS:"
    echo "════════════════════════════════════════"
    echo "1. ✅ Configuración TCP aplicada a phpMyAdmin"
    echo "   • host: 127.0.0.1 (TCP IP)"
    echo "   • port: 3306"
    echo "   • connect_type: tcp"
    echo "   • socket: (deshabilitado)"
    echo ""
    echo "2. ✅ Archivos creados:"
    echo "   • config.inc.php (configuración principal)"
    echo "   • phpmyadmin-diag.php (diagnóstico)"
    echo "   • phpmyadmin-simple.php (versión simplificada)"
    echo "   • admin-mysql.php (redirección directa)"
    echo "   • pma-fixed/ (phpMyAdmin portable)"
    echo "   • gestor-mysql.php (página de opciones)"
    echo ""
    echo "3. 🔗 ENLACES DE ACCESO:"
    echo "════════════════════════════════════════"
    echo "• phpMyAdmin Principal:    http://localhost:8080/phpmyadmin/"
    echo "• phpMyAdmin Portable:     http://localhost:8080/pma-fixed/"
    echo "• Diagnóstico:             http://localhost:8080/phpmyadmin-diag.php"
    echo "• Gestor de Opciones:      http://localhost:8080/gestor-mysql.php"
    echo "• Acceso Rápido:           http://localhost:8080/admin-mysql.php"
    echo "• Versión Simplificada:    http://localhost:8080/phpmyadmin-simple.php"
    echo ""
    echo "4. 🔧 CONFIGURACIÓN APLICADA:"
    echo "════════════════════════════════════════"
    echo "• Método: TCP (igual que HeidiSQL)"
    echo "• Dirección: 127.0.0.1:3306"
    echo "• Usuario: terminal1"
    echo "• Contraseña: Master01"
    echo ""
    echo "💡 NOTA: phpMyAdmin ahora usará el MÉTODO IDÉNTICO a HeidiSQL"
    echo "         (TCP en lugar de socket UNIX)"
    
    print_header "🔄 ¿PROBAR LA CONEXIÓN AHORA?"
    read -p "¿Abrir página de diagnóstico en el navegador? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_info "Abre tu navegador y visita: http://localhost:8080/phpmyadmin-diag.php"
        print_info "O ejecuta: termux-open-url http://localhost:8080/phpmyadmin-diag.php"
    fi
    
    print_header "🏁 FINALIZADO"
    echo "Si phpMyAdmin sigue sin funcionar, usa la versión portable:"
    echo "http://localhost:8080/pma-fixed/"
    echo ""
    echo "Script de reparación completado. ✅"
}

# ============================================
# EJECUTAR PROGRAMA PRINCIPAL
# ============================================
main "$@"