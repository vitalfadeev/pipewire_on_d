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
    // klass
    enum klass_type     = PW_TYPE_INTERFACE_Node;
    enum klass_version_ = PW_VERSION_NODE;
    enum klass_events   = &events;
    enum klass_name_key = PW_KEY_NODE_NAME.ptr;
    //
    static __gshared
    pw_node_events events = {
        PW_VERSION_NODE_EVENTS,
        info  : cast (typeof (pw_node_events.info))  &info_event,
        param : cast (typeof (pw_node_events.param)) &param_event
    };

    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
    }

    ~this () {
        if (info) {
            pw_node_info_free (cast (pw_node_info*) info);
            info = null;
        }
    }


    extern (C)
    void 
    info_event (/*void* _node, */const pw_node_info* info) {
        uint32_t i, changed = 0;
        int      res;

        printf ("node\n");
        printf ("node_info: id: %u\n", info.id);
        printf ("\tparams: %u\n", info.n_params);

        this.info = cast (void*) pw_node_info_update (cast (pw_node_info*) this.info, cast (pw_node_info*) info);
        if (this.info is null)
            return;

        params   = cast (spa_param_info*) (info.params);
        n_params = info.n_params;

        if (info.change_mask & PW_NODE_CHANGE_MASK_STATE)
            changed++;

        if (info.change_mask & PW_NODE_CHANGE_MASK_PROPS)
            changed++;

        if (info.change_mask & PW_NODE_CHANGE_MASK_PARAMS) {
            for (i = 0; i < info.n_params; i++) {
                uint32_t id = info.params[i].id;

                if (info.params[i].user == 0)
                    continue;
                (cast (pw_node_info*) info).params[i].user = 0;

                changed++;
                add_param (&pending_list, 0, id, null);
                if (!(info.params[i].flags & SPA_PARAM_INFO_READ))
                    continue;

                res = pw_node_enum_params (_this, 
                    ++(cast (pw_node_info*) info).params[i].seq, id, 0, -1, null);
                if (SPA_RESULT_IS_ASYNC (res))
                    (cast (pw_node_info*) info).params[i].seq = res;
            }
        }
        if (changed) {
            this.changed += changed;
            core.sync ();
        }

        //foreach (ref Param param; Node_info_params_foreach (_info.n_params, _info.params)) {
        //    auto id_name = param.id.to!string.toStringz;
        //    printf ("\t\t%2d: %s\n", param.id, id_name);

        //    switch (param.id) with (spa_param_type) {
        //        case SPA_PARAM_Format         : _enum_params (param.id); break;
        //        case SPA_PARAM_PropInfo       : _enum_params (param.id); break;
        //        case SPA_PARAM_Props          : _enum_params (param.id); break;
        //        case SPA_PARAM_IO             : _enum_params (param.id); break;
        //        //
        //        case SPA_PARAM_EnumProfile    : break;
        //        case SPA_PARAM_Profile        : break;
        //        case SPA_PARAM_EnumRoute      : break;
        //        case SPA_PARAM_Route          : break;
        //        case SPA_PARAM_EnumPortConfig : break;
        //        case SPA_PARAM_PortConfig     : break;
        //        case SPA_PARAM_Latency        : break;
        //        case SPA_PARAM_ProcessLatency : break;
        //        case SPA_PARAM_Tag            : break;
        //        default                       :
        //    }
        //}
    }

    extern (C)
    void
    param_event (/*void* _node, */int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        //printf ("node\n");
        //printf ("node_param: id:%u\n", id);
        //writefln ("  %s", cast (spa_param_type) id);

        add_param (&pending_list, seq, id, param);
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

    Struct_param*
    add_param (spa_list* params, int seq, uint32_t id, const spa_pod* param)
    {
        Struct_param* p;

        if (id == SPA_ID_INVALID) {
            if (param == null || !spa_pod_is_object (cast (spa_pod*) param)) {
                //errno = EINVAL;
                return null;
            }
            id = SPA_POD_OBJECT_ID (param);
        }
        
        p = cast (Struct_param*) malloc ((*p).sizeof + (param !is null ? SPA_POD_SIZE (param) : 0));
        if (p == null)
            return null;

        p.id = id;
        p.seq = seq;
        if (param !is null) {
            p.param = SPA_PTROFF!(p, (*p).sizeof, spa_pod);
            memcpy (p.param, param, SPA_POD_SIZE (param));
        } else {
            clear_params (params, id);
            p.param = null;
        }
        spa_list_append (params, &p.link);

        return p;
    }

    uint32_t 
    clear_params (spa_list* param_list, uint32_t id) {
        uint32_t count = 0;
        alias Struct_param_list = Spa_list!(Struct_param,"link");
        auto _list = cast (Struct_param_list*) (param_list);

        //foreach (Struct_param* p; spa_list_for_each_safe!(p_, t_, param_list, "link")) {
        foreach (p; _list.for_each_safe) {
            if (id == SPA_ID_INVALID || p.id == id) {
                spa_list_remove (&p.link);
                free (p);
                count++;
            }
        }
        return count;
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
    //Pod (param).dump ("  ");
}
