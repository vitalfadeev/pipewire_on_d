import importc;
import interfaces;
import spa;

struct 
Class {
    const char* type;
    uint32_t    version_;
    const void* events;
    Destroy_fn  destroy_;
    Dump_fn     dump;
    const char* name_key;

    alias Destroy_fn = void function (Object_* object);
    alias Dump_fn    = void function (Object_* object);
};

struct 
Object_ {
    spa_list        link;

    Data*           data;

    uint32_t        id;
    uint32_t        permissions;
    char*           type;
    uint32_t        version_;
    pw_properties*  props;

    Class*          class_;
    //void*           info;
    pw_node_info*   info;
    spa_param_info* params;
    uint32_t        n_params;

    int             changed;
    spa_list        param_list;
    spa_list        pending_list;
    spa_list        data_list;

    pw_proxy*       proxy;
    spa_hook        proxy_listener;
    spa_hook        object_listener;
}

struct 
Data {
    pw_main_loop*   loop;
    pw_context*     context;

    pw_core_info*   info;
    pw_core*        core;
    spa_hook        core_listener;
    int             sync_seq;

    pw_registry*    registry;
    spa_hook        registry_listener;

    spa_list        object_list;

    const char*     pattern;

    FILE*           out_;
    int             level;
    uint32_t        state;  // STATE_*

    //uint            monitor:1;
}

enum STATE_KEY    = (1<<0);
enum STATE_COMMA  = (1<<1);
enum STATE_FIRST  = (1<<2);
enum STATE_MASK   = 0xffff0000;
enum STATE_SIMPLE = (1<<16);

struct 
Param {
    uint32_t id;
    int32_t  seq;
    spa_list link;
    spa_pod* param;
};


static uint32_t 
clear_params (spa_list* param_list, uint32_t id) {
    Param* p;
    Param* t;
    uint32_t count = 0;

    //spa_list_for_each_safe (p, t, param_list, link) {
    //    if (id == SPA_ID_INVALID || p.id == id) {
    //        spa_list_remove (&p.link);
    //        free (p);
    //        count++;
    //    }
    //}

    return count;
}

static void 
object_destroy (Object_* o) {
    spa_list_remove (&o.link);
    if (o.proxy)
        pw_proxy_destroy (o.proxy);
    pw_properties_free (o.props);
    clear_params (&o.param_list, SPA_ID_INVALID);
    clear_params (&o.pending_list, SPA_ID_INVALID);
    free (o.type);
    free (o);
}

extern (C)
static void
destroy_removed (void* data) {
    Object_* o = cast (Object_*) data;
    pw_proxy_destroy (o.proxy);
}

extern (C)
static void
destroy_proxy (void* data) {
    Object_* o = cast (Object_*) data;

    spa_hook_remove (&o.proxy_listener);
    if (o.class_ !is null) {
        if (o.class_.events)
            spa_hook_remove (&o.object_listener);
        if (o.class_.destroy_)
            o.class_.destroy_ (o);
    }
    o.proxy = null;
}


static pw_proxy_events proxy_events = {
    PW_VERSION_PROXY_EVENTS,
    removed: &destroy_removed,
    destroy: &destroy_proxy,
};


// node
extern (C)
static void 
node_event_info (void* data, const pw_node_info* info) {
    //
}

extern (C)
static void 
node_event_param (void* data, int seq,
    uint32_t id, uint32_t index, uint32_t next,
    const spa_pod* param)
{
    Object_* o = cast (Object_*) data;
    //add_param (&o.pending_list, seq, id, param);
}

static const pw_node_events node_events = {
    PW_VERSION_NODE_EVENTS,
    info:  &node_event_info,
    param: &node_event_param,
};

static void 
node_destroy (Object_* o) {
    if (o.info) {
        pw_node_info_free (o.info);
        o.info = null;
    }
}

static void 
node_dump (Object_* o) {
    //
}


static const 
Class node_class = {
    type:     PW_TYPE_INTERFACE_Node,
    version_: PW_VERSION_NODE,
    events:   &node_events,
    destroy_: &node_destroy,
    dump:     &node_dump,
    name_key: PW_KEY_NODE_NAME.ptr,
};

static const Class*[] classes = [
    //&core_class,
    //&module_class,
    //&factory_class,
    //&client_class,
    //&device_class,
    &node_class,
    //&port_class,
    //&link_class,
    //&metadata_class,
];

Class*
find_class (const char* type, uint32_t version_) {
    //SPA_FOR_EACH_ELEMENT_VAR(classes, c) {
    foreach (c; classes) {
        if (spa_streq (c.type, type) && c.version_ <= version_)
            return cast (Class*) c;
    }
    return null;
}


extern (C)
static 
void 
registry_event_global_2 (void* data, uint32_t id,
    uint32_t permissions, const char* type, uint32_t version_,
    const spa_dict* props)
{
    Data* d = cast (Data*) data;

    Object_* o;
    o = cast (Object_*) calloc (1, (*o).sizeof);
    if (o is null) {
        //pw_log_error ("can't alloc object for %u %s/%d: %m", id, type, version_);
        return;
    }

    o.data        = d;
    o.id          = id;
    o.permissions = permissions;
    o.type        = strdup (type);
    o.version_    = version_;
    o.props       = props ? pw_properties_new_dict (cast (spa_dict*) props) : null;
    //spa_list_init (&o.param_list);
    //spa_list_init (&o.pending_list);
    //spa_list_init (&o.data_list);
    //spa_list_append (&d.object_list, &o.link);

    o.class_ = find_class (type,version_);
    if (o.class_ !is null) {
        o.proxy = cast (pw_proxy*) pw_registry_bind (d.registry, id, type, o.class_.version_, 0);

        if (o.proxy is null) goto bind_failed;

        pw_proxy_add_listener (o.proxy, &o.proxy_listener, &proxy_events, o);

        if (o.class_.events)
            pw_proxy_add_object_listener (o.proxy, &o.object_listener, o.class_.events, o);
        else
            o.changed++;

        core_sync (d);
        return;

        bind_failed:
//            pw_log_error ("can't bind object for %u %s/%d: %m", id, type, version_);
            object_destroy (o);
            return;
    }
}

static void 
core_sync (Data* d) {
    d.sync_seq = pw_core_sync (d.core, PW_ID_CORE, d.sync_seq);
    //pw_log_debug ("sync start %u", d.sync_seq);
}
