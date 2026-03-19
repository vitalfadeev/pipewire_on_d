module registry;

import importc;
import core_;
import client;
import interfaces;
import device;
import module_;
import node;
import factory;
import spa;
import klass;
import std.stdio : writeln;

class
Registry {
    pw_registry* _this;
    Core          core;
    spa_hook      listener;
    Device[]      devices;
    Client[]      clients;
    Node[]        nodes;
    Module_[]     modules;
    Factory[]     factorys;

    this (pw_registry* _this, Core core) {
        this._this = _this;
        this.core =  core;
        pw_registry_add_listener (
            _this, 
            &listener, // interface  // spa_hook
            &events, 
            cast (void*) this
        );
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    T
    bind (T) ( uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props) 
    {
        auto o = new T (core, id, permissions, type, version_, props);

        if (T.klass.events !is null) {
            o.proxy = cast (pw_proxy*) pw_registry_bind (_this, id, type, T.klass.version_, 0);

            if (o.proxy !is null) {
            bind_ok:
                pw_proxy_add_listener (o.proxy, &o.proxy_listener, &o.proxy_events, cast (void*) o);

                if (T.klass.events)
                    pw_proxy_add_object_listener (o.proxy, &o.object_listener, T.klass.events, cast (void*) o);
                else
                    o.changed++;

                core.sync ();

                return o;
            }
            else {
            bind_failed:
                //pw_log_error ("can't bind object for %u %s/%d: %m", id, type, version_);
                o.destroy ();
            }
        }

        return null;                
    }

    extern (C)
    void 
    global (
        /*void* _this, */uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props)
    {
        //printf ("  type: %s\n", type);

        // Node
        if (strcmp (type, Node.klass.type) == 0) {
            auto name = __find_node_name (cast (spa_dict*) props);
            printf ("registry\n");
            printf ("node id,name: %u, %s\n", id,name);
            printf ("  props: ");
            foreach (item; spa_dict_for_each (props))  // spa_dict_item* item
                printf ("    %s: \"%s\"\n", item.key, item.value);

            auto node = bind!Node (id, permissions, type, version_, props);
            if (node !is null)
                nodes ~= node;
        }
        else
        // Client
        if (strcmp (type, Client.klass.type) == 0) {
            auto client = bind!Client (id, permissions, type, version_, props);
            if (client !is null)
                clients ~= client;
        }
        else
        // Device
        if (strcmp (type, Device.klass.type) == 0) {
            auto device = bind!Device (id, permissions, type, version_, props);
            if (device !is null)
                devices ~= device;
        }
        //else
        //// Module
        //if (strcmp (type, PW_TYPE_INTERFACE_Module) == 0) {
        //    modules ~= bind!Module_ (id,type,PW_VERSION_MODULE);
        //}
        //else
        //// Factory
        //if (strcmp (type, PW_TYPE_INTERFACE_Factory) == 0) {
        //    factorys ~= bind!Factory (id,type,PW_VERSION_FACTORY);
        //}
        //else {
        //    return;
        //}

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
    pw_registry_events events = {
        PW_VERSION_REGISTRY_EVENTS,
        global        : cast (typeof (pw_registry_events.global)) &global,
        //global_remove : &registry_event_global_remove,
    };
}
