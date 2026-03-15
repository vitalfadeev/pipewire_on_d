#include "../include/spa_wrapper.h"

int 
_spa_format_parse (const struct spa_pod * 	format,
		uint32_t * 	media_type,
		uint32_t * 	media_subtype ) 
{
	return spa_format_parse (format, media_type, media_subtype);
}

void 
_spa_hook_remove (struct spa_hook* hook) 
{
	spa_hook_remove ( 	hook	) ;
}
