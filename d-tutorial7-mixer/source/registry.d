import importc;
import client;
import ctx;
import interfaces;
import device;
import module_;
import node;

class
Registry {
    pw_registry* _this;
    spa_hook      registry_listener;

    this (pw_registry* _this, Ctx ctx) {
        this._this = _this;
        add_listener (ctx);
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    Client
    bind_client (Ctx ctx, uint32_t id_, const char* type) {
        with (ctx)
        return new Client (
            cast (pw_client*)
            pw_registry_bind (
                _this, 
                id_, 
                type, 
                PW_VERSION_CLIENT, 
                0
            ),
            ctx
        );
    }

    Device
    bind_device (Ctx ctx, uint32_t id_, const char* type) {
        with (ctx)
        return new Device (
            cast (pw_device*)
            pw_registry_bind (
                _this, 
                id_, 
                type, 
                PW_VERSION_DEVICE, 
                0
            ),
            ctx
        );
    }

    Module_
    bind_module (Ctx ctx, uint32_t id_, const char* type) {
        with (ctx)
        return new Module_ (
            cast (pw_module*)
            pw_registry_bind (
                _this, 
                id_, 
                type, 
                PW_VERSION_MODULE, 
                0
            ),
            ctx
        );
    }

    Node
    bind_node (Ctx ctx, uint32_t id_, const char* type) {
        with (ctx)
        return new Node (
            cast (pw_node*)
            pw_registry_bind (
                _this, 
                id_, 
                type, 
                PW_VERSION_NODE, 
                0
            ),
            ctx
        );
    }

    extern (C)
    static 
    void 
    registry_event_global (
        void* ctx, uint32_t id_,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props)
    {
        printf ("  type: %s\n", type);

        // Client
        if (strcmp (type, PW_TYPE_INTERFACE_Client) == 0) {
            with (cast (Ctx) ctx)
            if (client is null)
                client = registry.bind_client (cast (Ctx) ctx, id_, type);
        }
        else
        // Device
        if (strcmp (type, PW_TYPE_INTERFACE_Device) == 0) {
            with (cast (Ctx) ctx)
            device = registry.bind_device (cast (Ctx) ctx, id_, type);
        }
        else
        // Module
        if (strcmp (type, PW_TYPE_INTERFACE_Module) == 0) {
            with (cast (Ctx) ctx)
            module_ = registry.bind_module (cast (Ctx) ctx, id_, type);
        }
        else
        // Node
        if (strcmp (type, PW_TYPE_INTERFACE_Node) == 0) {
            with (cast (Ctx) ctx)
            node = registry.bind_node (cast (Ctx) ctx, id_, type);
        }
    }

    static 
    pw_registry_events registry_events = {
        PW_VERSION_REGISTRY_EVENTS,
        global: &registry_event_global,
    };

    void
    add_listener (Ctx ctx) {
        pw_registry_add_listener (
            _this, 
            &registry_listener, // interface  // spa_hook
            &registry_events, 
            cast (void*) ctx
        );
    }
}

