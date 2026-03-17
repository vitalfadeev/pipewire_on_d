#include "../include/spa_wrapper.h"


int
__spa_pod_parse_object (struct spa_pod* pod, uint32_t type, uint32_t* id, ...)
{
	int res;
	va_list args;

	va_start (args, id);
	res = spa_pod_parse_object (pod,type,id,args);
	va_end (args);

	return res;
}

char*
__find_node_name (struct spa_dict* props)
{
    static const char* const name_keys[] = {
        PW_KEY_NODE_NAME,
        PW_KEY_NODE_DESCRIPTION,
        PW_KEY_APP_NAME,
        PW_KEY_MEDIA_NAME,
    };

    SPA_FOR_EACH_ELEMENT_VAR (name_keys, key) {
        char* name = (char*) spa_dict_lookup (props, *key);
        if (name)
            return name;
    }

    return NULL;
}
