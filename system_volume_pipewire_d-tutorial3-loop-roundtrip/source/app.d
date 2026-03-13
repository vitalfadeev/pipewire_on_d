import importc;

//
struct 
roundtrip_data {
    int pending;
    pw_main_loop* loop;
};

extern (C)
static void 
on_core_done (void *data, uint32_t id, int seq)
{
    roundtrip_data* d = cast (roundtrip_data*) data;

    if (id == PW_ID_CORE && seq == d.pending)
        pw_main_loop_quit(d.loop);
}

extern (C)
static 
void 
roundtrip (pw_core* core, pw_main_loop* loop)
{
    static pw_core_events core_events = {
        PW_VERSION_CORE_EVENTS,
        done: &on_core_done,
    };

    roundtrip_data d = { loop: loop };
    spa_hook core_listener;
    int err;

    pw_core_add_listener (core, &core_listener, &core_events, &d);

    d.pending = pw_core_sync (core, PW_ID_CORE, 0);

    if ((err = pw_main_loop_run (loop)) < 0)
        printf("main_loop_run error:%d!\n", err);

    spa_hook_remove (&core_listener);
}
/* [roundtrip] */

extern (C)
static
void
registry_event_global (void* data, uint32_t id,
    uint32_t permissions, const char* type, uint32_t version_,
    const spa_dict* props)
{
    printf ("object: id:%u type:%s/%d\n", id, type, version_);
}

static 
pw_registry_events registry_events = {
    PW_VERSION_REGISTRY_EVENTS,
    &registry_event_global,
};

extern (C)
int 
main (int argc, char** argv) {
    pw_main_loop* loop;
    pw_context*   context;
    pw_core*      core;
    pw_registry*  registry;
    spa_hook      registry_listener;

    pw_init (&argc, &argv);

    loop     = pw_main_loop_new (null /* properties */);
    context  = pw_context_new (pw_main_loop_get_loop (loop),
                    null /* properties */,
                    0 /* user_data size */);

    core     = pw_context_connect (context,
                    null /* properties */,
                    0 /* user_data size */);

    registry = pw_core_get_registry (core, PW_VERSION_REGISTRY,
                    0 /* user_data size */);

    pw_registry_add_listener (registry, &registry_listener,
                                   &registry_events, null);

    roundtrip (core, loop);

    pw_proxy_destroy (cast (pw_proxy*) registry);
    pw_core_disconnect (core);
    pw_context_destroy (context);
    pw_main_loop_destroy (loop);

    return 0;
}
