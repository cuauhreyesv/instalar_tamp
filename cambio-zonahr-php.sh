#!/data/data/com.termux/files/usr/bin/bash
echo "🔧 CONFIGURANDO PHP PARA GMT-6"

# Buscar todos los php.ini
PHP_INI_FILES=$(find /data/data/com.termux/files/usr -name "php.ini" 2>/dev/null)

if [ -z "$PHP_INI_FILES" ]; then
    echo "📄 Creando php.ini..."
    PHP_INI="/data/data/com.termux/files/usr/etc/php.ini"
    mkdir -p "$(dirname "$PHP_INI")"
    echo "[PHP]" > "$PHP_INI"
    echo "date.timezone = America/Mexico_City" >> "$PHP_INI"
    echo "✅ Creado: $PHP_INI"
else
    echo "⚙️  Configurando archivos encontrados..."
    for php_ini in $PHP_INI_FILES; do
        echo "   📝 Procesando: $php_ini"
        
        # Hacer backup
        cp "$php_ini" "${php_ini}.backup"
        
        # Buscar y reemplazar o agregar
        if grep -q "^date.timezone" "$php_ini"; then
            sed -i 's/^date.timezone.*/date.timezone = America\/Mexico_City/' "$php_ini"
            echo "   ✅ date.timezone actualizado"
        elif grep -q "^;date.timezone" "$php_ini"; then
            sed -i 's/^;date.timezone.*/date.timezone = America\/Mexico_City/' "$php_ini"
            echo "   ✅ date.timezone descomentado y configurado"
        else
            # Agregar al final si no existe
            echo "" >> "$php_ini"
            echo "[Date]" >> "$php_ini"
            echo "date.timezone = America/Mexico_City" >> "$php_ini"
            echo "   ✅ date.timezone agregado"
        fi
    done
fi

# También crear .user.ini en directorio web
echo "🌐 Creando .user.ini en directorio web..."
mkdir -p /sdcard/htdocs
echo "date.timezone = America/Mexico_City" > /sdcard/htdocs/.user.ini
echo "date.timezone = America/Mexico_City" > ~/tamp-cuauh/apache/htdocs/.user.ini

# Verificar
echo ""
echo "✅ PHP configurado. Reinicia Apache:"
echo "   apachectl restart"
echo ""
echo "🧪 Prueba con: php -r \"echo date_default_timezone_get();\""