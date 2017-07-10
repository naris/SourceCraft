$cd "C:/Temp/models/red"
$modelname "shield/redshield.mdl"
$model "studio" "redshield.smd"
$cdmaterials "models/shield/"
$hboxset "default"
$hbox 0 "polymsh" -184.000  -183.990  -184.000  184.000  184.000  184.000
// Model uses material "redshield.vmt"
$surfaceprop "metal"
$keyvalues  { prop_data { "base" "Metal.Medium"  } } 
$illumposition 0.000 0.000 0.005
$sequence idle "idle" ACT_IDLE 1 fps 15.00
$collisionmodel "phymodel.smd" {

	$concave
	$mass 200.0
	$inertia 1.00
	$damping 0.00
	$rotdamping 0.00
}
