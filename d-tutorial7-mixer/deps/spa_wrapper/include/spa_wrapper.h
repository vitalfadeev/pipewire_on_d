#include <stdio.h>
#include <errno.h>
//#include <math.h>
#include <signal.h>

// PipeWire
#define SPA_API_IMPL static
#include <pipewire/pipewire.h>

// Spa
#define SPA_API_IMPL static
#include <spa/utils/result.h>
#include <spa/utils/string.h>
#include <spa/utils/hook.h>
#include <spa/pod/parser.h>
// #include <spa/debug/types.h>
#include <spa/param/format-utils.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/video/format-utils.h>

int 
_spa_format_parse (const struct spa_pod * 	format,
		uint32_t * 	media_type,
		uint32_t * 	media_subtype ) ;

void 
_spa_hook_remove (struct spa_hook* hook) ;
