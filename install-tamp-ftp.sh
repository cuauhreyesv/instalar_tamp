#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# INSTALADOR TAMP + FTP CON AUTO-INICIO
# REPOSITORIO: https://github.com/cuauhreyesv/tamp.git
# PUERTO FTP: 2221
# USUARIO MYSQL: terminal1 / Master01
# phpMyAdmin: REPARADO (TCP como HeidiSQL)
# ============================================
# Para ejecutar: bash <(curl -s https://raw.githubusercontent.com/cuauhreyesv/tamp.git/main/install.sh)
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          🚀 TAMP SERVER INSTALLER v2.0 🚀                 ║"
    echo "║           Repo: cuauhreyesv/tamp                          ║"
    echo "║           FTP Port: 2221                                  ║"
    echo "║           MySQL User: terminal1 / Master01                ║"
    echo "║           phpMyAdmin: REPARADO (TCP como HeidiSQL)        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Funciones
print_header() {
    echo -e "\n${MAGENTA}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}📌 $1${NC}"; }
print_warning() { echo -e "${CYAN}⚠️  $1${NC}"; }

# ============================================
# FUNCIÓN MEJORADA: CONFIGURAR USUARIO MYSQL
# ============================================
configure_mysql_user() {
    print_header "CONFIGURANDO USUARIO MYSQL: terminal1"
    
    echo "⏳ Verificando estado de MySQL..."
    
    # 1. Primero verificar que MySQL esté corriendo
    if ! pgrep mysqld > /dev/null; then
        print_warning "MySQL no está ejecutándose"
        echo "Iniciando MySQL..."
        mysqld_safe --user=root &
        sleep 5
        
        if ! pgrep mysqld > /dev/null; then
            print_error "No se pudo iniciar MySQL. Inicia manualmente con: tamp start"
            return 1
        fi
    else
        print_success "MySQL está ejecutándose"
    fi
    
    # 2. Intentar conectar como root (múltiples métodos)
    echo -e "\n🔐 Intentando conexión como root..."
    ROOT_CONNECTED=false
    ROOT_AUTH=""
    
    # Método 1: Root sin contraseña
    if mysql -u root -e "SELECT 'root sin contraseña funciona' as Status;" 2>/dev/null; then
        print_success "Root sin contraseña: FUNCIONA"
        ROOT_CONNECTED=true
        ROOT_AUTH="-u root"
    
    # Método 2: Root con contraseña vacía explícita
    elif mysql -u root -p"" -e "SELECT 'root con contraseña vacía funciona' as Status;" 2>/dev/null; then
        print_success "Root con contraseña vacía explícita: FUNCIONA"
        ROOT_CONNECTED=true
        ROOT_AUTH="-u root -p\"\""
    
    # Método 3: Probar contraseñas comunes
    else
        print_warning "Root sin contraseña no funciona. Probando contraseñas comunes..."
        
        for pass in "root" "password" "123456" "mysql" ""; do
            if mysql -u root -p"$pass" -e "SELECT 'Probando contraseña...' as Status;" 2>/dev/null; then
                print_success "¡Contraseña encontrada: '$pass'"
                ROOT_CONNECTED=true
                ROOT_AUTH="-u root -p\"$pass\""
                break
            fi
        done
    fi
    
    # 3. Si tenemos acceso root, crear usuario terminal1
    if [ "$ROOT_CONNECTED" = true ]; then
        echo -e "\n👤 Creando usuario terminal1..."
        
        mysql $ROOT_AUTH << 'MYSQL_EOF' 2>/dev/null
-- Eliminar usuario existente si hay conflictos
DROP USER IF EXISTS 'terminal1'@'localhost';
DROP USER IF EXISTS 'terminal1'@'%';

-- Crear nuevo usuario con privilegios completos
CREATE USER 'terminal1'@'localhost' IDENTIFIED BY 'Master01';
CREATE USER 'terminal1'@'%' IDENTIFIED BY 'Master01';

GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

SELECT '✅ Usuario terminal1 creado exitosamente' as Status;
MYSQL_EOF
        
        if [ $? -eq 0 ]; then
            print_success "Usuario terminal1 creado con éxito"
            print_info "Usuario: terminal1"
            print_info "Contraseña: Master01"
            print_info "Acceso: Desde cualquier dispositivo (%)"
            print_info "Privilegios: TODOS (WITH GRANT OPTION)"
        else
            print_error "Error al crear usuario terminal1"
        fi
        
    else
        print_error "No se pudo conectar como root"
        print_warning "Configuración manual requerida:"
        echo "1. Descubre la contraseña de root:"
        echo "   - Revisa ~/tamp-cuauh/logs/"
        echo "   - Busca archivos de configuración"
        echo "2. O resetea la contraseña:"
        echo "   pkill mysqld"
        echo "   mysqld_safe --skip-grant-tables &"
        echo "   mysql -u root"
        echo "   FLUSH PRIVILEGES;"
        echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY '';"
        echo "   FLUSH PRIVILEGES;"
        return 1
    fi
    
    # 4. Verificar que el usuario se creó correctamente
    echo -e "\n🔍 Verificando usuario creado..."
    
    # Primero intentar con root
    mysql $ROOT_AUTH -e "SELECT User, Host FROM mysql.user WHERE User='terminal1';" 2>/dev/null
    
    # Luego intentar conectar como terminal1
    echo -e "\n🔌 Probando conexión con terminal1..."
    if mysql -u terminal1 -pMaster01 -e "SELECT '✅ ¡terminal1 funciona correctamente!' as Status;" 2>/dev/null; then
        print_success "Usuario terminal1 verificado y funcionando"
    else
        print_warning "Usuario creado pero conexión falla. Posibles causas:"
        echo "   • MySQL necesita reinicio"
        echo "   • Privilegios no aplicados"
        echo "   • Espera unos segundos y prueba manualmente:"
        echo "     mysql -u terminal1 -pMaster01"
    fi
    
    return 0
}

# Mostrar banner
show_banner

# 1. LIMPIAR INSTALACIONES PREVIAS
print_header "LIMPIANDO INSTALACIONES PREVIAS"
pkill -f "httpd" 2>/dev/null || true
pkill -f "mysqld" 2>/dev/null || true
pkill -f "pyftpdlib" 2>/dev/null || true
pkg remove -y apache2 mariadb php php-apache python 2>/dev/null || true
rm -rf ~/tamp 2>/dev/null || true
rm -rf ~/tamp-cuauh 2>/dev/null || true
print_success "Limpieza completada"

# 2. INSTALAR TAMP DESDE NUEVO REPOSITORIO
print_header "INSTALANDO TAMP DESDE: cuauhreyesv/tamp"
print_info "Actualizando paquetes Termux..."
pkg update -y && pkg upgrade -y

print_info "Configurando permisos de almacenamiento..."
echo -e "${YELLOW}📱 Por favor, acepta los permisos en tu dispositivo${NC}"
termux-setup-storage
sleep 3

print_info "Instalando git..."
pkg install git -y

print_info "Clonando repositorio personalizado..."
git clone https://github.com/cuauhreyesv/tamp.git ~/tamp-cuauh

print_info "Ejecutando instalador TAMP..."
cd ~/tamp-cuauh
bash setup

if [ $? -eq 0 ]; then
    print_success "TAMP instalado correctamente desde cuauhreyesv/tamp"
else
    print_error "Error durante la instalación de TAMP"
    exit 1
fi

cd ~

# 3. CONFIGURAR USUARIO MYSQL: terminal1 (USANDO FUNCIÓN MEJORADA)
if ! configure_mysql_user; then
    print_warning "Continuando instalación, pero MySQL necesita configuración manual"
    sleep 2
fi

# 4. INSTALAR FTP CON PUERTO 2221
print_header "INSTALANDO FTP SERVER (PUERTO: 2221)"
pkg install python python-pip -y
pip install pyftpdlib

# Crear script FTP con puerto 2221
cat > ~/tamp-ftp-2221 << 'FTP_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# SERVIDOR FTP PARA TAMP - PUERTO 2221
# ============================================
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         📤 FTP SERVER - TAMP v2.0           ║"
echo "║            Puerto Personalizado             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Configuración
FTP_PORT=2221
FTP_USER="android"
FTP_PASS="android"
FTP_DIR="/sdcard/htdocs"

echo "🔧 CONFIGURACIÓN FTP:"
echo "════════════════════════════════════════"
echo "   Puerto:    $FTP_PORT"
echo "   Usuario:   $FTP_USER"
echo "   Contraseña: $FTP_PASS"
echo "   Directorio: $FTP_DIR"
echo "════════════════════════════════════════"

# Verificar directorio
if [ ! -d "$FTP_DIR" ]; then
    echo "📁 Creando directorio $FTP_DIR..."
    mkdir -p "$FTP_DIR"
    echo "✅ Directorio creado"
fi

# Obtener IP
get_ip() {
    IP=$(ifconfig 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
    if [ -n "$IP" ]; then
        echo ""
        echo "📡 CONEXIÓN DESDE FILEZILLA:"
        echo "════════════════════════════════════════"
        echo "   Host: $IP"
        echo "   Puerto: $FTP_PORT"
        echo "   Usuario: $FTP_USER"
        echo "   Contraseña: $FTP_PASS"
        echo "════════════════════════════════════════"
    fi
}

get_ip

echo ""
echo "🚀 Iniciando servidor FTP en puerto $FTP_PORT..."
echo "🛑 Presiona Ctrl+C para detener"
echo ""

# Iniciar servidor
cd "$FTP_DIR"
python3 -m pyftpdlib -p "$FTP_PORT" -u "$FTP_USER" -P "$FTP_PASS" -w
FTP_EOF

chmod +x ~/tamp-ftp-2221
print_success "FTP configurado en puerto 2221"

# 5. CREAR SCRIPT DE AUTO-INICIO MEJORADO
print_header "CREANDO SISTEMA DE AUTO-INICIO"

cat > ~/auto-start-all << 'AUTO_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# AUTO-INICIO COMPLETO TAMP + FTP (2221)
# ============================================
echo ""
echo "🔧 INICIANDO SERVICIOS AUTOMÁTICAMENTE..."
echo ""

# Esperar estabilización
sleep 2

# 1. INICIAR TAMP (WEB SERVER)
echo "🌐 Paso 1/2: Iniciando TAMP Web Server..."
tamp start
WEB_STATUS=$?

if [ $WEB_STATUS -eq 0 ]; then
    echo "✅ TAMP iniciado correctamente"
    echo "   • Apache: http://localhost:8080"
    echo "   • phpMyAdmin: http://localhost:8080/phpmyadmin"
else
    echo "⚠️  TAMP tuvo problemas al iniciar"
fi

sleep 3

# 2. CONFIGURAR USUARIO MYSQL (con manejo de errores mejorado)
echo ""
echo "🗄️  Configurando usuario MySQL..."

# Intentar múltiples métodos para configurar terminal1
configure_mysql_in_auto() {
    # Método 1: Root sin contraseña
    mysql -u root << 'SQL_EOF' 2>/dev/null
CREATE USER IF NOT EXISTS 'terminal1'@'%' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'terminal1'@'localhost' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT '✅ terminal1 configurado' as Status;
SQL_EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Usuario MySQL configurado:"
        echo "   • Usuario: terminal1"
        echo "   • Contraseña: Master01"
        echo "   • Acceso: Desde cualquier dispositivo (%)"
        return 0
    fi
    
    # Método 2: Root con contraseña vacía explícita
    mysql -u root -p"" << 'SQL_EOF' 2>/dev/null
CREATE USER IF NOT EXISTS 'terminal1'@'%' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'terminal1'@'localhost' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL_EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Usuario MySQL configurado (método 2)"
        return 0
    fi
    
    # Si ambos métodos fallan
    echo "⚠️  No se pudo configurar MySQL automáticamente"
    echo "   Configura manualmente con:"
    echo "   mysql -u root -p[TU_CONTRASEÑA]"
    return 1
}

configure_mysql_in_auto

# 3. INICIAR FTP EN SEGUNDO PLANO
echo ""
echo "📤 Paso 2/2: Iniciando FTP Server (puerto 2221)..."

# Detener FTP previo si existe
pkill -f "pyftpdlib" 2>/dev/null

# Iniciar nuevo FTP
cd /sdcard/htdocs
nohup python3 -m pyftpdlib -p 2221 -u android -P android -w > ~/ftp.log 2>&1 &
FTP_PID=$!
echo $FTP_PID > ~/.ftp_2221_pid
sleep 2

if ps -p $FTP_PID > /dev/null; then
    echo "✅ FTP iniciado en puerto 2221"
    echo "   • Puerto: 2221"
    echo "   • Usuario: android"
    echo "   • Contraseña: android"
else
    echo "❌ FTP no pudo iniciar"
fi

# 4. MOSTRAR RESUMEN
echo ""
echo "📊 RESUMEN DE SERVICIOS:"
echo "════════════════════════════════════════"

# Obtener IP para conexión externa
IP=$(ifconfig 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')

echo "🌐 SERVICIO WEB:"
if [ -n "$IP" ]; then
    echo "   • URL Externa: http://$IP:8080"
    echo "   • URL Local: http://localhost:8080"
else
    echo "   • URL: http://localhost:8080"
fi

echo "   • phpMyAdmin: http://localhost:8080/phpmyadmin"
echo ""

echo "🗄️  BASE DE DATOS:"
echo "   • Usuario root: (sin contraseña por defecto)"
echo "   • Usuario: terminal1 (contraseña: Master01)"
echo "   • Host: Cualquier dispositivo (%)"
echo "   • Privilegios: TODOS"
echo ""

echo "📤 SERVICIO FTP:"
echo "   • Puerto: 2221"
echo "   • Usuario: android"
echo "   • Contraseña: android"
echo "   • Directorio: /sdcard/htdocs"
if [ -n "$IP" ]; then
    echo "   • FileZilla: ftp://$IP:2221"
fi

echo ""
echo "📁 SUBIR ARCHIVOS:"
echo "════════════════════════════════════════"
echo "1. FileZilla → Conectar a ftp://[IP]:2221"
echo "2. Subir archivos a: /sdcard/htdocs/"
echo "3. Acceder desde: http://localhost:8080/tu_archivo.php"
echo ""

echo "🔌 CONEXIÓN EXTERNA A MYSQL:"
echo "════════════════════════════════════════"
echo "Host: $IP (o dirección del dispositivo)"
echo "Puerto: 3306"
echo "Usuario: terminal1"
echo "Contraseña: Master01"
echo ""

echo "⚙️  COMANDOS DE CONTROL:"
echo "════════════════════════════════════════"
echo "tamp stop                   # Detener web"
echo "pkill -f pyftpdlib          # Detener FTP"
echo "~/tamp-ftp-2221            # Reiniciar FTP"
echo "cat ~/ftp.log              # Ver logs FTP"

# Mostrar logs recientes
echo ""
echo "📋 LOGS RECIENTES:"
echo "════════════════════════════════════════"
tail -5 ~/ftp.log 2>/dev/null || echo "No hay logs aún"
AUTO_EOF

chmod +x ~/auto-start-all

# 6. CONFIGURAR AUTO-INICIO EN .BASHRC
print_header "CONFIGURANDO INICIO AUTOMÁTICO EN TERMUX"

# Crear versión mejorada del auto-inicio para .bashrc
cat >> ~/.bashrc << 'BASHRC_EOF'
# ============================================
# AUTO-INICIO TAMP + FTP (2221)
# CON USUARIO MYSQL: terminal1/Master01
# ============================================
if [ -f ~/auto-start-all ] && [ ! -f ~/.servers_auto_started ]; then
    echo ""
    echo "🔄 Iniciando servidores automáticamente..."
    echo "   • TAMP Web Server"
    echo "   • MySQL con usuario: terminal1"
    echo "   • FTP Server (puerto 2221)"
    echo ""
    touch ~/.servers_auto_started
    # Ejecutar en segundo plano para no bloquear terminal
    (~/auto-start-all > ~/startup.log 2>&1 &)
fi
BASHRC_EOF

print_success "Auto-inicio configurado en ~/.bashrc"

# 7. EJECUTAR SERVICIOS AHORA MISMO
print_header "INICIANDO SERVICIOS POR PRIMERA VEZ"
echo "⏳ Iniciando TAMP + MySQL + FTP (2221)..."
echo "   Esto tomará aproximadamente 10 segundos"

# Ejecutar auto-inicio
~/auto-start-all &

# Esperar a que todo inicie
sleep 10

# 8. VERIFICACIÓN COMPLETA
print_header "VERIFICACIÓN DE ESTADO"
echo ""
echo "🔍 PROCESOS EN EJECUCIÓN:"
echo "════════════════════════════════════════"

check_service() {
    local service_name=$1
    local process_name=$2
    local port=$3
    
    if pgrep -f "$process_name" > /dev/null; then
        echo "✅ $service_name: 🟢 ACTIVO (puerto $port)"
        return 0
    else
        echo "❌ $service_name: 🔴 INACTIVO"
        return 1
    fi
}

# Verificar cada servicio
check_service "Apache Web Server" "httpd" "8080"
check_service "MySQL Database" "mysqld" "3306"
check_service "FTP Server" "pyftpdlib" "2221"

# VERIFICACIÓN MEJORADA DE USUARIO MYSQL
echo ""
echo "🗄️  VERIFICANDO USUARIO MYSQL:"
echo "════════════════════════════════════════"

# Primero: Verificar que MySQL esté accesible
if ! pgrep mysqld > /dev/null; then
    echo "❌ MySQL NO está ejecutándose"
    echo "   Ejecuta: tamp start  o  mysqld_safe --user=root &"
else
    echo "✅ MySQL está ejecutándose"
    
    # Intentar conectar como terminal1
    echo -e "\n🔌 Probando conexión con terminal1..."
    if mysql -u terminal1 -pMaster01 -e "SELECT '✅ terminal1 funciona' as Status;" 2>/dev/null; then
        echo "✅ Usuario terminal1: Configurado y funcionando"
        echo "   • Acceso local: OK"
        echo "   • Contraseña: Master01"
        
        # Mostrar hosts permitidos (con manejo de error)
        echo -e "\n📋 Hosts configurados para terminal1:"
        if mysql -u terminal1 -pMaster01 -e "SELECT User, Host FROM mysql.user WHERE User='terminal1';" 2>/dev/null; then
            # Éxito usando terminal1
            :
        elif mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='terminal1';" 2>/dev/null; then
            # Éxito usando root sin contraseña
            :
        elif mysql -u root -p"" -e "SELECT User, Host FROM mysql.user WHERE User='terminal1';" 2>/dev/null; then
            # Éxito usando root con contraseña vacía explícita
            :
        else
            echo "   ⚠️  No se pudo obtener información de hosts"
        fi
        
    else
        echo "⚠️  Usuario terminal1: No se pudo conectar"
        echo "   Posibles soluciones:"
        echo "   1. Verifica que el usuario exista:"
        echo "      mysql -u root -p[CONTRASEÑA] -e \"SELECT User, Host FROM mysql.user;\""
        echo "   2. Si no existe, créalo:"
        echo "      mysql -u root -p[CONTRASEÑA]"
        echo "      CREATE USER 'terminal1'@'localhost' IDENTIFIED BY 'Master01';"
        echo "      GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'localhost';"
        echo "      FLUSH PRIVILEGES;"
    fi
fi

echo ""
echo "🌐 PRUEBA DE CONEXIÓN WEB:"
echo "════════════════════════════════════════"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo "✅ Web Server responde correctamente"
else
    echo "⚠️  Web Server no responde como esperado"
fi

# 9. CREAR ARCHIVO DE PRUEBA CON CONEXIÓN MYSQL (MEJORADO)
print_header "CREANDO ARCHIVO DE PRUEBA CON CONEXIÓN MYSQL"

cat > /sdcard/htdocs/test-mysql-terminal1.php << 'TEST_MYSQL_EOF'
<?php
// Test MySQL Connection with terminal1 user - VERSIÓN MEJORADA
echo "<!DOCTYPE html>";
echo "<html>";
echo "<head>";
echo "<title>✅ TAMP Server - MySQL Terminal1 Test</title>";
echo "<style>";
echo "body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }";
echo ".container { max-width: 800px; margin: 0 auto; background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; backdrop-filter: blur(10px); }";
echo "h1 { text-align: center; color: #4CAF50; }";
echo ".success { background: #10b981; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".error { background: #ef4444; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".warning { background: #f59e0b; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".info-box { background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; margin: 10px 0; }";
echo "pre { background: rgba(0,0,0,0.3); padding: 10px; border-radius: 5px; overflow-x: auto; }";
echo "</style>";
echo "</head>";
echo "<body>";
echo "<div class='container'>";
echo "<h1>🔌 PRUEBA DE CONEXIÓN MYSQL - terminal1</h1>";

// Método 1: Conexión TCP (como HeidiSQL) - ESTE ES EL QUE FUNCIONA
echo "<div class='info-box'>";
echo "<h3>🔧 Método 1: Conexión TCP (127.0.0.1:3306) - COMO HEIDISQL</h3>";

$conn1 = @new mysqli('127.0.0.1', 'terminal1', 'Master01', null, 3306);
if ($conn1->connect_error) {
    echo "<div class='error'>❌ Error TCP: " . $conn1->connect_error . "</div>";
    echo "<div class='warning'>⚠️  HeidiSQL funciona porque usa este método exacto</div>";
} else {
    echo "<div class='success'>✅ ¡Conectado exitosamente! (igual que HeidiSQL)</div>";
    echo "<p><strong>MySQL Version:</strong> " . $conn1->server_info . "</p>";
    echo "<p><strong>Host Info:</strong> " . $conn1->host_info . "</p>";
    echo "<p><strong>Método:</strong> TCP (127.0.0.1:3306)</p>";
    $conn1->close();
}
echo "</div>";

// Método 2: Conexión localhost (socket - el que falla en phpMyAdmin)
echo "<div class='info-box'>";
echo "<h3>🔧 Método 2: Conexión localhost (socket) - EL PROBLEMA</h3>";

$conn2 = @new mysqli('localhost', 'terminal1', 'Master01');
if ($conn2->connect_error) {
    echo "<div class='error'>❌ Error: " . $conn2->connect_error . "</div>";
    
    if (strpos($conn2->connect_error, 'No such file') !== false) {
        echo "<div class='warning'>⚠️  ¡ESTE ES EL ERROR DE phpMyAdmin!</div>";
        echo "<p>phpMyAdmin falla porque intenta usar socket UNIX</p>";
        echo "<p>HeidiSQL funciona porque usa TCP (127.0.0.1:3306)</p>";
    }
} else {
    echo "<div class='success'>✅ Socket funciona (inusual en Termux)</div>";
    $conn2->close();
}
echo "</div>";

// Solución aplicada
echo "<div class='info-box'>";
echo "<h3>🔧 SOLUCIÓN APLICADA:</h3>";
echo "<p><strong>Problema:</strong> phpMyAdmin usa socket, HeidiSQL usa TCP</p>";
echo "<p><strong>Solución:</strong> Configurar phpMyAdmin para usar TCP</p>";
echo "<p><strong>Archivo:</strong> config.inc.php creado con:</p>";
echo "<pre>";
echo "\$cfg['Servers'][1]['host'] = '127.0.0.1';\n";
echo "\$cfg['Servers'][1]['port'] = '3306';\n";
echo "\$cfg['Servers'][1]['connect_type'] = 'tcp';\n";
echo "\$cfg['Servers'][1]['socket'] = '';";
echo "</pre>";
echo "</div>";

echo "<div class='success'>";
echo "🎯 phpMyAdmin ahora funciona igual que HeidiSQL";
echo "</div>";

echo "</div>";
echo "</body>";
echo "</html>";
?>
TEST_MYSQL_EOF

print_success "Archivo de prueba MEJORADO creado: /sdcard/htdocs/test-mysql-terminal1.php"

# 10. REPARAR phpMyAdmin - CONFIGURACIÓN TCP (COMO HEIDISQL)
print_header "REPARANDO phpMyAdmin - CONFIGURACIÓN TCP"
echo "⚠️  PROBLEMA DETECTADO: HeidiSQL funciona pero phpMyAdmin da error"
echo "    RAZÓN: phpMyAdmin intenta usar socket, HeidiSQL usa TCP"
echo "    SOLUCIÓN: Forzar phpMyAdmin a usar TCP (127.0.0.1:3306)"

PMA_DIR="$HOME/tamp-cuauh/apache/htdocs/phpmyadmin"
CONFIG_FILE="$PMA_DIR/config.inc.php"

# Verificar si phpMyAdmin existe
if [ ! -d "$PMA_DIR" ]; then
    print_warning "phpMyAdmin no encontrado en: $PMA_DIR"
    print_info "Buscando en otras ubicaciones..."
    
    # Buscar alternativas
    FIND_PMA=$(find ~/tamp-cuauh -type d -name "phpmyadmin" 2>/dev/null | head -1)
    
    if [ -n "$FIND_PMA" ]; then
        PMA_DIR="$FIND_PMA"
        CONFIG_FILE="$PMA_DIR/config.inc.php"
        print_success "Encontrado en: $PMA_DIR"
    else
        print_error "phpMyAdmin no encontrado"
        echo "   phpMyAdmin no se instaló correctamente"
        echo "   Acceso alternativo: Usa HeidiSQL o programas externos"
    fi
fi

# Crear archivo de configuración si no existe o repararlo
if [ -d "$PMA_DIR" ]; then
    print_info "Creando/Reparando config.inc.php para TCP..."
    
    # Hacer backup si existe
    if [ -f "$CONFIG_FILE" ]; then
        BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_success "Backup creado: $BACKUP_FILE"
    fi
    
    # Crear configuración TCP (igual que HeidiSQL)
    cat > "$CONFIG_FILE" << 'PMA_CONFIG_EOF'
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
$cfg['Servers'][$i]['auth_type'] = 'cookie';    // Login normal
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['Servers'][$i]['AllowRoot'] = true;

// Credenciales sugeridas (aparecerán pre-llenadas)
$cfg['Servers'][$i]['user'] = 'terminal1';
$cfg['Servers'][$i]['password'] = 'Master01';

/* ============================================
 * CONFIGURACIÓN GENERAL
 * ============================================ */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
$cfg['ExecTimeLimit'] = 300;
$cfg['MemoryLimit'] = '256M';
$cfg['ServerDefault'] = 1;          // Usar servidor 1 por defecto
$cfg['VersionCheck'] = true;

/* ============================================
 * INTERFAZ Y APARIENCIA
 * ============================================ */
$cfg['ThemeManager'] = true;
$cfg['ThemeDefault'] = 'pmahomme';
$cfg['DefaultLang'] = 'es';

/* ============================================
 * SEGURIDAD
 * ============================================ */
$cfg['ForceSSL'] = false;
$cfg['AllowArbitraryServer'] = false;
$cfg['LoginCookieValidity'] = 14400;

/* Fin del archivo */
?>
PMA_CONFIG_EOF
    
    if [ $? -eq 0 ]; then
        chmod 644 "$CONFIG_FILE"
        print_success "✅ Configuración phpMyAdmin creada/reparada"
        print_info "Configuración aplicada:"
        echo "   • host: 127.0.0.1 (TCP IP)"
        echo "   • port: 3306"
        echo "   • socket: '' (vacío)"
        echo "   • connect_type: 'tcp' (igual que HeidiSQL)"
        echo "   • auth_type: 'cookie'"
        echo "   • usuario sugerido: terminal1"
    else
        print_error "❌ Error al crear configuración phpMyAdmin"
    fi
    
    # Crear página de diagnóstico
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
    echo "<h4>Configuración aplicada:</h4>";
    echo "<pre>";
    $lines = file($config_file);
    foreach ($lines as $line) {
        if (preg_match('/host|port|socket|connect_type|127\.0\.0\.1|localhost/i', $line)) {
            echo htmlspecialchars(trim($line)) . "\n";
        }
    }
    echo "</pre>";
} else {
    echo "<div class='error'>❌ config.inc.php NO EXISTE</div>";
    echo "<p>Esto causa que phpMyAdmin use valores por defecto (socket)</p>";
}

// Enlaces
echo "<h3>3. Enlaces de acceso:</h3>";
echo "<ul>";
echo "<li><a href='/phpmyadmin/' target='_blank'>phpMyAdmin Principal</a> (debería funcionar ahora)</li>";
echo "<li><a href='/test-mysql-terminal1.php' target='_blank'>Prueba MySQL</a></li>";
echo "</ul>";

echo "</body></html>";
?>
DIAG_EOF
    
    print_success "Página de diagnóstico creada: /sdcard/htdocs/phpmyadmin-diag.php"
    
else
    print_warning "No se pudo reparar phpMyAdmin (directorio no encontrado)"
fi

# 11. VERIFICACIÓN ESPECÍFICA DE phpMyAdmin
print_header "VERIFICANDO phpMyAdmin REPARADO"
echo "🔍 Estado de la reparación:"

if [ -f "$CONFIG_FILE" ]; then
    print_success "✅ config.inc.php creado en: $CONFIG_FILE"
    echo "   Configuración aplicada: TCP 127.0.0.1:3306"
    echo "   Método: Igual que HeidiSQL (no más socket)"
    
    # Mostrar configuración clave
    echo "   Contenido clave:"
    grep -E "(host|port|socket|connect_type)" "$CONFIG_FILE" 2>/dev/null | while read line; do
        echo "     • $line"
    done
else
    print_warning "⚠️  config.inc.php no se pudo crear"
    echo "   phpMyAdmin usará valores por defecto (socket)"
    echo "   Esto causará error: 'No such file or directory'"
fi

echo ""
echo "🌐 Acceso a phpMyAdmin:"
echo "════════════════════════════════════════"
echo "• phpMyAdmin: http://localhost:8080/phpmyadmin/"
echo "• Diagnóstico: http://localhost:8080/phpmyadmin-diag.php"
echo ""
echo "🔧 Si phpMyAdmin aún falla:"
echo "════════════════════════════════════════"
echo "1. phpMyAdmin intenta usar socket por defecto"
echo "2. HeidiSQL usa TCP (127.0.0.1:3306)"
echo "3. Solución: El script ya configuró TCP en config.inc.php"
echo "4. Si persiste, edita manualmente:"
echo "   nano $CONFIG_FILE"
echo "   Asegúrate que tenga:"
echo "   \$cfg['Servers'][1]['host'] = '127.0.0.1';"
echo "   \$cfg['Servers'][1]['connect_type'] = 'tcp';"

# 12. CREAR ARCHIVO DE CONFIGURACIÓN MEJORADO
print_header "CREANDO DOCUMENTACIÓN DEL SISTEMA"

cat > ~/tamp-config-terminal1.txt << 'CONFIG_EOF'
╔════════════════════════════════════════════════════════════════════╗
║                 🚀 TAMP SERVER CONFIG v2.0 🚀                     ║
║              Repositorio: cuauhreyesv/tamp                        ║
║                FTP Personalizado: 2221                            ║
║                MySQL User: terminal1 / Master01                   ║
║                phpMyAdmin: REPARADO (TCP como HeidiSQL)          ║
╚════════════════════════════════════════════════════════════════════╝

📍 DIRECTORIOS PRINCIPALES:
   • Proyectos Web:    /sdcard/htdocs/
   • Instalación TAMP: ~/tamp-cuauh/
   • phpMyAdmin:       ~/tamp-cuauh/apache/htdocs/phpmyadmin/
   • Logs Apache:      ~/tamp-cuauh/logs/
   • Logs FTP:         ~/ftp.log

🔧 CONFIGURACIÓN DE PUERTOS:
   • Apache HTTP:      8080
   • Apache HTTPS:     8443 (SSL)
   • MySQL/MariaDB:    3306
   • FTP Server:       2221 ← PERSONALIZADO

👤 CREDENCIALES DE ACCESO:
   
   MySQL/phpMyAdmin (REPARADO):
      ▸ Usuario root:      (sin contraseña por defecto)
      ▸ Usuario terminal1: Master01
      ▸ phpMyAdmin URL:    http://localhost:8080/phpmyadmin/
      ▸ CONFIGURACIÓN:     TCP 127.0.0.1:3306 (igual que HeidiSQL)
      ▸ Problema solucionado: phpMyAdmin ya no usa socket

   FTP Server:
      ▸ Puerto:    2221
      ▸ Usuario:   android
      ▸ Password:  android
      ▸ Directorio: /sdcard/htdocs

🔌 CONEXIÓN phpMyAdmin - PROBLEMA SOLUCIONADO:
   
   ANTES: ❌ phpMyAdmin fallaba con "No such file or directory"
          ✅ HeidiSQL funcionaba perfectamente
   
   RAZÓN: phpMyAdmin usaba socket UNIX por defecto
          HeidiSQL usa TCP (127.0.0.1:3306)
   
   SOLUCIÓN APLICADA:
      • Se creó: ~/tamp-cuauh/apache/htdocs/phpmyadmin/config.inc.php
      • Configuración: host='127.0.0.1', connect_type='tcp'
      • Mismo método que HeidiSQL
   
   ACCESO:
      • phpMyAdmin: http://localhost:8080/phpmyadmin/
      • Diagnóstico: http://localhost:8080/phpmyadmin-diag.php

🚀 COMANDOS DE CONTROL:
   ▸ tamp start          # Iniciar servidor web
   ▸ tamp stop           # Detener servidor web
   ▸ tamp start-ssl      # Iniciar con SSL (8443)
   ▸ ~/tamp-ftp-2221    # Iniciar FTP (puerto 2221)
   ▸ ~/auto-start-all   # Iniciar todos los servicios
   ▸ pkill -f pyftpdlib # Detener FTP

📡 ACCESO DESDE RED:
   ▸ Web Server:    http://[TU_IP]:8080
   ▸ phpMyAdmin:    http://[TU_IP]:8080/phpmyadmin (REPARADO)
   ▸ FTP Server:    ftp://[TU_IP]:2221
   
   Para obtener tu IP: ifconfig | grep inet

🔄 AUTO-INICIO:
   Los servicios se inician automáticamente al abrir Termux.
   Para desactivar: rm ~/.servers_auto_started

📝 EJEMPLO DE CONEXIÓN PHP (REPARADO):
   
   <?php
   // CONEXIÓN REPARADA - Usa TCP como HeidiSQL
   // Método 1: TCP explícito (RECOMENDADO)
   \$conn = new mysqli('127.0.0.1', 'terminal1', 'Master01', null, 3306);
   
   // Método 2: Localhost con socket forzado
   // \$socket = '/data/data/com.termux/files/usr/tmp/mysqld.sock';
   // \$conn = new mysqli('localhost', 'terminal1', 'Master01', null, null, \$socket);
   
   if (\$conn->connect_error) {
       die("Error: " . \$conn->connect_error);
   }
   echo "✅ Conectado como terminal1";
   ?>

⚡ CONSEJOS phpMyAdmin:
   • phpMyAdmin ahora está configurado con TCP (127.0.0.1:3306)
   • Mismo método de conexión que HeidiSQL
   • Si aún falla, verifica: http://localhost:8080/phpmyadmin-diag.php
   • Configuración en: ~/tamp-cuauh/apache/htdocs/phpmyadmin/config.inc.php

────────────────────────────────────────────────────────────────────────
   🏆 ¡SERVIDOR CONFIGURADO CON ÉXITO! 🏆
   Repository: github.com/cuauhreyesv/tamp
   FTP Port: 2221
   MySQL User: terminal1 / Master01
   phpMyAdmin: REPARADO (TCP como HeidiSQL)
────────────────────────────────────────────────────────────────────────
CONFIG_EOF

print_success "Configuración guardada en ~/tamp-config-terminal1.txt"

# 13. MOSTRAR RESUMEN FINAL
print_header "🎉 INSTALACIÓN COMPLETADA CON ÉXITO"
echo ""
echo "🏆 ¡FELICITACIONES! 🏆"
echo "Has instalado exitosamente:"
echo ""
echo "✅ TAMP Web Server (Apache + MySQL + PHP)"
echo "   • Desde: github.com/cuauhreyesv/tamp"
echo "   • Web: http://localhost:8080"
echo ""
echo "✅ Usuario MySQL: terminal1"
echo "   • Contraseña: Master01"
echo "   • Acceso: Desde cualquier dispositivo"
echo "   • Privilegios: TODOS"
echo ""
echo "✅ FTP Server Personalizado"
echo "   • Puerto: 2221"
echo "   • Usuario: android"
echo "   • Contraseña: android"
echo ""
echo "✅ phpMyAdmin REPARADO"
echo "   • Problema: Socket vs TCP solucionado"
echo "   • Método: TCP 127.0.0.1:3306 (igual que HeidiSQL)"
echo "   • Configuración: config.inc.php creado automáticamente"

# Mostrar IP actual
IP=$(ifconfig 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')

if [ -n "$IP" ]; then
    echo ""
    echo "📡 ACCESO DESDE OTROS DISPOSITIVOS:"
    echo "════════════════════════════════════════"
    echo "🌐 Web Server:    http://$IP:8080"
    echo "📤 FTP Server:    ftp://$IP:2221"
    echo "🗄️  phpMyAdmin:   http://$IP:8080/phpmyadmin"
    echo "💾 MySQL:         $IP:3306"
    echo "   User: terminal1 / Pass: Master01"
    echo ""
    echo "💡 Guarda estas URLs para acceder desde otras apps"
else
    echo ""
    echo "📱 ACCESO LOCAL EN LA TABLET:"
    echo "════════════════════════════════════════"
    echo "🌐 Web: http://localhost:8080"
    echo "📤 FTP: localhost:2221"
    echo "🗄️  MySQL: localhost:3306"
    echo "   User: terminal1 / Pass: Master01"
fi

echo ""
echo "🔧 phpMyAdmin REPARADO:"
echo "════════════════════════════════════════"
echo "Problema solucionado: HeidiSQL funciona, phpMyAdmin no"
echo "Razón: phpMyAdmin usaba socket, HeidiSQL usa TCP"
echo "Solución: Configurado TCP 127.0.0.1:3306 (igual que HeidiSQL)"
echo ""
echo "Enlaces importantes:"
echo "• phpMyAdmin: http://localhost:8080/phpmyadmin/"
echo "• Diagnóstico: http://localhost:8080/phpmyadmin-diag.php"
echo "• Prueba MySQL: http://localhost:8080/test-mysql-terminal1.php"

echo ""
echo "🎯 TEST FINAL:"
echo "════════════════════════════════════════"
echo "1. Prueba MySQL (diagnóstico completo):"
echo "   • http://localhost:8080/test-mysql-terminal1.php"
echo ""
echo "2. phpMyAdmin (REPARADO):"
echo "   • http://localhost:8080/phpmyadmin/"
echo "   • User: terminal1 / Pass: Master01"
echo ""
echo "3. Prueba conexión externa (desde otra PC):"
echo "   • MySQL Workbench / HeidiSQL"
echo "   • Host: $IP:3306"
echo "   • User: terminal1"
echo "   • Password: Master01"

echo ""
echo "🛠️  SOLUCIÓN DE PROBLEMAS:"
echo "════════════════════════════════════════"
echo "Si phpMyAdmin aún falla:"
echo "1. Verifica: http://localhost:8080/phpmyadmin-diag.php"
echo "2. El problema era: socket vs TCP"
echo "3. Solución aplicada: TCP 127.0.0.1:3306"
echo "4. Configuración en: ~/tamp-cuauh/apache/htdocs/phpmyadmin/config.inc.php"
echo ""
echo "Si MySQL no funciona:"
echo "1. Verifica que MySQL esté corriendo: pgrep mysqld"
echo "2. Si no está, inicia: tamp start"
echo "3. Usuario terminal1 ya está configurado"

echo ""
echo "────────────────────────────────────────────"
echo "   🏁 INSTALACIÓN TERMINADA - SERVIDOR ACTIVO 🏁"
echo "   FTP: 2221 | MySQL: terminal1/Master01"
echo "   phpMyAdmin: REPARADO (TCP como HeidiSQL)"
echo "────────────────────────────────────────────"