import importc;
import interfaces;
import spa;


struct 
Klass {
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

    Klass*          klass;
    void*           info; // pw_device_info* | pw_node_info*
    //pw_node_info*   info;
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
