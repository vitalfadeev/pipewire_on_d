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
    bind (T) (uint32_t id, const char* type) {
        return new T (
            pw_registry_bind (_this, id, type, T.klass.version_, 0),
            core
        );
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

            auto _node = new Node (core);
            nodes ~= _node;
            //_node.o.data       = d;
            _node.o.id          = id;
            _node.o.permissions = permissions;
            _node.o.type        = strdup (type);
            _node.o.version_    = version_;
            _node.o.props       = props ? pw_properties_new_dict (cast (spa_dict*) props) : null;

            //
            _node.o.klass = find_klass (type, version_);
            if (_node.o.klass !is null) {
                _node.o.proxy = cast (pw_proxy*) pw_registry_bind (_this, id, type, _node.o.klass.version_, 0);
                _node._this   = cast (pw_node*) _node.o.proxy;

                if (_node.o.proxy is null) goto bind_failed;

                pw_proxy_add_listener (_node.o.proxy, &_node.o.proxy_listener, &proxy_events, cast (void*) _node);

                if (_node.o.klass.events)
                    pw_proxy_add_object_listener (_node.o.proxy, &_node.o.object_listener, _node.o.klass.events, cast (void*) _node);
                else
                    _node.o.changed++;

                core.sync ();
                return;

                bind_failed:
                    //pw_log_error ("can't bind object for %u %s/%d: %m", id, type, version_);
                    //object_destroy (&_node.o);
                    return;
            }
        }
        //else
        //// Client
        //if (strcmp (type, Client.klass.type) == 0) {
        //    //if (client is null)
        //    clients ~= bind!Client (id,type);
        //}
        //else
        //// Device
        //if (strcmp (type, Device.klass.type) == 0) {
        //    devices ~= bind!Device (id,type);
        //}
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

extern (C)
void
destroy_removed (void* data) {
    Object_* o = cast (Object_*) data;
    pw_proxy_destroy (o.proxy);
}

extern (C)
void
destroy_proxy (void* data) {
    Object_* o = cast (Object_*) data;

    spa_hook_remove (&o.proxy_listener);
    if (o.klass !is null) {
        if (o.klass.events)
            spa_hook_remove (&o.object_listener);
        if (o.klass.destroy_)
            o.klass.destroy_ (o);
    }
    o.proxy = null;
}

static 
pw_proxy_events proxy_events = {
    PW_VERSION_PROXY_EVENTS,
    removed: &destroy_removed,
    destroy: &destroy_proxy,
};

Klass*
find_klass (const char* type, uint32_t version_) {
    //SPA_FOR_EACH_ELEMENT_VAR(classes, c) {
    foreach (k; klasses) {
        if (spa_streq (k.type, type) && k.version_ <= version_)
            return cast (Klass*) k;
    }
    return null;
}

static const 
Klass*[] klasses = [
    //&core_class,
    //&module_class,
    //&factory_class,
    //&client_class,
    //&device_class,
    &Node.klass,
    //&port_class,
    //&link_class,
    //&metadata_class,
];
