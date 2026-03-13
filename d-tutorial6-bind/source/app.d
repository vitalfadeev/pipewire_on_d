import importc;

enum PW_TYPE_INFO_BASE           = "PipeWire:";
enum PW_TYPE_INFO_Object         = PW_TYPE_INFO_BASE ~ "Object";
enum PW_TYPE_INFO_OBJECT_BASE    = PW_TYPE_INFO_Object ~ ":";
enum PW_TYPE_INFO_Interface      = PW_TYPE_INFO_BASE ~ "Interface";
enum PW_TYPE_INFO_INTERFACE_BASE = PW_TYPE_INFO_Interface ~ ":";
enum PW_TYPE_INTERFACE_Client    = PW_TYPE_INFO_INTERFACE_BASE ~ "Client";


struct 
Ctx {
    pw_main_loop* loop;
    pw_context*   context;
    pw_core*      core;

    pw_registry*  registry;
    spa_hook      registry_listener;

    pw_client*    client;
    spa_hook      client_listener;
};

auto removeConst (T) (T value) {
    static if (is (T == const U, U)) {
        return cast (U) value;
    } else {
        return value;
    }
}

auto
spa_dict_for_each (DICT) (DICT dict) {
    auto  items = removeConst (dict.items);
    alias ITEMS = typeof (items);
    return _spa_dict_for_each!(DICT,ITEMS) (dict,items);
}

struct
_spa_dict_for_each (DICT,ITEMS) {
    DICT  dict;
    ITEMS front;
    bool  empty () { return front >= &dict.items[dict.n_items]; }
    void  popFront () { front++; }

    this (DICT dict, ITEMS items) {
        this.dict  = dict;
        this.front = items;
    }
}


/* [client_info] */
extern (C)
static void 
client_info (void *ctx, const pw_client_info *info)
{
    with (cast (Ctx*) ctx) {
        printf ("client: id:%u\n", info.id);
        printf ("\tprops:\n");

        foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
            printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        pw_main_loop_quit (loop);
    }
}

static 
pw_client_events client_events = {
    PW_VERSION_CLIENT_EVENTS,
    info: &client_info,
};
/* [client_info] */

/* [registry_event_global] */
extern (C)
static 
void 
registry_event_global (
    void* ctx, uint32_t id_,
    uint32_t permissions, const char*  type,
    uint32_t version_, const spa_dict* props)
{
    with (cast (Ctx*) ctx) {
        if (client !is null)
            return;

        // PipeWire:Object:Interface:Client
        if (strcmp (type, PW_TYPE_INTERFACE_Client) == 0) {
            client = cast (pw_client*) pw_registry_bind (
                registry, 
                id_, 
                type, 
                PW_VERSION_CLIENT, 
                0
            );
            pw_client_add_listener (
                client,
                &client_listener,
                &client_events, 
                ctx
            );
        }
    }
}
/* [registry_event_global] */

static 
pw_registry_events registry_events = {
    PW_VERSION_REGISTRY_EVENTS,
    global: &registry_event_global,
};

extern (C)
int main (int argc, char** argv) {
    Ctx ctx;

    // init
    pw_init (&argc, &argv);

    with (ctx) {
        loop    = pw_main_loop_new (null /* properties */ );
        context = pw_context_new (
            pw_main_loop_get_loop (loop),
            null /* properties */ ,
            0 /* user_data size */ 
        );

        core = pw_context_connect (
            context, 
            null /* properties */ ,
            0 /* user_data size */ 
        );

        registry = pw_core_get_registry (
            core, 
            PW_VERSION_REGISTRY,
            0 /* user_data size */ 
        );

        pw_registry_add_listener (
            registry, 
            &registry_listener,
            &registry_events, 
            &ctx
        );

        // loop
        pw_main_loop_run (loop);

        // free
        pw_proxy_destroy (cast (pw_proxy *) client);
        pw_proxy_destroy (cast (pw_proxy *) registry);
        pw_core_disconnect (core);
        pw_context_destroy (context);
        pw_main_loop_destroy (loop);
    }

    return 0;
}
