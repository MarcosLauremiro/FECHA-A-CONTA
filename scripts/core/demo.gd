class_name Demo
extends RefCounted
## Versão demo: só dá para jogar os 6 primeiros meses (sem modo infinito).
## A demo sai de um export com a feature "demo" (presets "Windows Demo" e "Web Demo" em export_presets.cfg).


static func is_demo() -> bool:
	return OS.has_feature("demo")
