module registry;

import importc;
import core_;
import client;
import interfaces;
import device;
import module_;
import node;
import factory;

class
Registry {
    pw_registry* _this;
    Core_         core_;
    spa_hook      registry_listener;
    Client[]      clients;
    Device[]      devices;
    Module_[]     modules;
    Node[]        nodes;
    Factory[]     factorys;

    this (pw_registry* _this, Core_ core_) {
        this._this = _this;
        this.core_ =  core_;
        pw_registry_add_listener (
            _this, 
            &registry_listener, // interface  // spa_hook
            &registry_events, 
            cast (void*) this
        );
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    T
    bind (T) (uint32_t id, const char* type, uint32_t version_) {
        return new T (
            pw_registry_bind (_this, id, type, version_, 0),
            core_
        );
    }

    extern (C)
    static 
    void 
    registry_event_global (
        void* _this, uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props)
    {
        with (cast (Registry) _this) {
            //printf ("  type: %s\n", type);

            // Node
            if (strcmp (type, PW_TYPE_INTERFACE_Node) == 0) {
                nodes ~= bind!Node (id,type,PW_VERSION_NODE);
                core_.add_pending ();

                //events = &node_events;
                //client_version = PW_VERSION_NODE;
                //destroy = cast (pw_destroy_t) pw_node_info_free;
                //print_func = print_node;
            }
            else
            // Client
            if (strcmp (type, PW_TYPE_INTERFACE_Client) == 0) {
                //if (client is null)
                clients ~= bind!Client (id,type,PW_VERSION_CLIENT);
            }
            else
            // Device
            if (strcmp (type, PW_TYPE_INTERFACE_Device) == 0) {
                devices ~= bind!Device (id,type,PW_VERSION_DEVICE);
            }
            else
            // Module
            if (strcmp (type, PW_TYPE_INTERFACE_Module) == 0) {
                modules ~= bind!Module_ (id,type,PW_VERSION_MODULE);
            }
            else
            // Factory
            if (strcmp (type, PW_TYPE_INTERFACE_Factory) == 0) {
                factorys ~= bind!Factory (id,type,PW_VERSION_FACTORY);
            }
            else {
                return;
            }
        }

    //    //
    //    with (cast (Ctx) ctx)
    //    proxy = pw_registry_bind (
    //        registry, id, type,
    //        client_version,
    //        proxy_data.sizeof
    //    );

    //    if (proxy is null)
    //        goto no_mem;

    //    pd = pw_proxy_get_user_data(proxy);
    //    pd.data        = d;
    //    pd.first       = true;
    //    pd.proxy       = proxy;
    //    pd.id          = id;
    //    pd.permissions = permissions;
    //    pd.version     = version;
    //    pd.type        = strdup(type);
    //    pd.destroy     = destroy;
    //    pd.pending_seq = 0;
    //    pd.print_func  = print_func; 
    //    spa_list_init (&pd.param_list);
    //    pw_proxy_add_object_listener (proxy, &pd.object_listener, events, pd);
    //    pw_proxy_add_listener (proxy, &pd.proxy_listener, &proxy_events, pd);
    //    spa_list_append (&d.global_list, &pd.global_link);

    //no_mem:
    //    fprintf (stderr, "failed to create proxy");
    //    return;
    }

    static 
    pw_registry_events registry_events = {
        PW_VERSION_REGISTRY_EVENTS,
        global        : &registry_event_global,
        //global_remove : &registry_event_global_remove,
    };
}

