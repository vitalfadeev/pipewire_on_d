import importc;
import core_;
import interfaces;
import spa;

enum DEFAULT_VOLUME_METHOD = "cubic";
enum VOLUME_MIN            = (cast (uint32_t) 0U);
enum VOLUME_MAX            = (cast (uint32_t) 0x10000U);


struct Volume {
    uint32_t                     channels;
    long[SPA_AUDIO_MAX_CHANNELS] values;
}

struct 
snd_ctl_pipewire_t {
    //snd_ctl_ext_t   ext;

    pw_properties*  props;

    spa_system*     system;
    pw_thread_loop* mainloop;

    pw_context*     context;
    pw_core*        core;
    spa_hook        core_listener;

    pw_registry*    registry;
    spa_hook        registry_listener;

    //pw_metadata*    metadata;
    spa_hook        metadata_listener;

    int             fd;
    int             last_seq;
    int             pending_seq;
    int             error;

    char[1024]      default_sink;
    int             sink_muted;
    Volume          sink_volume;

    char[1024]      default_source;
    int             source_muted;
    Volume          source_volume;

    int             subscribed;
    int             volume_method;

    int             updated;

    spa_list        globals;
}

enum VOLUME_METHOD_LINEAR = (0);
enum VOLUME_METHOD_CUBIC  = (1);
enum UPDATE_SINK_VOL    = (1<<0);
enum UPDATE_SINK_MUTE   = (1<<1);
enum UPDATE_SOURCE_VOL  = (1<<2);
enum UPDATE_SOURCE_MUTE = (1<<3);


struct global_info {
    const char*  type;
    uint32_t     version_;
    const void*  events;
    pw_destroy_t destroy;
    INIT_FN      init;
    alias INIT_FN = int function (global* g);
};

struct global {
    spa_list        link;

    snd_ctl_pipewire_t* ctl;

    const global_info* ginfo;

    uint32_t        id;
    uint32_t        permissions;
    pw_properties*  props;

    pw_proxy*       proxy;
    spa_hook        proxy_listener;
    spa_hook        object_listener;

    union {
        struct 
        _Node {
            uint32_t flags;
            uint32_t device_id;
            uint32_t profile_device_id;
            int      priority;
            float    volume;
            bool     mute;
            Volume   channel_volume;
        }
        _Node node;

        struct 
        _Device {
            uint32_t active_route_output;
            uint32_t active_route_input;
        }
        _Device device;
    }
};

enum NODE_FLAG_SINK          = (1<<0);
enum NODE_FLAG_SOURCE        = (1<<1);
enum NODE_FLAG_DEVICE_VOLUME = (1<<2);
enum NODE_FLAG_DEVICE_MUTE   = (1<<3);

enum SOURCE_VOL_NAME  = "Capture Volume";
enum SOURCE_MUTE_NAME = "Capture Switch";
enum SINK_VOL_NAME    = "Master Playback Volume";
enum SINK_MUTE_NAME   = "Master Playback Switch";


spa_pod*
build_volume_mute (spa_pod_builder* b, Volume* volume, int* mute, int volume_method) {
    spa_pod_frame[1] f;

    spa_pod_builder_push_object (b, &f[0],
            SPA_TYPE_OBJECT_Props, SPA_PARAM_Props);
    if (volume) {
        float[SPA_AUDIO_MAX_CHANNELS] volumes;
        uint32_t i, n_volumes = 0;

        n_volumes = volume.channels;
        for (i = 0; i < n_volumes; i++)
            volumes[i] = volume_to_linear (volume.values[i], volume_method);

        spa_pod_builder_prop (b, SPA_PROP_channelVolumes, 0);
        spa_pod_builder_array (b, float.sizeof,
            SPA_TYPE_Float, n_volumes, volumes.ptr);
    }
    if (mute) {
        spa_pod_builder_prop (b, SPA_PROP_mute, 0);
        spa_pod_builder_bool (b, *mute ? true : false);
    }
    return cast (spa_pod*) spa_pod_builder_pop (b, &f[0]);
}

static int 
set_volume_mute (snd_ctl_pipewire_t* ctl, const char* name, Volume* volume, int* mute) {
    global*          g;
    global*          dg;
    uint32_t         id = SPA_ID_INVALID, device_id = SPA_ID_INVALID;
    char[1024]       buf;
    spa_pod_builder  b = SPA_POD_BUILDER_INIT (buf.ptr,buf.sizeof);
    spa_pod_frame[2] f;
    spa_pod          *param;

    g = find_global (ctl, SPA_ID_INVALID, name, PW_TYPE_INTERFACE_Node);
    if (g is null)
        return -EINVAL;

    if (spa.SPA_FLAG_IS_SET (g.node.flags, NODE_FLAG_DEVICE_VOLUME) &&
        (dg = find_global (ctl, g.node.device_id, null, PW_TYPE_INTERFACE_Device)) != null) {
        if (g.node.flags & NODE_FLAG_SINK)
            id = dg.device.active_route_output;
        else 
        if (g.node.flags & NODE_FLAG_SOURCE)
            id = dg.device.active_route_input;
        device_id = g.node.profile_device_id;
    }
    //pw_log_debug ("id %d device_id %d flags:%08x", id, device_id, g.node.flags);
    if (id != SPA_ID_INVALID && device_id != SPA_ID_INVALID && dg != null) {
        if (!spa.SPA_FLAG_IS_SET (dg.permissions, PW_PERM_W | PW_PERM_X))
            return -EPERM;

        spa_pod_builder_push_object (&b, &f[0],
            SPA_TYPE_OBJECT_ParamRoute, SPA_PARAM_Route);
        spa_pod_builder_add (&b,
            SPA_PARAM_ROUTE_index,  SPA_POD_Int (id),
            SPA_PARAM_ROUTE_device, SPA_POD_Int (device_id),
            SPA_PARAM_ROUTE_save,   SPA_POD_Bool (true),
            0);

        spa_pod_builder_prop (&b, SPA_PARAM_ROUTE_props, 0);
        build_volume_mute (&b, volume, mute, ctl.volume_method);
        param = cast (spa_pod*) spa_pod_builder_pop (&b, &f[0]);

        //pw_log_debug ("set device %d mute/volume for node %d", dg.id, g.id);
        pw_device_set_param (cast (pw_device*) dg.proxy,
            SPA_PARAM_Route, 0, param);
    } 
    else {
        if (!spa.SPA_FLAG_IS_SET (g.permissions, PW_PERM_W | PW_PERM_X))
            return -EPERM;

        param = build_volume_mute (&b, volume, mute, ctl.volume_method);

        //pw_log_debug ("set node %d mute/volume", g.id);
        pw_node_set_param (cast (pw_node*) g.proxy, SPA_PARAM_Props, 0, param);
    }

    return 0;
}

float 
volume_to_linear (long vol, int method) {
    float v = (cast (float) vol) / VOLUME_MAX;

    switch (method) {
        case VOLUME_METHOD_CUBIC:
            v = v * v * v;
            break;
        default:
    }
    return v;
}

global*
find_global (snd_ctl_pipewire_t* ctl, uint32_t id,
        const char* name, const char* type)
{
    uint32_t name_id = name ? cast (uint32_t) atoi(name) : SPA_ID_INVALID;
    char* str;

    // spa_list_for_each (g, &ctl.globals, link) {
    //foreach (global* g; Spa_list_for_each!global (&ctl.globals)) {
    //foreach (global* g; cast (Spa_list!"link") ctl.globals) {
    foreach (global* g; Spa_list (&ctl.globals)) {
        if ((g.id == id || g.id == name_id) &&
            (type == NULL || spa_streq(g.ginfo.type, type)))
            return g;
        if (name != NULL && name[0] != '\0' &&
            (str = cast (char*) pw_properties_get (g.props, PW_KEY_NODE_NAME.ptr)) !is null &&
            spa_streq(name, str))
            return g;
    }
    return null;
}

