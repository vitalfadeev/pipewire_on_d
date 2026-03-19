import importc;
import interfaces;
import spa;
import core_;


//struct 
//Klass {
//    const char* type;
//    uint32_t    version_;
//    const void* events;
//    const char* name_key;
//};


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

class Pw_proxy {
    pw_proxy*       proxy;
    spa_hook        proxy_listener;
}

class Pw_object : Pw_proxy {
    spa_list        link;

    Data*           data;

    uint32_t        id;
    uint32_t        permissions;
    char*           type;
    uint32_t        version_;
    pw_properties*  props;   // from registry.global ()

    //const void*     klass_events;
    //Klass*         _klass;
    void*           info; // pw_device_info* | pw_node_info*
    spa_param_info* params;
    uint32_t        n_params;
    //Param_info[]    params;  // from node.info (), node_param ()

    int             changed;
    spa_list        param_list;
    spa_list        pending_list;
    spa_list        data_list;

    spa_hook        object_listener;
    Core            core;

    this (Core core, uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props) 
    {
        this.core = core;
        this.id          = id;
        this.permissions = permissions;
        this.type        = strdup (type);
        this.version_    = version_;
        this.props       = props ? pw_properties_new_dict (cast (spa_dict*) props) : null;
        spa_list_init (&this.param_list);
        spa_list_init (&this.pending_list);
        spa_list_init (&this.data_list);
        spa_list_append (&core.object_list, &this.link);
    }

    extern (C)
    void
    destroy_removed (void* data) {
        pw_proxy_destroy (proxy);
    }

    void
    destroy_proxy (void* data) {
        spa_hook_remove (&proxy_listener);
        //if (klass.events)
            spa_hook_remove (&object_listener);
        proxy = null;
    }

    static 
    pw_proxy_events proxy_events = {
        PW_VERSION_PROXY_EVENTS,
        removed: cast (typeof (pw_proxy_events.removed)) &destroy_removed,
        destroy: cast (typeof (pw_proxy_events.destroy)) &destroy_proxy,
    };

    void 
    dump () {
        //
    }
}

struct 
Struct_param {
    uint32_t id;
    int32_t  seq;
    spa_list link;
    spa_pod* param;
};
