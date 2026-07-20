#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# SOLUCIÓN DEFINITIVA: IMAGEMAGICK PARA TAMP
# =====================================================

echo "========================================="
echo "  SOLUCIÓN DEFINITIVA - IMAGEMAGICK"
echo "========================================="
echo ""

# 1. Instalar ImageMagick
echo "[1] Instalando ImageMagick..."
pkg install imagemagick -y 2>/dev/null

if command -v convert > /dev/null 2>&1; then
    echo "    ✅ ImageMagick instalado"
    convert --version | head -1
else
    echo "    ❌ ImageMagick no se instaló"
    exit 1
fi

# 2. Crear auto_im.php
echo ""
echo "[2] Creando auto_im.php..."

cat > /sdcard/htdocs/devmx/bordamex/auto_im.php << 'EOF'
<?php
// =====================================================
// AUTO-CARGA DE IMAGEMAGICK PARA TAMP
// =====================================================

// Verificar si GD está disponible
if (!extension_loaded('gd') || !function_exists('imagecreatetruecolor')) {
    
    // Verificar ImageMagick
    $has_im = false;
    if (function_exists('exec')) {
        exec('convert --version 2>&1', $out, $ret);
        if ($ret === 0) $has_im = true;
    }
    
    if ($has_im) {
        // Redefinir la función en la clase GestorPermisos
        if (class_exists('GestorPermisos')) {
            // Crear una clase que extienda la original
            eval('
                class GestorPermisos_IM extends GestorPermisos {
                    public static function crearMiniatura($ruta_original, $ruta_miniatura, $ancho_max = 250, $calidad = 85) {
                        if (!file_exists($ruta_original)) return false;
                        $comando = "convert " . escapeshellarg($ruta_original) . 
                                  " -resize " . escapeshellarg($ancho_max . "x" . $ancho_max . ">") . 
                                  " -quality " . intval($calidad) . " " . 
                                  escapeshellarg($ruta_miniatura) . " 2>&1";
                        exec($comando, $output, $return_var);
                        if ($return_var === 0 && file_exists($ruta_miniatura) && filesize($ruta_miniatura) > 0) {
                            @chmod($ruta_miniatura, 0666);
                            return true;
                        }
                        return @copy($ruta_original, $ruta_miniatura);
                    }
                }
            ');
            
            // Reemplazar la clase original con la nueva
            if (class_exists('GestorPermisos')) {
                class_alias('GestorPermisos_IM', 'GestorPermisos');
                error_log("✅ ImageMagick activado para TAMP");
            }
        }
    }
}
?>
EOF

echo "    ✅ auto_im.php creado"

# 3. Modificar conectbd.php
echo ""
echo "[3] Modificando conectbd.php..."

if [ -f "/sdcard/htdocs/devmx/bordamex/conectbd.php" ]; then
    # Verificar si ya tiene la inclusión
    if ! grep -q "auto_im.php" /sdcard/htdocs/devmx/bordamex/conectbd.php; then
        sed -i '1s/<?php/<?php\ninclude_once("auto_im.php");/' /sdcard/htdocs/devmx/bordamex/conectbd.php
        echo "    ✅ conectbd.php modificado"
    else
        echo "    ✅ conectbd.php ya tiene la inclusión"
    fi
else
    echo "    ⚠️ conectbd.php no encontrado"
fi

# 4. Crear archivo de verificación
echo ""
echo "[4] Creando verificar_im.php..."

cat > /sdcard/htdocs/devmx/bordamex/verificar_im.php << 'EOF'
<?php
echo "=== VERIFICACIÓN IMAGEMAGICK ===\n";
echo "================================\n\n";

// Verificar ImageMagick
if (function_exists('exec')) {
    exec('convert --version 2>&1', $out, $ret);
    if ($ret === 0) {
        echo "✅ ImageMagick: " . $out[0] . "\n";
    } else {
        echo "❌ ImageMagick: No disponible\n";
    }
}

// Verificar GD
echo "\n--- GD ---\n";
echo "GD: " . (extension_loaded('gd') ? '✅ SI' : '❌ NO') . "\n";
echo "imagecreatetruecolor: " . (function_exists('imagecreatetruecolor') ? '✅ SI' : '❌ NO') . "\n";

// Verificar clase GestorPermisos
echo "\n--- Clase GestorPermisos ---\n";
if (class_exists('GestorPermisos')) {
    echo "✅ GestorPermisos existe\n";
    if (method_exists('GestorPermisos', 'crearMiniatura')) {
        echo "✅ método crearMiniatura existe\n";
    }
} else {
    echo "❌ GestorPermisos no existe\n";
}

// Verificar auto_im.php
echo "\n--- auto_im.php ---\n";
if (function_exists('class_alias')) {
    echo "✅ class_alist disponible\n";
}

echo "\n================================\n";
echo "NOTA: ImageMagick debe estar instalado\n";
echo "para que las miniaturas funcionen en TAMP\n";
?>
EOF

echo "    ✅ verificar_im.php creado"

# 5. Reiniciar servicios
echo ""
echo "[5] Reiniciando servicios..."

pkill -f "httpd" 2>/dev/null
pkill -f "mysqld" 2>/dev/null
sleep 2

apachectl start 2>/dev/null
mysqld_safe --user=root &
echo "    ✅ Servicios reiniciados"

echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 Verifica:"
echo "   http://localhost:8080/devmx/bordamex/verificar_im.php"
echo ""
echo "📋 Si ves ImageMagick disponible, tus archivos"
echo "   PHP funcionarán sin modificar"
echo ""