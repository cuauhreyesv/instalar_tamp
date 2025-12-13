#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# INSTALADOR TAMP + FTP CON AUTO-INICIO
# REPOSITORIO: https://github.com/cuauhreyesv/tamp.git
# PUERTO FTP: 2221
# USUARIO MYSQL: terminal1 / Master01
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
# Función para configurar usuario MySQL
configure_mysql_user() {
    print_header "CONFIGURANDO USUARIO MYSQL: TERMINAL1"
    # Esperar a que MySQL esté listo
    sleep 5
    # Intentar conexión sin contraseña (root por defecto en TAMP)
    echo "⏳ Configurando usuario TERMINAL1..."
    # Crear usuario con acceso desde cualquier host
    mysql -u root << MYSQL_EOF 2>/dev/null
-- Crear usuario con acceso desde cualquier dispositivo (todos los hosts)
CREATE USER IF NOT EXISTS 'TERMINAL1'@'%' IDENTIFIED BY 'Master01';
-- Otorgar todos los privilegios
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'%' WITH GRANT OPTION;
-- Crear también usuario local
CREATE USER IF NOT EXISTS 'TERMINAL1'@'localhost' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'localhost' WITH GRANT OPTION;
-- Aplicar cambios
FLUSH PRIVILEGES;
MYSQL_EOF
    if [ $? -eq 0 ]; then
        print_success "Usuario TERMINAL1 creado con éxito"
        print_info "Usuario: TERMINAL1"
        print_info "Contraseña: Master01"
        print_info "Acceso: Desde cualquier dispositivo (%)"
        print_info "Privilegios: TODOS (WITH GRANT OPTION)"
    else
        print_warning "Intentando método alternativo..."
        # Método alternativo usando mysqladmin
        mysqladmin -u root password '' 2>/dev/null
        sleep 2
        mysql -u root << MYSQL_EOF2 2>/dev/null
CREATE USER 'TERMINAL1'@'%' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'%';
CREATE USER 'TERMINAL1'@'localhost' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF2
        if [ $? -eq 0 ]; then
            print_success "Usuario TERMINAL1 creado (método alternativo)"
        else
            print_error "No se pudo crear el usuario. Configúralo manualmente:"
            echo "1. Acceder a MySQL: mysql -u root"
            echo "2. Ejecutar: CREATE USER 'TERMINAL1'@'%' IDENTIFIED BY 'Master01';"
            echo "3. Ejecutar: GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'%' WITH GRANT OPTION;"
            echo "4. Ejecutar: FLUSH PRIVILEGES;"
        fi
    fi
    # Verificar usuario creado
    echo ""
    print_info "Verificando usuario creado..."
    mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='TERMINAL1';" 2>/dev/null
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
# 3. CONFIGURAR USUARIO MYSQL: TERMINAL1
configure_mysql_user
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
# 2. CONFIGURAR USUARIO MYSQL (si no existe)
echo ""
echo "🗄️  Configurando usuario MySQL..."
mysql -u root << 'MYSQL_CONFIG_EOF' 2>/dev/null
CREATE USER IF NOT EXISTS 'TERMINAL1'@'%' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL1'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'TERMINAL1'@'localhost' IDENTIFIED BY 'Master01';
GRANT ALL PRIVILEGES ON *.* TO 'TERMINAL'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_CONFIG_EOF
echo "✅ Usuario MySQL configurado:"
echo "   • Usuario: TERMINAL1"
echo "   • Contraseña: Master01"
echo "   • Acceso: Desde cualquier dispositivo (%)"
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
echo "   • Usuario root: (sin contraseña)"
echo "   • Usuario: TERMINAL1"
echo "   • Contraseña: Master01"
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
echo "Usuario: TERMINAL1"
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
# CON USUARIO MYSQL: TERMINAL1/Master01
# ============================================
if [ -f ~/auto-start-all ] && [ ! -f ~/.servers_auto_started ]; then
    echo ""
    echo "🔄 Iniciando servidores automáticamente..."
    echo "   • TAMP Web Server"
    echo "   • MySQL con usuario: TERMINAL1"
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
# Verificar usuario MySQL
echo ""
echo "🗄️  VERIFICANDO USUARIO MYSQL:"
echo "════════════════════════════════════════"
if mysql -u TERMINAL1 -pMaster01 -e "SELECT '✅ Usuario TERMINAL1 funciona correctamente' as Status;" 2>/dev/null; then
    echo "✅ Usuario TERMINAL1: Configurado y funcionando"
    echo "   • Acceso local: OK"
    echo "   • Contraseña: Master01"
    # Mostrar hosts permitidos
    mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='TERMINAL1';" 2>/dev/null
else
    echo "⚠️  Usuario TERMINAL1: Necesita configuración manual"
fi
echo ""
echo "🌐 PRUEBA DE CONEXIÓN WEB:"
echo "════════════════════════════════════════"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo "✅ Web Server responde correctamente"
else
    echo "⚠️  Web Server no responde como esperado"
fi
# 9. CREAR ARCHIVO DE CONFIGURACIÓN MEJORADO
print_header "CREANDO DOCUMENTACIÓN DEL SISTEMA"
cat > ~/tamp-config-terminal1.txt << 'CONFIG_EOF'
╔════════════════════════════════════════════════════════════════════╗
║                 🚀 TAMP SERVER CONFIG v2.0 🚀                     ║
║              Repositorio: cuauhreyesv/tamp                        ║
║                FTP Personalizado: 2221                            ║
║                MySQL User: TERMINAL1 / Master01                   ║
╚════════════════════════════════════════════════════════════════════╝
📍 DIRECTORIOS PRINCIPALES:
   • Proyectos Web:    /sdcard/htdocs/
   • Instalación TAMP: ~/tamp-cuauh/
   • Logs Apache:      ~/tamp-cuauh/logs/
   • Logs FTP:         ~/ftp.log
🔧 CONFIGURACIÓN DE PUERTOS:
   • Apache HTTP:      8080
   • Apache HTTPS:     8443 (SSL)
   • MySQL/MariaDB:    3306
   • FTP Server:       2221 ← PERSONALIZADO
👤 CREDENCIALES DE ACCESO:
   MySQL/phpMyAdmin:
      ▸ Usuario root:      (sin contraseña)
      ▸ Usuario TERMINAL1: Master01
      ▸ Acceso:            Desde cualquier dispositivo (%)
      ▸ Privilegios:       TODOS (WITH GRANT OPTION)
      ▸ phpMyAdmin URL:    http://localhost:8080/phpmyadmin
   FTP Server:
      ▸ Puerto:    2221
      ▸ Usuario:   android
      ▸ Password:  android
      ▸ Directorio: /sdcard/htdocs
🚀 COMANDOS DE CONTROL:
   ▸ tamp start          # Iniciar servidor web
   ▸ tamp stop           # Detener servidor web
   ▸ tamp start-ssl      # Iniciar con SSL (8443)
   ▸ ~/tamp-ftp-2221    # Iniciar FTP (puerto 2221)
   ▸ ~/auto-start-all   # Iniciar todos los servicios
   ▸ pkill -f pyftpdlib # Detener FTP
🔌 CONEXIÓN EXTERNA A MYSQL:
   ▸ Host:       [IP_DEL_DISPOSITIVO]
   ▸ Puerto:     3306
   ▸ Usuario:    TERMINAL1
   ▸ Contraseña: Master01
   ▸ Acceso:     Desde cualquier red (%)
   Ejemplo Workbench/HeidiSQL:
      Host: 192.168.1.100:3306
      User: TERMINAL1
      Pass: Master01
📡 ACCESO DESDE RED:
   ▸ Web Server:    http://[TU_IP]:8080
   ▸ phpMyAdmin:    http://[TU_IP]:8080/phpmyadmin
   ▸ FTP Server:    ftp://[TU_IP]:2221
   Para obtener tu IP: ifconfig | grep inet
🔄 AUTO-INICIO:
   Los servicios se inician automáticamente al abrir Termux.
   Para desactivar: rm ~/.servers_auto_started
🔐 CONFIGURACIÓN MYSQL AVANZADA:
   El usuario 'TERMINAL1' tiene:
   • Acceso desde: '%' (todos los hosts)
   • Privilegios: ALL PRIVILEGES
   • WITH GRANT OPTION (puede crear otros usuarios)
📝 EJEMPLO DE CONEXIÓN PHP:
   <?php
   \$host = 'IP_DEL_SERVIDOR'; // o 'localhost' para acceso interno
   \$user = 'TERMINAL1';
   \$pass = 'Master01';
   \$db = 'tu_basedatos';
   \$conn = new mysqli(\$host, \$user, \$pass, \$db);
   if (\$conn->connect_error) {
       die("Error: " . \$conn->connect_error);
   }
   echo "✅ Conectado como TERMINAL1";
   ?>
⚡ CONSEJOS RÁPIDOS:
   • Usa 'TERMINAL1' para conexiones externas
   • Usa 'root' sin contraseña para administración local
   • El puerto 3306 debe estar accesible en la red
   • Verifica firewall del dispositivo si hay problemas
────────────────────────────────────────────────────────────────────────
   🏆 ¡SERVIDOR CONFIGURADO CON ÉXITO! 🏆
   Repository: github.com/cuauhreyesv/tamp
   FTP Port: 2221
   MySQL User: TERMINAL1 / Master01
────────────────────────────────────────────────────────────────────────
CONFIG_EOF
print_success "Configuración guardada en ~/tamp-config-terminal1.txt"
# 10. MOSTRAR RESUMEN FINAL
print_header "🎉 INSTALACIÓN COMPLETADA CON ÉXITO"
echo ""
echo "🏆 ¡FELICITACIONES! 🏆"
echo "Has instalado exitosamente:"
echo ""
echo "✅ TAMP Web Server (Apache + MySQL + PHP)"
echo "   • Desde: github.com/cuauhreyesv/tamp"
echo "   • Web: http://localhost:8080"
echo ""
echo "✅ Usuario MySQL: TERMINAL1"
echo "   • Contraseña: Master01"
echo "   • Acceso: Desde cualquier dispositivo"
echo "   • Privilegios: TODOS"
echo ""
echo "✅ FTP Server Personalizado"
echo "   • Puerto: 2221"
echo "   • Usuario: android"
echo "   • Contraseña: android"
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
    echo "   User: TERMINAL1 / Pass: Master01"
    echo ""
    echo "💡 Guarda estas URLs para acceder desde otras apps"
else
    echo ""
    echo "📱 ACCESO LOCAL EN LA TABLET:"
    echo "════════════════════════════════════════"
    echo "🌐 Web: http://localhost:8080"
    echo "📤 FTP: localhost:2221"
    echo "🗄️  MySQL: localhost:3306"
    echo "   User: TERMINAL1 / Pass: Master01"
fi
# 11. CREAR ARCHIVO DE PRUEBA CON CONEXIÓN MYSQL
print_header "CREANDO ARCHIVO DE PRUEBA CON CONEXIÓN MYSQL"
cat > /sdcard/htdocs/test-mysql-terminal1.php << 'TEST_MYSQL_EOF'
<?php
// Test MySQL Connection with TERMINAL1 user
echo "<!DOCTYPE html>";
echo "<html>";
echo "<head>";
echo "<title>✅ TAMP Server - MySQL TERMINAL1 Test</title>";
echo "<style>";
echo "body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }";
echo ".container { max-width: 800px; margin: 0 auto; background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; backdrop-filter: blur(10px); }";
echo "h1 { text-align: center; color: #4CAF50; }";
echo ".success { background: #10b981; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".error { background: #ef4444; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".info-box { background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; margin: 10px 0; }";
echo "pre { background: rgba(0,0,0,0.3); padding: 10px; border-radius: 5px; overflow-x: auto; }";
echo "</style>";
echo "</head>";
echo "<body>";
echo "<div class='container'>";
echo "<h1>🔌 PRUEBA DE CONEXIÓN MYSQL - TERMINAL1</h1>";
// Configuración de conexión
$host = 'localhost';
$user = 'TERMINAL1';
$pass = 'Master01';
$db = 'test_db';
// Intentar conexión
echo "<div class='info-box'>";
echo "<h3>🔧 Configuración de conexión:</h3>";
echo "<pre>";
echo "Host: $host\n";
echo "Usuario: $user\n";
echo "Contraseña: $pass\n";
echo "Base de datos: $db";
echo "</pre>";
echo "</div>";
// Conexión 1: Local con TERMINAL1
echo "<div class='info-box'>";
echo "<h3>🔗 Prueba 1: Conexión local con TERMINAL1</h3>";
$conn1 = new mysqli($host, $user, $pass);
if ($conn1->connect_error) {
    echo "<div class='error'>❌ Error: " . $conn1->connect_error . "</div>";
} else {
    echo "<div class='success'>✅ ¡Conectado exitosamente como TERMINAL1!</div>";
    // Mostrar información del servidor
    echo "<p><strong>Servidor MySQL:</strong> " . $conn1->server_info . "</p>";
    echo "<p><strong>Host:</strong> " . $conn1->host_info . "</p>";
    // Crear base de datos de prueba
    if ($conn1->query("CREATE DATABASE IF NOT EXISTS test_db")) {
        echo "<p><strong>Base de datos:</strong> test_db creada</p>";
    }
    $conn1->close();
}
echo "</div>";
// Mostrar IP para conexión externa
$ip = shell_exec('ifconfig 2>/dev/null | grep -oE "inet ([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v "127.0.0.1" | head -1 | awk "{print \$2}"');
$ip = trim($ip ?: 'localhost');
echo "<div class='info-box'>";
echo "<h3>🌐 Conexión desde otros dispositivos:</h3>";
echo "<pre>";
echo "Para conectar desde otra PC/app:\n";
echo "Host: $ip\n";
echo "Puerto: 3306\n";
echo "Usuario: TERMINAL1\n";
echo "Contraseña: Master01\n";
echo "\nEjemplo en PHP:\n";
echo "\$conn = new mysqli('$ip', 'TERMINAL1', 'Master01');";
echo "</pre>";
echo "</div>";
echo "<div class='success'>";
echo "🎯 ¡Usuario TERMINAL1 configurado para acceso desde cualquier dispositivo!";
echo "</div>";
echo "</div>";
echo "</body>";
echo "</html>";
?>
TEST_MYSQL_EOF
print_success "Archivo de prueba creado: /sdcard/htdocs/test-mysql-terminal1.php"
echo ""
echo "🎯 TEST FINAL:"
echo "════════════════════════════════════════"
echo "1. Prueba MySQL:"
echo "   • http://localhost:8080/test-mysql-terminal1.php"
echo ""
echo "2. Prueba conexión externa (desde otra PC):"
echo "   • MySQL Workbench / HeidiSQL"
echo "   • Host: $IP:3306"
echo "   • User: TERMINAL1"
echo "   • Password: Master01"
echo ""
echo "3. phpMyAdmin:"
echo "   • http://localhost:8080/phpmyadmin"
echo "   • User: TERMINAL1 / Pass: Master01"
echo ""
echo "🛠️  SOLUCIÓN DE PROBLEMAS:"
echo "════════════════════════════════════════"
echo "Si no puedes conectar externamente:"
echo "1. Verificar que el puerto 3306 esté accesible"
echo "2. En MySQL:"
echo "   mysql -u root"
echo "   SELECT User, Host FROM mysql.user;"
echo "3. Agregar usuario si falta:"
echo "   CREATE USER 'TERMINAL1'@'%' IDENTIFIED BY 'Master01';"
echo "   GRANT ALL PRIVILEGES ON *.* TO 'terminal1'@'%';"
echo "   FLUSH PRIVILEGES;"
echo ""
echo "────────────────────────────────────────────"
echo "   🏁 INSTALACIÓN TERMINADA - SERVIDOR ACTIVO 🏁"
echo "   FTP: 2221 | MySQL: TERMINAL1/Master01"
echo "   Acceso desde cualquier dispositivo"
echo "────────────────────────────────────────────"