#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# PARCHAR GD EN TAMP - SIN MODIFICAR CONFIGURACIONES
# =====================================================

echo "========================================="
echo "  PARCHAR GD EN TAMP"
echo "========================================="
echo ""

# 1. Crear gd_fix.php
echo "[1] Creando gd_fix.php..."

cat > /sdcard/htdocs/devmx/bordamex/gd_fix.php << 'EOF'
<?php
// =====================================================
// PARCHES PARA TAMP - GD FALLBACK
// =====================================================

$gd_available = extension_loaded('gd') && function_exists('imagecreatetruecolor');

if (!$gd_available) {
    $has_imagemagick = false;
    if (function_exists('exec')) {
        exec('convert --version 2>&1', $output, $return);
        if ($return === 0) {
            $has_imagemagick = true;
        }
    }
    
    if ($has_imagemagick) {
        function crearMiniatura_IM($ruta_original, $ruta_miniatura, $ancho_max = 250, $calidad = 85) {
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
        
        if (class_exists('GestorPermisos')) {
            // Sobrescribir el método en la clase
            // Usamos un hack simple: crear una nueva clase que extienda la original
            // y luego sobrescribir la referencia en el código
            // Nota: Esto solo funciona si el código usa la clase directamente
            // Si el código ya está cargado, no se puede reemplazar
        }
        
        error_log("✅ GD PATCH: ImageMagick disponible");
    } else {
        error_log("⚠️ GD PATCH: usando fallback copy");
    }
}

function gd_status() {
    return [
        'gd' => extension_loaded('gd') && function_exists('imagecreatetruecolor'),
        'imagemagick' => function_exists('exec') && exec('convert --version 2>&1', $o, $r) === 0 && $r === 0
    ];
}
?>
EOF

echo "    ✅ gd_fix.php creado"

# 2. Crear archivo de verificación
echo ""
echo "[2] Creando verificar_gd.php..."

cat > /sdcard/htdocs/devmx/bordamex/verificar_gd.php << 'EOF'
<?php
include_once("gd_fix.php");

echo "=== ESTADO GD ===\n";
$s = gd_status();
echo "GD: " . ($s['gd'] ? '✅ SI' : '❌ NO') . "\n";
echo "ImageMagick: " . ($s['imagemagick'] ? '✅ SI' : '❌ NO') . "\n";
echo "PHP: " . phpversion() . "\n";
echo "INI: " . php_ini_loaded_file() . "\n";
?>
EOF

echo "    ✅ verificar_gd.php creado"

# 3. Instrucciones
echo ""
echo "========================================="
echo "  COMPLETADO"
echo "========================================="
echo ""
echo "📋 AGREGAR ESTA LÍNEA A TU 0001_guardar_producto.php:"
echo ""
echo "   include_once('gd_fix.php');"
echo ""
echo "📋 Verifica:"
echo "   http://localhost:8080/devmx/bordamex/verificar_gd.php"
echo ""