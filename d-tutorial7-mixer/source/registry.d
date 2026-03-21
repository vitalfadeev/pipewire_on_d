module registry;

import importc;
import core_;
import client;
import interfaces;
import device;
import module_;
import node;
import factory;
import metadata;
import spa;
import klass;
import set_volume_mute : Volume;
import set_volume_mute : VOLUME_METHOD_LINEAR,VOLUME_METHOD_CUBIC;
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
    Metadata[]    metadatas;

    //Pw_object[]   objects;

    char[1024]    default_sink;
    int           sink_muted;
    Volume        sink_volume;

    char[1024]    default_source;
    int           source_muted;
    Volume        source_volume;

    int           volume_method = VOLUME_METHOD_LINEAR;


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

    extern (C)
    void 
    global (
        /*void* _this, */uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props)
    {
        //printf ("  type: %s\n", type);

        // Node
        if (strcmp (type, Node.klass_type) == 0) {
            auto name = __find_node_name (cast (spa_dict*) props);
            printf ("registry\n");

            auto node = bind!Node (id, permissions, type, version_, props);
            if (node !is null)
                nodes ~= node;
        }
        else
        // Device
        if (strcmp (type, Device.klass_type) == 0) {
            auto device = bind!Device (id, permissions, type, version_, props);
            if (device !is null)
                devices ~= device;
        }
        else
        // Metadata
        if (strcmp (type, Metadata.klass_type) == 0) {
            auto metadata = bind!Metadata (id, permissions, type, version_, props);
            if (metadata is null)
                metadatas ~= metadata;
        }
        //else
        //// Client
        //if (strcmp (type, Client.klass_type) == 0) {
        //    auto client = bind!Client (id, permissions, type, version_, props);
        //    if (client !is null)
        //        clients ~= client;
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
    }

    void 
    global_remove (/*void* _this, */uint32_t id) {
        size_t[] _for_remove;
        const (char)* name;

        foreach (i,node; nodes) {
            if (node.id == id) {  // Pw_object.id
                if ((name = node.name) is null)
                    return;

                if (spa_streq (name, default_sink.ptr))
                    default_sink[0] = '\0';
                if (spa_streq (name, default_source.ptr))
                    default_source[0] = '\0';

                _for_remove ~= i;
            }
        }

        foreach (i; _for_remove) {
            import std.algorithm;
            nodes = nodes.remove (i);
        }
    }

    static 
    pw_registry_events events = {
        PW_VERSION_REGISTRY_EVENTS,
        global        : cast (typeof (pw_registry_events.global))        &global,
        global_remove : cast (typeof (pw_registry_events.global_remove)) &global_remove,
    };

    T
    bind (T) ( uint32_t id,
        uint32_t permissions, const char*  type,
        uint32_t version_, const spa_dict* props) 
    {
        auto o = new T (core, id, permissions, type, version_, props);

        if (T.klass_events !is null) {
            o.proxy = cast (pw_proxy*) pw_registry_bind (_this, id, type, T.klass_version_, 0);

            if (o.proxy !is null) {
            bind_ok:
                pw_proxy_add_listener (o.proxy, &o.proxy_listener, &o.proxy_events, cast (void*) o);

                if (T.klass_events)
                    pw_proxy_add_object_listener (o.proxy, &o.object_listener, T.klass_events, cast (void*) o);
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

    Node
    find_node (uint32_t id, const char* name) {
        uint32_t name_id = name ? cast (uint32_t) atoi(name) : SPA_ID_INVALID;
        const(char)* str;

        // node
        foreach (node; nodes)
            if ((node.id == id || node.id == name_id)) {
                return node;
            }
            else
            if (name !is null && name[0] != '\0' 
                && (str = node.name) !is null 
                && spa_streq (name, str)
            )
                return node;

        //// device
        //foreach (device; device)
        //    if ((device.id == id || device.id == name_id)) {
        //        return device;
        //    }

        //// metadata
        //foreach (metadata; metadatas)
        //    if ((metadata.id == id || metadata.id == name_id)) {
        //        return metadata;
        //    }

        return null;
    }

    Device
    find_device (uint32_t id, const char* name) {
        uint32_t name_id = name ? cast (uint32_t) atoi(name) : SPA_ID_INVALID;
        char* str;

        // device
        foreach (device; devices)
            if ((device.id == id || device.id == name_id)) {
                return device;
            }

        //// metadata
        //foreach (metadata; metadatas)
        //    if ((metadata.id == id || metadata.id == name_id)) {
        //        return metadata;
        //    }

        return null;
    }

    Node
    find_best_node (uint32_t flags) {
        Node best;

        foreach (node; nodes) {
            if ((flags == 0 || (node.flags & flags) == flags) 
                && (best is null || best.priority < node.priority)
            )
                best = node;
        }

        return best;
    }

    Node
    find_node_for_route (uint32_t card, uint32_t device) {
        foreach (node; nodes) {
            if ((node.device_id == card) 
                && (node.profile_device_id == device)
            )
                return node;
        }

        return null;
    }

}


