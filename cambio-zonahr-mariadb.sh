#!/data/data/com.termux/files/usr/bin/bash
echo "📱 CORRECCIÓN ZONA HORARIA - ANDROID/TERMUX"

# 1. Cambiar zona horaria de Termux
export TZ='America/Mexico_City'
echo "export TZ='America/Mexico_City'" >> ~/.bashrc
echo "export TZ='America/Mexico_City'" >> ~/.profile

# 2. Configurar PHP en Termux
PHP_INI="/data/data/com.termux/files/usr/etc/php.ini"
if [ -f "$PHP_INI" ]; then
    sed -i "s/^;*date.timezone.*/date.timezone = America\\/Mexico_City/" "$PHP_INI"
else
    echo "date.timezone = America/Mexico_City" > "$PHP_INI"
fi

# 3. Configurar MySQL en Termux
MYSQL_CONF="/data/data/com.termux/files/usr/etc/my.cnf"
cat > "$MYSQL_CONF" << 'MYSQL_EOF'
[mysqld]
default-time-zone = '-06:00'
socket = /data/data/com.termux/files/usr/tmp/mysqld.sock

[client]
socket = /data/data/com.termux/files/usr/tmp/mysqld.sock
default-time-zone = '-06:00'
MYSQL_EOF

# 4. Reiniciar servicios
pkill -f mysqld
sleep 2
mysqld_safe &

# 5. Configurar MySQL internamente
sleep 5
mysql -u $(whoami) << 'SQL_EOF'
SET GLOBAL time_zone = '-06:00';
SET time_zone = '-06:00';
SELECT NOW(), DATE(NOW()), @@global.time_zone;
SQL_EOF

# 6. Crear archivo de prueba PHP
cat > ~/test_fecha.php << 'PHP_EOF'
<?php
date_default_timezone_set('America/Mexico_City');
echo "Fecha PHP: " . date('Y-m-d H:i:s') . "\n";
echo "Fecha que necesitamos: 2025-12-27\n";
echo "¿Coinciden? " . (date('Y-m-d') == '2025-12-27' ? '✅ SÍ' : '❌ NO');
?>
PHP_EOF

echo "✅ Configuración completada"
echo "📅 Verificar: php ~/test_fecha.php"