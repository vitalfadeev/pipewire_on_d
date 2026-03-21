#include <stdio.h>
#include <errno.h>
//#include <math.h>
#include <signal.h>

// PipeWire
#define SPA_API_IMPL __attribute__((unused))
#include <pipewire/pipewire.h>
#include <pipewire/extensions/metadata.h>

// Spa
#define SPA_API_IMPL __attribute__((unused))
#include <spa/utils/result.h>
#include <spa/utils/string.h>
#include <spa/utils/hook.h>
#include <spa/pod/parser.h>
// #include <spa/debug/types.h>
#include <spa/param/props.h>
#include <spa/param/format-utils.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/video/format-utils.h>

int
__spa_pod_parse_object (struct spa_pod* pod, uint32_t type, uint32_t* id, ...);

char*
__find_node_name (struct spa_dict* props);
