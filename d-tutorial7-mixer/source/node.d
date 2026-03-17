import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;
import std.string : fromStringz;
import spa;

class
Node {
    pw_node*    _this;
    Core        core;
    spa_hook     node_listener;
    pw_node_info info;
    string[]     params;

    this (void* _this, Core core) {
        this._this = cast (pw_node*) _this;
        this.core = core;

        pw_node_add_listener (
            this._this,
            &node_listener,
            &node_events, 
            cast (void*) this
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    node_info (void* _node, const pw_node_info *_info) {
        with (cast (Node) _node) {
            printf ("node: id: %u\n", _info.id);
            printf ("\tparams: %u\n", _info.n_params);

            info = cast (pw_node_info) (*_info); // props

            params.length = 0;
            const spa_param_info* ps = _info.params;
            uint32_t              n  = _info.n_params;

            for (auto i = 0; i < n; i++) {
                writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);

                params ~= (cast (spa_param_type) ps[i].id).to!string;

                //if (info.params[i].user == 0) continue;
                if (!SPA_FLAG_IS_SET (ps[i].flags, SPA_PARAM_INFO_READ)) continue;

                auto seq = core.pendings.add ();
// node_info_props(&sender, object_id, info);
                pw_node_enum_params (_this, seq, ps[i].id, 0, 0, null);
                core.add_pending (seq);

                //ps[i].user = 0;
            }
            //add_pending (data);

            //with (cast (Ctx) ctx)
            //pw_main_loop_quit (loop);
        }
    }

    extern (C)
    static void
    node_param (void* _node, int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        with (cast (Node) _node) {
            printf ("node param: id:%u\n", id);
            writefln ("  %s", cast (spa_param_type) id);

            if (param is null) goto done;

            switch (id) with (spa_param_type) {
                case SPA_PARAM_Format:
                    uint32_t media_type, media_subtype;
                    if (spa_format_parse (param, &media_type, &media_subtype) < 0) goto done; 
                    writefln ("  media_type: %s", cast (spa_media_type) media_type);
                    writefln ("    %s", cast (spa_media_subtype) media_subtype);
                    switch (media_type) with (spa_media_type) {  // and spa_media_subtype, and spa_format
                        case SPA_MEDIA_TYPE_audio: break;  // SPA_MEDIA_SUBTYPE_raw
                        case SPA_MEDIA_TYPE_video: break;
                        case SPA_MEDIA_TYPE_image: break;
                        case SPA_MEDIA_TYPE_binary: break;
                        case SPA_MEDIA_TYPE_stream: break;
                        case SPA_MEDIA_TYPE_application: break;
                        default:
                    }
                    break;
                case SPA_PARAM_PropInfo:
                    // SPA_TYPE_OBJECT_PropInfo
                    // spa_prop_info
                    // SPA_PROP_INFO_*,       value
                    // SPA_PROP_INFO_id,      SPA_POD_Id(&iid)
                    // SPA_PROP_INFO_type,    SPA_POD_PodChoice(&type)
                    // SPA_PROP_INFO_labels,  SPA_POD_PodStruct(&labels)) < 0)

                    uint iid;
                    const char* desc;
                    const char* name;
                    const spa_pod_choice* ctype;
                    const void* params;
                    uint32_t choice, n_vals, container = SPA_ID_INVALID;

                    import spa;

                    with (spa_prop_info)
                    if (spa_pod_parse_object (param,
                        SPA_TYPE_OBJECT_PropInfo, null,
                        SPA_PROP_INFO_id,           SPA_POD_Id(&iid),
                        SPA_PROP_INFO_name ,        SPA_POD_String(&name),
                        SPA_PROP_INFO_description,  SPA_POD_String(&desc),
                        SPA_PROP_INFO_type,         SPA_POD_PodChoice(&ctype),
                        SPA_PROP_INFO_container,    SPA_POD_Id(&container),
                        //SPA_PROP_INFO_params,       SPA_POD_String(&params),
                    ) < 0)
                        printf ("-EINVAL\n");
                    
                    printf ("  iid,name,desc: %d, %s, %s\n", iid, name, desc);
                    printf ("    type: %p, %d\n", ctype, container);
                    break;

                case SPA_PARAM_Props:
                    // id == ParamType::Props:
                    // node_param_props (&sender, object_id, param);
                    //node_param_props (_node, id, param);

                    uint iid;
                    uint cid;
                    const char* desc;
                    const char* name;
                    const float volume;
                    const float gain;
                    const bool  mute;
                    const uint32_t n_volumes;
                    const float[SPA_AUDIO_MAX_CHANNELS] volumes;
                    const uint32_t n_volumesm;
                    const float[SPA_AUDIO_MAX_CHANNELS] volumesm;
                    const uint32_t n_volumess;
                    const float[SPA_AUDIO_MAX_CHANNELS] volumess;
                    //const float type;
                    const void* params;
                    const bool _params;
                    const spa_pod_struct* labels;
                    const spa_pod_choice* ctype;

                    if (spa_pod_parse_object (param,
                        SPA_TYPE_OBJECT_Props, null,
                        SPA_PROP_volume,            SPA_POD_Float(&volume),
                        //SPA_PROP_mute,              SPA_POD_Bool(&mute),
                        SPA_PROP_channelVolumes,    SPA_POD_Array(float.sizeof, SPA_TYPE_Float, n_volumes, volumes.ptr),
                        //SPA_PROP_monitorVolumes,    SPA_POD_Array(float.sizeof, SPA_TYPE_Float, n_volumesm, volumesm.ptr),
                        //SPA_PROP_softVolumes,       SPA_POD_Array(float.sizeof, SPA_TYPE_Float, n_volumess, volumess.ptr),
                    ) < 0)
                        printf ("    -EINVAL\n");

                    printf ("    volume %f\n", volume);
                    printf ("    channelVolumes %d\n", n_volumes);

                    dump_pod_object (param);
                    break;

                case SPA_PARAM_Tag:
                    break;
                default:
            }

            done:
        }
    }

    static 
    pw_node_events node_events = {
        PW_VERSION_NODE_EVENTS,
        info  : &node_info,
        param : &node_param
    };
}

//void
//node_param_props (void* _node, uint32_t id, spa_pod* param) {
//    with (cast (Node) _node) {
//        import spa_pod_parse_object;
//        uint iid;
//        const char* desc;

//        with (spa_prop_info)
//        _spa_pod_parse_object (param,
//            SPA_TYPE_OBJECT_PropInfo, &id,
//            SPA_PROP_INFO_id, SPA_POD_Id (&iid));

//        spa_pod_parser _p;
//        spa_pod_parser_pod(&_p, pod);
//        int spa_pod_parser_get_object(&_p,type,id,##__VA_ARGS__);
//          struct spa_pod_frame _f;
//            pod;
//            parent;
//            offset;
//            flags;

//        printf ("  iid,desc: %d\n", iid);

//        foreach (prop; param.properties) {
//            switch (prop.key) with (spa_prop) {
//                case SPA_PROP_channelVolumes:   // float
//                    // volumes: prop.value
//                    break;
//                case SPA_PROP_mute:             // bool
//                    // mute: prop.value
//                    break;
//                default:
//            }
//        }
//    }
//}

auto
_SPA_POD_PROP_SIZE (spa_pod_prop* prop) {
    return spa_pod_prop.sizeof + prop.value.size;
}

auto
_SPA_POD_Params2_SIZE (Params2* prop) {
    return spa_pod_prop.sizeof + prop.value.size;
}

auto 
SPA_ROUND_MASK (ulong num, uint mask) {
    return mask - 1;
}

auto
_SPA_ROUND_UP_N (ulong num, uint _align) {
    return ((num-1) | SPA_ROUND_MASK (num, _align)) + 1;
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

    spa_pod_object* obj = cast (spa_pod_object*) param;
    printf ("    obj body size %d\n", obj.pod.size);
    writefln ("    obj body type %s", cast (spa_type) obj.pod.type);

    if (obj.pod.type == SPA_TYPE_Object) {
        auto _prop = cast (spa_pod_prop*) ((cast (void*) &obj.body) + obj.body.sizeof);  // &body + body.sizeof
        for (; 
            (cast (void*)_prop) < ((cast (void*) &obj.body) + obj.pod.size);
            _prop = cast (spa_pod_prop*) ((cast (void*)_prop) + _SPA_ROUND_UP_N (_SPA_POD_PROP_SIZE (_prop), 8)))
        {
            writefln ("      %s: %s", 
                cast (spa_prop) _prop.key,
                cast (spa_type) _prop.value.type);

            if (_prop.key == SPA_PROP_params) {
                // key, value   // string: pod
                if (_prop.value.type == SPA_TYPE_Struct) {
                    // _prop.value
                    // spa_pod
                    //   size
                    //   type
                    //   __content  // Params2
                    auto _prop2 = cast (Params2*) ((&_prop.value) + 1);
                    // foreach...
                    for (; 
                        (cast (void*)_prop2) < ((cast (void*) (&_prop.value)) + _prop.value.size);
                        _prop2 = cast (Params2*) ((cast (void*)_prop2) + _SPA_ROUND_UP_N (_SPA_POD_Params2_SIZE (_prop2), 8)))
                    {
                      writefln ("        %s", cast (spa_type) _prop2.key.pod.type);
                        printf ("        %s", cast (char *) ((&_prop2.key.pod)+1) );
                    }
                }
            }
        }
    }
}

struct
Params2 {
    spa_pod_string key;
    spa_pod        value;
}
