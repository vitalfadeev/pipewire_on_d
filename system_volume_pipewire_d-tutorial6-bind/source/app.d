import importc;

import std.traits;


enum PW_TYPE_INFO_BASE           = "PipeWire:";
enum PW_TYPE_INFO_Object         = PW_TYPE_INFO_BASE ~ "Object";
enum PW_TYPE_INFO_OBJECT_BASE    = PW_TYPE_INFO_Object ~ ":";
enum PW_TYPE_INFO_Interface      = PW_TYPE_INFO_BASE ~ "Interface";
enum PW_TYPE_INFO_INTERFACE_BASE = PW_TYPE_INFO_Interface ~ ":";
enum PW_TYPE_INTERFACE_Client    = PW_TYPE_INFO_INTERFACE_BASE ~ "Client";


// Безопасно убирает const только если исходный объект не был константным
T safeConstCast(T)(return T value) if (isConst!T) {
    // Проверка в рантайме (не всегда возможна)
    return cast(T) value;
}

// Или более продвинутый вариант с проверкой на immutable
auto removeConst(T)(T value) {
    static if (is(T == const U, U)) {
        return cast(U) value;
    } else {
        return value;
    }
}


struct 
data {
    pw_main_loop *loop;
    pw_context *context;
    pw_core *core;

    pw_registry *registry;
    spa_hook registry_listener;

    pw_client *client;
    spa_hook client_listener;
};

auto
spa_dict_for_each (DICT) (DICT dict) {
    auto items = removeConst (dict.items);
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
client_info (void *object, const pw_client_info *info)
{
        data *data = cast (data *) object;
        //const spa_dict_item *item;

        printf ("client: id:%u\n", info.id);
        printf ("\tprops:\n");        
        foreach (item; spa_dict_for_each(info.props))
                printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        pw_main_loop_quit(data.loop);
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
registry_event_global (void *_data, uint32_t id_,
                        uint32_t permissions, const char *type,
                        uint32_t version_, const spa_dict *props)
{
        data *data = cast (data *) _data;
        if (data.client !is null)
                return;

        if (strcmp (type, PW_TYPE_INTERFACE_Client) == 0) {
                data.client = cast (pw_client*) pw_registry_bind (data.registry,
                                id_, type, PW_VERSION_CLIENT, 0);
                pw_client_add_listener (data.client,
                                &data.client_listener,
                                &client_events, data);
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
    data data;

    spa_zero(data);

    pw_init(&argc, &argv);

    data.loop = pw_main_loop_new(null /* properties */ );
    data.context = pw_context_new(pw_main_loop_get_loop(data.loop),
                             null /* properties */ ,
                             0 /* user_data size */ );

    data.core = pw_context_connect(data.context, null /* properties */ ,
                              0 /* user_data size */ );

    data.registry = pw_core_get_registry(data.core, PW_VERSION_REGISTRY,
                                    0 /* user_data size */ );

    pw_registry_add_listener (data.registry, &data.registry_listener,
                             &registry_events, &data);

    pw_main_loop_run (data.loop);

    pw_proxy_destroy (cast (pw_proxy *) data.client);
    pw_proxy_destroy (cast (pw_proxy *) data.registry);
    pw_core_disconnect (data.core);
    pw_context_destroy (data.context);
    pw_main_loop_destroy (data.loop);

    return 0;
}
