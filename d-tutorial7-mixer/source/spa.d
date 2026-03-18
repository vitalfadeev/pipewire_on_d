module spa;

import importc;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import core.stdc.stdarg;
import spa_list;
import std.conv : to;
import std.string : fromStringz;


auto
spa_pod_parse_object (POD,TYPE,ID,ARGS...) (POD pod,TYPE type,ID id, ARGS args) {
    return __spa_pod_parse_object (pod,type,id,args);
}

//static 
//void 
//print_params (proxy_data* data) {
//    param* p;

//    //with_prefix (use_prefix) {
//        printf ("\tparams:\n");
//    //}

//    // spa_list_for_each (p, &data.param_list, link)
//    param* p;
//    foreach (item; spa_list_for_each (p, &data.param_list, link)) {
//        //printf ("\t\t%s: \"%s\"\n", item.key, item.value);

//    //with_prefix (p.changed) {
//        printf ("\t  id:%u (%s)\n",
//            p.id,
//            spa_debug_type_find_name (spa_type_param, p.id));
//        if (spa_pod_is_object_type (p.param, SPA_TYPE_OBJECT_Format))
//            spa_debug_format (10, NULL, p.param);
//        else
//            spa_debug_pod (10, NULL, p.param);
//    //}
//    //p.changed = false;
//    }
//}

auto removeConst (T) (T value) {
    static if (is (T == const U, U)) {
        return cast (U) value;
    } else {
        return value;
    }
}

auto
spa_dict_for_each (DICT) (DICT dict) {
    auto  items = removeConst (dict.items);
    alias ITEMS = typeof (items);
    return _spa_dict_for_each!(DICT,ITEMS) (dict,items);
}

struct
_spa_dict_for_each (DICT,ITEMS) {
    DICT  dict;
    ITEMS front;
    bool  empty () { return front >= &dict.items[dict.n_items]; }
    void  popFront () { front++; }

    this (DICT dict, ITEMS items) {
        this.dict  = dict;
        this.front = items;
    }
}


// SPA plugin
//gpointer
//wp_corefind_object (WpCore* self, GEqualFunc func, gconstpointer data) {
//  GObject* object;
//  guint    i;

//  /* prevent bad things when called from within wp_registry_clear() */
//  if (G_UNLIKELY (!self.registry.objects))
//      return null;

//  for (i = 0; i < self.registry.objects.len; i++) {
//      object = g_ptr_array_index (self.registry.objects, i);
//      if (func (object, data))
//          return g_object_ref (object);
//  }

//  return null;
//}

//WpPlugin *
//wp_plugin_find (WpCore* core, const gchar* plugin_name) {
//    GObject* p = wp_corefind_object (
//        core,
//        cast (GEqualFunc) find_plugin_func, 
//        GUINT_TO_POINTER (q)
//    );

//    return p;
//}


enum 
spa_type {
    /* Basic types */
    SPA_TYPE_START = 0x00000,
    SPA_TYPE_None,
    SPA_TYPE_Bool,
    SPA_TYPE_Id,
    SPA_TYPE_Int,
    SPA_TYPE_Long,
    SPA_TYPE_Float,
    SPA_TYPE_Double,
    SPA_TYPE_String,
    SPA_TYPE_Bytes,
    SPA_TYPE_Rectangle,
    SPA_TYPE_Fraction,
    SPA_TYPE_Bitmap,
    SPA_TYPE_Array,
    SPA_TYPE_Struct,
    SPA_TYPE_Object,
    SPA_TYPE_Sequence,
    SPA_TYPE_Pointer,
    SPA_TYPE_Fd,
    SPA_TYPE_Choice,
    SPA_TYPE_Pod,
    _SPA_TYPE_LAST,             /**< not part of ABI */

    /* Pointers */
    SPA_TYPE_POINTER_START = 0x10000,
    SPA_TYPE_POINTER_Buffer,
    SPA_TYPE_POINTER_Meta,
    SPA_TYPE_POINTER_Dict,
    _SPA_TYPE_POINTER_LAST,         /**< not part of ABI */

    /* Events */
    SPA_TYPE_EVENT_START = 0x20000,
    SPA_TYPE_EVENT_Device,
    SPA_TYPE_EVENT_Node,
    _SPA_TYPE_EVENT_LAST,           /**< not part of ABI */

    /* Commands */
    SPA_TYPE_COMMAND_START = 0x30000,
    SPA_TYPE_COMMAND_Device,
    SPA_TYPE_COMMAND_Node,
    _SPA_TYPE_COMMAND_LAST,         /**< not part of ABI */

    /* Objects */
    SPA_TYPE_OBJECT_START = 0x40000,
    SPA_TYPE_OBJECT_PropInfo,
    SPA_TYPE_OBJECT_Props,
    SPA_TYPE_OBJECT_Format,
    SPA_TYPE_OBJECT_ParamBuffers,
    SPA_TYPE_OBJECT_ParamMeta,
    SPA_TYPE_OBJECT_ParamIO,
    SPA_TYPE_OBJECT_ParamProfile,
    SPA_TYPE_OBJECT_ParamPortConfig,
    SPA_TYPE_OBJECT_ParamRoute,
    SPA_TYPE_OBJECT_Profiler,
    SPA_TYPE_OBJECT_ParamLatency,
    SPA_TYPE_OBJECT_ParamProcessLatency,
    SPA_TYPE_OBJECT_ParamTag,
    _SPA_TYPE_OBJECT_LAST,          /**< not part of ABI */

    /* vendor extensions */
    SPA_TYPE_VENDOR_PipeWire    = 0x02000000,

    SPA_TYPE_VENDOR_Other       = 0x7f000000,
};

enum SPA_POD_PROP_FLAG_HINT_DICT = (1u<<2);

template
_Object_key_type (alias TObject) {
    static if (TObject == SPA_TYPE_OBJECT_Props)               alias _Object_key_type = spa_prop;
    static if (TObject == SPA_TYPE_OBJECT_ParamRoute)          alias _Object_key_type = spa_param_route;
    static if (TObject == SPA_TYPE_OBJECT_ParamTag)            alias _Object_key_type = spa_param_tag;
    static if (TObject == SPA_TYPE_OBJECT_ParamBuffers)        alias _Object_key_type = spa_param_buffers;
    static if (TObject == SPA_TYPE_OBJECT_ParamMeta)           alias _Object_key_type = spa_param_meta;
    static if (TObject == SPA_TYPE_OBJECT_ParamIO)             alias _Object_key_type = spa_param_io;
    static if (TObject == SPA_TYPE_OBJECT_ParamDict)           alias _Object_key_type = spa_param_dict;
    static if (TObject == SPA_TYPE_OBJECT_Format)              alias _Object_key_type = spa_media_type;
    static if (TObject == SPA_TYPE_OBJECT_ParamLatency)        alias _Object_key_type = spa_param_latency;
    static if (TObject == SPA_TYPE_OBJECT_ParamProcessLatency) alias _Object_key_type = spa_param_process_latency;
    static if (TObject == SPA_TYPE_OBJECT_PeerParam)           alias _Object_key_type = spa_peer_param;
    static if (TObject == SPA_TYPE_OBJECT_ParamPortConfig)     alias _Object_key_type = spa_param_port_config;
    static if (TObject == SPA_TYPE_OBJECT_ParamProfile)        alias _Object_key_type = spa_param_profile  ;
    static if (TObject == SPA_TYPE_OBJECT_Profiler)            alias _Object_key_type = spa_profiler;
    static if (TObject == SPA_TYPE_OBJECT_PropInfo)            alias _Object_key_type = spa_prop_info;
}

// Node
//   params
struct
Node_info_foreach {
    Param    front;
    bool     empty ()    { return length == 0; }
    void     popFront () { front = front.next (); length--; }
    pw_node* node;
    const pw_node_info* _info;
    uint32_t length;

    this (pw_node* node, pw_node_info* _info) {  // pw_node*
        this.node   =  node;
        this._info  = _info;
        this.front  = Param (_info.params);
        this.length = _info.n_params;
    }
}
//   props
struct
Pod_object_foreach (alias TObject) { // SPA_POD_OBJECT_FOREACH
    alias Key        = _Object_key_type!TObject;
    alias Prop       = _Prop!Key;
    alias Pod_object = _Pod_object!Prop;
    Prop front;
    bool empty ()    { return !obj.is_inside (front); }
    void popFront () { front = front.next (); }
    Pod_object obj;

    @disable this();

    this (spa_pod_object* obj) {  // pod*
        this.obj   = Pod_object (obj);
        this.front = this.obj.prop_first ();
    }

    this (spa_pod* pod) {
        this (cast (spa_pod_object*) pod);
    }
}

struct
Pod_struct_foreach {  // SPA_POD_STRUCT_FOREACH
    Pod  front;
    bool empty ()    { return !pod_struct.is_inside (front); }
    void popFront () { front = front.next (); }
    Pod  pod_struct;  // size,type, ...[]

    @disable this();

    this (spa_pod* pod) {
        this.pod_struct = Pod (pod);
        this.front      = Pod (SPA_POD_BODY (pod));
    }
}

struct
Pod_array_foreach {  // SPA_POD_ARRAY_FOREACH, SPA_POD_ARRAY_BODY_FOREACH
    Pod  front;
    bool empty ()    { return !(pod_array.size > 0 && pod_array.is_inside (front)); }
    void popFront () { front = front.next (); }
    Pod  pod_array;  // size,type, ...[]

    @disable this();

    this (spa_pod* pod) {
        this.pod_array = Pod (pod);
        this.front     = Pod (SPA_POD_BODY (pod));
    }
}

struct
Pod {
    spa_pod* _this;
    alias _this this;

    Pod
    next () {
        return Pod (cast (spa_pod*) spa_pod_next (_this));
    }

    bool
    is_inside (Pod pod) {
        return spa_pod_is_inside (_this, _this.size, pod._this);
    }

    bool
    find (spa_prop key) {  // SPA_PROP_volume, SPA_PROP_channelVolumes, SPA_PROP_softVolumes
        return false;
    }

    bool
    find_any (spa_prop[] key) {  // SPA_PROP_volume, SPA_PROP_channelVolumes, SPA_PROP_softVolumes
        return false;
    }

    string
    as_string () {
        switch (_this.type) with (spa_type) {
            case SPA_TYPE_Bool   : return (cast (spa_pod_bool*)   _this).value.to!string;
            case SPA_TYPE_Id     : return (cast (spa_pod_id*)     _this).value.to!string;
            case SPA_TYPE_Int    : return (cast (spa_pod_int *)   _this).value.to!string;
            case SPA_TYPE_Long   : return (cast (spa_pod_long *)  _this).value.to!string;
            case SPA_TYPE_Float  : return (cast (spa_pod_float*)  _this).value.to!string;
            case SPA_TYPE_Double : return (cast (spa_pod_double*) _this).value.to!string;
            case SPA_TYPE_String : return fromStringz (cast (char*) SPA_POD_BODY (cast (spa_pod*) _this)).to!string;
            case SPA_TYPE_Choice : 
                // n_vals
                // choice
                uint32_t n_vals;
                uint32_t choice;
                spa_pod* child;
                child = spa_pod_get_values (_this, &n_vals, &choice);
                return Pod (child).as_string;

            case SPA_TYPE_Struct : 
                string s;
                s ~= "[";
                foreach (pod; Pod_struct_foreach (_this)) {
                    if (s.length > 1) s ~= ", ";
                    s ~= pod.as_string;
                }
                s ~= "]";
                return s;

            case SPA_TYPE_Array : 
                string s;
                s ~= "[";
                foreach (pod; Pod_array_foreach (_this)) {
                    if (s.length > 1) s ~= ", ";
                    s ~= pod.as_string;
                }
                s ~= "]";
                return s;
            //case SPA_TYPE_OBJECT_Props    : return "?";
            //case SPA_TYPE_OBJECT_Format   : return "?";
            default                       :
                return "? ("~(cast (spa_type) _this.type).to!string~")";
        }
    }

    void
    parse () {
        switch (_this.type) with (spa_type) {
            case SPA_TYPE_OBJECT_PropInfo : _parse_PropInfo (); break;
            case SPA_TYPE_OBJECT_Props    : break;
            case SPA_TYPE_OBJECT_Format   : break;
            default                       :
        }
    }

    void
    _parse_PropInfo () {
        uint32_t iid;

        foreach (/*Prop*/ prop; Pod_object_foreach!SPA_TYPE_OBJECT_PropInfo (_this)) {
            writefln ("  %s: %s", prop.key, prop.value_type);
            switch (prop.key) with (spa_prop_info) {
                case SPA_PROP_INFO_id : break;
                default:
            }
        }

        spa_pod* info = SPA_POD_BODY (_this);
    }

    void
    dump (string prefix="") {
        switch (_this.type) with (spa_type) {
            case SPA_TYPE_Bool   : writefln ("%s%d", prefix, (cast (spa_pod_bool*)   _this).value); break;
            case SPA_TYPE_Id     : writefln ("%s%d", prefix, (cast (spa_pod_id*)     _this).value); break;
            case SPA_TYPE_Int    : writefln ("%s%d", prefix, (cast (spa_pod_int *)   _this).value); break;
            case SPA_TYPE_Long   : writefln ("%s%d", prefix, (cast (spa_pod_long *)  _this).value); break;
            case SPA_TYPE_Float  : writefln ("%s%f", prefix, (cast (spa_pod_float*)  _this).value); break;
            case SPA_TYPE_Double : writefln ("%s%f", prefix, (cast (spa_pod_double*) _this).value); break;
            case SPA_TYPE_String : writefln ("%s%s", prefix, fromStringz (cast (char*) SPA_POD_BODY (cast (spa_pod*) _this)).to!string); break;
            case SPA_TYPE_Array  : 
                writefln ("%s%s", prefix, cast (spa_type) (cast (spa_pod_array*)  _this).body.child.type); 
                // foreach array of pod.body.child.type
                break;
            case SPA_TYPE_Object : 
                //foreach (Prop prop; Pod_object_foreach (_this)) {
                //    writefln ("%s%s: %s", prefix, prop.key, prop.value_type);
                //    Pod (prop.value).dump (prefix~" ");
                //}
                break;
            case SPA_TYPE_Struct : 
                foreach (Pod _param; Pod_struct_foreach (_this)) {
                    _param.dump (prefix~" ");
                }
                break;
            default              : writefln ("%s?", prefix);
        }
    }
}

struct
_Pod_object (Prop) {
    spa_pod_object* _this;

    Prop
    prop_first () {
        return Prop (spa_pod_prop_first (&_this.body));
    }

    bool
    is_inside (Prop prop) {
        return spa_pod_prop_is_inside (&_this.body, _this.pod.size, prop._this);
    }
}

struct
_Prop (Key) {
    spa_pod_prop* _this;

    Key      key        () { return cast (Key)       _this.key; }
    Pod      value      () { return Pod (cast (spa_pod*) &_this.value); }
    spa_type value_type () { return cast (spa_type)  _this.value.type; }

    _Prop!Key
    next () {
        return _Prop!Key (spa_pod_prop_next (_this));
    }
}

struct
Param {
    spa_param_info* _this;
    alias _this this;

    spa_param_type id () { return cast (spa_param_type) _this.id; }

    Param
    next () {
        return Param (_this+1);
    }
}

auto
SPA_PTROFF (T,BASE) (BASE* base, size_t offset) {
    return cast (T*) (base + offset);
}

auto
SPA_POD_BODY (spa_pod* pod) {
    return SPA_PTROFF!spa_pod (pod,1);
}

auto
_SPA_POD_PROP_SIZE (spa_pod_prop* prop) {
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


