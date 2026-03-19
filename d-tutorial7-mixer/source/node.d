import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;
import std.string : fromStringz,toStringz;
import spa;
import klass;

class
Node : Pw_object {
    pw_node*      _this () { return cast (pw_node*) proxy; }  // alias to proxy
    //
    static __gshared
    Klass          klass = {
        type:          PW_TYPE_INTERFACE_Node,
        version_:      PW_VERSION_NODE,
        events:        &events,
        name_key:      PW_KEY_NODE_NAME.ptr,
    };
    static __gshared
    pw_node_events events = {
        PW_VERSION_NODE_EVENTS,
        info  : cast (typeof (pw_node_events.info))  &info_event,
        param : cast (typeof (pw_node_events.param)) &param_event
    };

    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
        _klass = &klass;
    }

    ~this () {
        if (info) {
            pw_node_info_free (cast (pw_node_info*) info);
            info = null;
        }
    }


    extern (C)
    void 
    info_event (/*void* _node, */const pw_node_info* _info) {
        printf ("node\n");
        printf ("node_info: id: %u\n", _info.id);
        printf ("\tparams: %u\n", _info.n_params);

        info = cast (void*) pw_node_info_update (cast (pw_node_info*) info, cast (pw_node_info*) _info);

        foreach (ref Param param; Node_info_params_foreach (_info.n_params, _info.params)) {
            auto id_name = param.id.to!string.toStringz;
            printf ("\t\t%2d: %s\n", param.id, id_name);

            switch (param.id) with (spa_param_type) {
                case SPA_PARAM_Format         : _enum_params (param.id); break;
                case SPA_PARAM_PropInfo       : _enum_params (param.id); break;
                case SPA_PARAM_Props          : _enum_params (param.id); break;
                case SPA_PARAM_IO             : _enum_params (param.id); break;
                //
                case SPA_PARAM_EnumProfile    : break;
                case SPA_PARAM_Profile        : break;
                case SPA_PARAM_EnumRoute      : break;
                case SPA_PARAM_Route          : break;
                case SPA_PARAM_EnumPortConfig : break;
                case SPA_PARAM_PortConfig     : break;
                case SPA_PARAM_Latency        : break;
                case SPA_PARAM_ProcessLatency : break;
                case SPA_PARAM_Tag            : break;
                default                       :
            }
        }
    }

    void
    _enum_params (spa_param_type id) {
        //if (info.params[i].user == 0) continue;

        //if (!SPA_FLAG_IS_SET (param.flags, SPA_PARAM_INFO_READ)) continue;

        //auto seq = core.pendings.add ();
        auto seq = 0;
        // node_info_props(&sender, object_id, info);
        pw_node_enum_params (_this, seq, id, 0, 0, null);
        core.sync ();

        //ps[i].user = 0;        
    }

    extern (C)
    void
    param_event (/*void* _node, */int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        printf ("node\n");
        printf ("node_param: id:%u\n", id);
        writefln ("  %s", cast (spa_param_type) id);

        if (param !is null) {
            //add_param (params, seq, id, param);  // malloc (pod.size)
        }
    }

    void
    add_param (spa_list* params, int seq, uint32_t id, const spa_pod* param) {
        // props
    }

    override
    void 
    dump () {
        //
    }
}

void
dump_pod_object (spa_pod* param) {
    // spa_pod_object
    // obj
    //   pod                // spa_pod
    //     size             //   uint32_t
    //     type             //   uint32_t  spa_type  SPA_TYPE_*
    //   body               // spa_pod_object_body
    //     type             //   uint32_t  spa_type  SPA_TYPE_*
    //     id               //   uint32_t
    //     spa_pod_prop[] __array
    //       [0] key        //     uint32_t  spa_prop  SPA_PROP_*
    //       [0] flags      //     uint32_t
    //       [0] value      //     spa_pod
    //           ubyte[]  __value
    //
    // SPA_TYPE_Object
    //   SPA_TYPE_OBJECT_Props
    //
    // SPA_TYPE_*
    //   SPA_TYPE_OBJECT_*
    Pod (param).dump ("  ");
}
