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

# 8. VERIFICACIÓN COMPLETA (SECCIÓN CRÍTICA CORREGIDA)
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

# 9. CREAR ARCHIVO DE CONFIGURACIÓN MEJORADO
print_header "CREANDO DOCUMENTACIÓN DEL SISTEMA"

cat > ~/tamp-config-terminal1.txt << 'CONFIG_EOF'
╔════════════════════════════════════════════════════════════════════╗
║                 🚀 TAMP SERVER CONFIG v2.0 🚀                     ║
║              Repositorio: cuauhreyesv/tamp                        ║
║                FTP Personalizado: 2221                            ║
║                MySQL User: terminal1 / Master01                   ║
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
      ▸ Usuario root:      (sin contraseña por defecto)
      ▸ Usuario terminal1: Master01
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
   ▸ Usuario:    terminal1
   ▸ Contraseña: Master01
   ▸ Acceso:     Desde cualquier red (%)

   Ejemplo Workbench/HeidiSQL:
      Host: 192.168.1.100:3306
      User: terminal1
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
   El usuario 'terminal1' tiene:
   • Acceso desde: '%' (todos los hosts)
   • Privilegios: ALL PRIVILEGES
   • WITH GRANT OPTION (puede crear otros usuarios)

📝 EJEMPLO DE CONEXIÓN PHP:
   
   <?php
   // Para conexión local:
   \$conn = new mysqli('localhost', 'terminal1', 'Master01');
   
   // Para conexión desde otro dispositivo:
   // \$conn = new mysqli('[IP_DEL_SERVIDOR]', 'terminal1', 'Master01');
   
   if (\$conn->connect_error) {
       die("Error: " . \$conn->connect_error);
   }
   echo "✅ Conectado como terminal1";
   ?>

⚡ CONSEJOS RÁPIDOS:
   • Si root no tiene contraseña vacía, busca en ~/tamp-cuauh/logs/
   • Usa 'terminal1' para conexiones externas
   • El puerto 3306 debe estar accesible en la red
   • Verifica firewall del dispositivo si hay problemas

────────────────────────────────────────────────────────────────────────
   🏆 ¡SERVIDOR CONFIGURADO CON ÉXITO! 🏆
   Repository: github.com/cuauhreyesv/tamp
   FTP Port: 2221
   MySQL User: terminal1 / Master01
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
echo "✅ Usuario MySQL: terminal1"
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

# 11. CREAR ARCHIVO DE PRUEBA CON CONEXIÓN MYSQL (MEJORADO)
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

// Método 1: Conexión estándar
echo "<div class='info-box'>";
echo "<h3>🔧 Método 1: Conexión estándar (localhost)</h3>";

$conn1 = @new mysqli('localhost', 'terminal1', 'Master01');
if ($conn1->connect_error) {
    echo "<div class='error'>❌ Error: " . $conn1->connect_error . "</div>";
    
    // Diagnóstico del error
    if (strpos($conn1->connect_error, 'No such file') !== false) {
        echo "<div class='warning'>⚠️  Posible solución: MySQL no está corriendo o socket no encontrado</div>";
        echo "<pre>Ejecuta en Termux: tamp start  o  mysqld_safe --user=root &</pre>";
    }
} else {
    echo "<div class='success'>✅ ¡Conectado exitosamente como terminal1!</div>";
    echo "<p><strong>MySQL Version:</strong> " . $conn1->server_info . "</p>";
    echo "<p><strong>Host Info:</strong> " . $conn1->host_info . "</p>";
    $conn1->close();
}
echo "</div>";

// Método 2: Conexión con socket específico
echo "<div class='info-box'>";
echo "<h3>🔧 Método 2: Conexión con socket específico</h3>";

// Socket común en Termux/TAMP
$socket_path = '/data/data/com.termux/files/usr/tmp/mysqld.sock';
if (file_exists($socket_path)) {
    echo "<p>Socket encontrado en: <code>$socket_path</code></p>";
    $conn2 = @new mysqli('localhost', 'terminal1', 'Master01', null, null, $socket_path);
    if ($conn2->connect_error) {
        echo "<div class='error'>❌ Error con socket: " . $conn2->connect_error . "</div>";
    } else {
        echo "<div class='success'>✅ ¡Conectado via socket!</div>";
        $conn2->close();
    }
} else {
    echo "<div class='warning'>⚠️  Socket no encontrado en ruta esperada</div>";
}
echo "</div>";

// Método 3: Probar como root
echo "<div class='info-box'>";
echo "<h3>🔧 Método 3: Probar conexión root (diagnóstico)</h3>";

$conn3 = @new mysqli('localhost', 'root', '');
if ($conn3->connect_error) {
    echo "<div class='error'>❌ Root sin contraseña falló: " . $conn3->connect_error . "</div>";
    
    // Intentar con contraseña vacía explícita
    $conn3b = @new mysqli('localhost', 'root', '');
    if ($conn3b->connect_error) {
        echo "<div class='warning'>⚠️  Root necesita contraseña. Busca en ~/tamp-cuauh/logs/</div>";
    }
} else {
    echo "<div class='success'>✅ Root conectado - MySQL funciona</div>";
    echo "<p><strong>MySQL Version:</strong> " . $conn3->server_info . "</p>";
    $conn3->close();
}
echo "</div>";

// Información del sistema
echo "<div class='info-box'>";
echo "<h3>📊 Información del sistema</h3>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>MySQLi socket:</strong> " . ini_get('mysqli.default_socket') . "</p>";

// Verificar procesos MySQL
echo "<p><strong>Procesos MySQL activos:</strong> ";
$mysql_processes = shell_exec('pgrep mysqld 2>/dev/null | wc -l');
echo trim($mysql_processes) . " proceso(s)</p>";

if (trim($mysql_processes) == '0') {
    echo "<div class='warning'>⚠️  MySQL NO está ejecutándose</div>";
}
echo "</div>";

echo "<div class='success'>";
echo "🎯 Script de diagnóstico completo";
echo "</div>";

echo "</div>";
echo "</body>";
echo "</html>";
?>
TEST_MYSQL_EOF

print_success "Archivo de prueba MEJORADO creado: /sdcard/htdocs/test-mysql-terminal1.php"

echo ""
echo "🎯 TEST FINAL:"
echo "════════════════════════════════════════"
echo "1. Prueba MySQL (diagnóstico completo):"
echo "   • http://localhost:8080/test-mysql-terminal1.php"
echo ""
echo "2. Prueba conexión externa (desde otra PC):"
echo "   • MySQL Workbench / HeidiSQL"
echo "   • Host: $IP:3306"
echo "   • User: terminal1"
echo "   • Password: Master01"
echo ""
echo "3. phpMyAdmin:"
echo "   • http://localhost:8080/phpmyadmin"
echo "   • User: terminal1 / Pass: Master01"

echo ""
echo "🛠️  SOLUCIÓN DE PROBLEMAS:"
echo "════════════════════════════════════════"
echo "Si MySQL no funciona:"
echo "1. Verifica que MySQL esté corriendo: pgrep mysqld"
echo "2. Si no está, inicia: tamp start"
echo "3. Si root tiene contraseña, descúbrela:"
echo "   grep -r password ~/tamp-cuauh/logs/ 2>/dev/null"
echo "4. Para resetear contraseña root:"
echo "   pkill mysqld"
echo "   mysqld_safe --skip-grant-tables &"
echo "   mysql -u root"
echo "   FLUSH PRIVILEGES;"
echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY '';"
echo "   FLUSH PRIVILEGES;"

echo ""
echo "────────────────────────────────────────────"
echo "   🏁 INSTALACIÓN TERMINADA - SERVIDOR ACTIVO 🏁"
echo "   FTP: 2221 | MySQL: terminal1/Master01"
echo "   Acceso desde cualquier dispositivo"
echo "────────────────────────────────────────────"