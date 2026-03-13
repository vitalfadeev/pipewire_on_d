import importc;

//
extern (C)
static 
void 
registry_event_global(void *data, uint32_t id,
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


//
extern (C)
int 
main (int argc, char** argv) 
{
        pw_main_loop *loop;
        pw_context *context;
        pw_core *core;
        pw_registry *registry;
        spa_hook registry_listener;

        pw_init (&argc, &argv);

        loop = pw_main_loop_new (null /* properties */);
        context = pw_context_new(pw_main_loop_get_loop (loop),
                        null /* properties */,
                        0 /* user_data size */);

        core = pw_context_connect (context,
                        null /* properties */,
                        0 /* user_data size */);

        registry = pw_core_get_registry (core, PW_VERSION_REGISTRY,
                        0 /* user_data size */);

        spa_zero (registry_listener);
        pw_registry_add_listener (registry, &registry_listener,
                                       &registry_events, null);

        pw_main_loop_run (loop);

        pw_proxy_destroy (cast (pw_proxy*) registry);
        pw_core_disconnect (core);
        pw_context_destroy (context);
        pw_main_loop_destroy (loop);

        return 0;
}
