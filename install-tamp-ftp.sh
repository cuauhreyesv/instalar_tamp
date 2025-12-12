#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# INSTALADOR TAMP + FTP CON AUTO-INICIO
# REPOSITORIO: https://github.com/cuauhreyesv/tamp.git
# PUERTO FTP: 2221
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
    echo "╔══════════════════════════════════════════════╗"
    echo "║      🚀 TAMP SERVER INSTALLER v2.0 🚀       ║"
    echo "║         Repo: cuauhreyesv/tamp              ║"
    echo "║         FTP Port: 2221                      ║"
    echo "╚══════════════════════════════════════════════╝"
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
# 3. INSTALAR FTP CON PUERTO 2221
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
# 4. CREAR SCRIPT DE AUTO-INICIO MEJORADO
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
# 2. INICIAR FTP EN SEGUNDO PLANO
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
# 3. MOSTRAR RESUMEN
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
echo "   • MySQL User: root (sin contraseña)"
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
# 5. CONFIGURAR AUTO-INICIO EN .BASHRC
print_header "CONFIGURANDO INICIO AUTOMÁTICO EN TERMUX"
# Crear versión mejorada del auto-inicio para .bashrc
cat >> ~/.bashrc << 'BASHRC_EOF'
# ============================================
# AUTO-INICIO TAMP + FTP (2221)
# ============================================
if [ -f ~/auto-start-all ] && [ ! -f ~/.servers_auto_started ]; then
    echo ""
    echo "🔄 Iniciando servidores automáticamente..."
    echo "   • TAMP Web Server"
    echo "   • FTP Server (puerto 2221)"
    echo ""
    touch ~/.servers_auto_started
    # Ejecutar en segundo plano para no bloquear terminal
    (~/auto-start-all > ~/startup.log 2>&1 &)
fi
BASHRC_EOF
print_success "Auto-inicio configurado en ~/.bashrc"
# 6. EJECUTAR SERVICIOS AHORA MISMO
print_header "INICIANDO SERVICIOS POR PRIMERA VEZ"
echo "⏳ Iniciando TAMP + FTP (2221)..."
echo "   Esto tomará aproximadamente 10 segundos"
# Ejecutar auto-inicio
~/auto-start-all &
# Esperar a que todo inicie
sleep 10
# 7. VERIFICACIÓN COMPLETA
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
echo ""
echo "🌐 PRUEBA DE CONEXIÓN WEB:"
echo "════════════════════════════════════════"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo "✅ Web Server responde correctamente"
else
    echo "⚠️  Web Server no responde como esperado"
fi
# 8. CREAR ARCHIVO DE CONFIGURACIÓN MEJORADO
print_header "CREANDO DOCUMENTACIÓN DEL SISTEMA"
cat > ~/tamp-config-2221.txt << 'CONFIG_EOF'
╔══════════════════════════════════════════════════════════╗
║                 🚀 TAMP SERVER CONFIG v2.0 🚀            ║
║              Repositorio: cuauhreyesv/tamp              ║
║                FTP Personalizado: 2221                  ║
╚══════════════════════════════════════════════════════════╝
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
      ▸ URL:      http://localhost:8080/phpmyadmin
      ▸ Usuario:  root
      ▸ Password: (dejar vacío)
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
📡 ACCESO DESDE RED:
   ▸ Web Server:    http://[TU_IP]:8080
   ▸ phpMyAdmin:    http://[TU_IP]:8080/phpmyadmin
   ▸ FTP Server:    ftp://[TU_IP]:2221
   Para obtener tu IP: ifconfig | grep inet
🔄 AUTO-INICIO:
   Los servicios se inician automáticamente al abrir Termux.
   Para desactivar: rm ~/.servers_auto_started
📝 EJEMPLO DE USO:
   1. Subir archivo con FileZilla a ftp://[IP]:2221
   2. Archivo se guarda en: /sdcard/htdocs/mi_app.php
   3. Acceder desde: http://localhost:8080/mi_app.php
⚡ CONSEJOS RÁPIDOS:
   • Siempre guarda archivos en /sdcard/htdocs/
   • Usa FileZilla para transferencias FTP
   • Para desarrollo, accede vía http://localhost:8080/
   • Para producción, usa la IP de tu dispositivo
────────────────────────────────────────────────────────────
   🏆 ¡SERVIDOR CONFIGURADO CON ÉXITO! 🏆
   Repository: github.com/cuauhreyesv/tamp
   FTP Port: 2221
────────────────────────────────────────────────────────────
CONFIG_EOF
print_success "Configuración guardada en ~/tamp-config-2221.txt"
# 9. MOSTRAR RESUMEN FINAL
print_header "🎉 INSTALACIÓN COMPLETADA CON ÉXITO"
echo ""
echo "🏆 ¡FELICITACIONES! 🏆"
echo "Has instalado exitosamente:"
echo ""
echo "✅ TAMP Web Server (Apache + MySQL + PHP)"
echo "   • Desde: github.com/cuauhreyesv/tamp"
echo "   • Web: http://localhost:8080"
echo ""
echo "✅ FTP Server Personalizado"
echo "   • Puerto: 2221 (Personalizado)"
echo "   • Usuario: android"
echo "   • Contraseña: android"
echo ""
# Mostrar IP actual
IP=$(ifconfig 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
if [ -n "$IP" ]; then
    echo "📡 ACCESO DESDE OTROS DISPOSITIVOS:"
    echo "════════════════════════════════════════"
    echo "🌐 Web Server:    http://$IP:8080"
    echo "📤 FTP Server:    ftp://$IP:2221"
    echo "🗄️  phpMyAdmin:   http://$IP:8080/phpmyadmin"
    echo ""
    echo "💡 Guarda estas URLs para acceder desde otras apps"
else
    echo "📱 ACCESO LOCAL EN LA TABLET:"
    echo "════════════════════════════════════════"
    echo "🌐 Web: http://localhost:8080"
    echo "📤 FTP: localhost:2221"
fi
echo ""
echo "🔧 PRUEBA RÁPIDA:"
echo "════════════════════════════════════════"
echo "1. Crear archivo de prueba:"
echo "   echo '<?php echo \"¡Servidor funcionando! 🎉\"; ?>' > /sdcard/htdocs/test.php"
echo ""
echo "2. Acceder desde navegador:"
echo "   http://localhost:8080/test.php"
echo ""
echo "3. O desde otra app Android/PC:"
echo "   http://[IP-de-arriba]:8080/test.php"
echo ""
echo "📋 ARCHIVOS CREADOS:"
echo "════════════════════════════════════════"
echo "• ~/tamp-cuauh/        # Instalación TAMP"
echo "• ~/tamp-ftp-2221      # Script FTP (puerto 2221)"
echo "• ~/auto-start-all     # Auto-inicio servicios"
echo "• ~/tamp-config-2221.txt # Configuración completa"
echo "• ~/ftp.log           # Logs del servidor FTP"
echo ""
print_warning "⚠️  RECUERDA: Los servicios se iniciarán automáticamente"
echo "   cada vez que abras Termux."
# 10. CREAR TEST RÁPIDO
print_header "CREANDO ARCHIVO DE PRUEBA AUTOMÁTICO"
cat > /sdcard/htdocs/test-tamp-2221.php << 'TEST_EOF'
<?php
// Test TAMP Server with FTP 2221
echo "<!DOCTYPE html>";
echo "<html>";
echo "<head>";
echo "<title>✅ TAMP Server Test - Puerto FTP 2221</title>";
echo "<style>";
echo "body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }";
echo ".container { max-width: 800px; margin: 0 auto; background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; backdrop-filter: blur(10px); }";
echo "h1 { text-align: center; color: #4CAF50; }";
echo ".success { background: #10b981; padding: 15px; border-radius: 8px; text-align: center; font-size: 20px; margin: 20px 0; }";
echo ".info-box { background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; margin: 10px 0; }";
echo "</style>";
echo "</head>";
echo "<body>";
echo "<div class='container'>";
echo "<h1>🎉 ¡TAMP SERVER FUNCIONANDO! 🎉</h1>";
echo "<div class='success'>✅ Servidor configurado exitosamente</div>";
echo "";
echo "<div class='info-box'>";
echo "<h3>📊 Información del Sistema</h3>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>Server Software:</strong> " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p><strong>Document Root:</strong> " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p><strong>Remote Address:</strong> " . $_SERVER['REMOTE_ADDR'] . "</p>";
echo "</div>";
echo "";
echo "<div class='info-box'>";
echo "<h3>🔧 Configuración FTP</h3>";
echo "<p><strong>Puerto FTP:</strong> 2221 (Personalizado)</p>";
echo "<p><strong>Usuario FTP:</strong> android</p>";
echo "<p><strong>Contraseña FTP:</strong> android</p>";
echo "<p><strong>Directorio:</strong> /sdcard/htdocs/</p>";
echo "<p><strong>Repositorio:</strong> github.com/cuauhreyesv/tamp</p>";
echo "</div>";
echo "";
echo "<div class='info-box'>";
echo "<h3>🚀 Servicios Activos</h3>";
echo "<ul>";
echo "<li>🌐 Apache Web Server (Puerto: 8080)</li>";
echo "<li>🗄️ MySQL/MariaDB Database (Puerto: 3306)</li>";
echo "<li>📤 FTP Server (Puerto: 2221)</li>";
echo "<li>🔐 phpMyAdmin (http://localhost:8080/phpmyadmin)</li>";
echo "</ul>";
echo "</div>";
echo "";
echo "<div class='info-box'>";
echo "<h3>📁 Subir Archivos</h3>";
echo "<p>Usa FileZilla con:</p>";
echo "<pre>";
$ip = shell_exec('ifconfig 2>/dev/null | grep -oE "inet ([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v "127.0.0.1" | head -1 | awk "{print \$2}"');
echo "Host: " . trim($ip ?: "localhost") . "\n";
echo "Puerto: 2221\n";
echo "Usuario: android\n";
echo "Contraseña: android\n";
echo "Directorio: /sdcard/htdocs/";
echo "</pre>";
echo "</div>";
echo "";
echo "<div class='success'>";
echo "🎯 ¡Todo listo para desarrollar!";
echo "</div>";
echo "</div>";
echo "</body>";
echo "</html>";
?>
TEST_EOF
print_success "Archivo de prueba creado: /sdcard/htdocs/test-tamp-2221.php"
echo ""
echo "🎯 TEST FINAL:"
echo "════════════════════════════════════════"
echo "Visita en tu navegador:"
echo "• http://localhost:8080/test-tamp-2221.php"
echo ""
echo "O desde otra app/PC:"
echo "• http://[TU_IP]:8080/test-tamp-2221.php"
echo ""
echo "🛠️  SOLUCIÓN DE PROBLEMAS:"
echo "════════════════════════════════════════"
echo "Si FTP no inicia en puerto 2221:"
echo "1. Verificar si el puerto está libre:"
echo "   netstat -tuln | grep 2221"
echo "2. Cambiar puerto manualmente:"
echo "   Editar ~/tamp-ftp-2221 y cambiar -p 2221"
echo ""
echo "Para soporte: github.com/cuauhreyesv/tamp"
# 11. OPCIONAL: VER LOGS
echo ""
read -p "¿Ver logs de inicio? (s/n): " ver_logs
if [[ "$ver_logs" == "s" || "$ver_logs" == "S" ]]; then
    echo ""
    echo "📋 LOGS DE INICIO:"
    echo "════════════════════════════════════════"
    tail -20 ~/ftp.log 2>/dev/null || echo "Esperando logs..."
fi
echo ""
echo "────────────────────────────────────────────"
echo "   🏁 INSTALACIÓN TERMINADA - SERVIDOR ACTIVO 🏁"
echo "   FTP en puerto 2221 - Repo: cuauhreyesv/tamp"
echo "────────────────────────────────────────────"