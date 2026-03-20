module spa;

import importc;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import core.stdc.stdarg;
import std.conv : to;
import std.string : fromStringz;
import std.format : format;


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

auto 
removeConst (T) (T value) {
    static if (is (T == const U, U)) {
        return cast (U) value;
    } else {
        return value;
    }
}

// pw_node_info
//   id
//   state
//   params
//   n_params
//
// params  
// spa_param_info
//   id            // spa_param_type
//   flags
//   user
//   seq
//
// spa_pod
//   size
//   type          // spa_pod_type
struct
Pod {
    spa_pod _this;
    alias _this this;

    string
    as_string () {
        if (spa_pod_is_bool (&_this)) {
            bool bool_value;
            spa_pod_get_bool (&_this, &bool_value); 
            return bool_value.to!string;
        }
        if (spa_pod_is_int (&_this)) {
            int int_value;
            spa_pod_get_int (&_this, &int_value); 
            return int_value.to!string;
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_PropInfo)) {
            string s = "[\n";
            foreach (spa_pod_prop* prop; object_foreach) {
                s ~= "  " ~ prop.key.to!string ~ ": "~ ((cast (Pod*) &prop.value).as_string) ~ ",\n";
            }
            s ~= "]\n";
            return s;
            //return "?SPA_TYPE_OBJECT_PropInfo";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_Format)) {
            return "?SPA_TYPE_OBJECT_Format";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamBuffers)) {
            return "?SPA_TYPE_OBJECT_ParamBuffers";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamMeta)) {
            return "?SPA_TYPE_OBJECT_ParamMeta";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamIO)) {
            return "?SPA_TYPE_OBJECT_ParamIO";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamProfile)) {
            return "?SPA_TYPE_OBJECT_ParamProfile";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamPortConfig)) {
            return "?SPA_TYPE_OBJECT_ParamPortConfig";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamPortConfig)) {
            return "?SPA_TYPE_OBJECT_ParamPortConfig";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamRoute)) {
            return "?SPA_TYPE_OBJECT_ParamRoute";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_Profiler)) {
            return "?SPA_TYPE_OBJECT_Profiler";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamLatency)) {
            return "?SPA_TYPE_OBJECT_ParamLatency";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamProcessLatency)) {
            return "?SPA_TYPE_OBJECT_ParamProcessLatency";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamTag)) {
            return "?SPA_TYPE_OBJECT_ParamTag";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_PeerParam)) {
            return "?SPA_TYPE_OBJECT_PeerParam";
        }
        if (spa_pod_is_object_type (&_this, SPA_TYPE_OBJECT_ParamDict)) {
            return "?SPA_TYPE_OBJECT_ParamDict";
        }

        switch (type) with (spa_pod_type) {
            case Bool   : return (cast (spa_pod_bool)   _this).value.to!string;
            case Id     : return (cast (spa_pod_id)     _this).value.to!string;
            case Int    : return (cast (spa_pod_int)    _this).value.to!string;
            case Long   : return (cast (spa_pod_long)   _this).value.to!string;
            case Float  : return (cast (spa_pod_float)  _this).value.to!string;
            case Double : return (cast (spa_pod_double) _this).value.to!string;
            case String : return fromStringz (cast (char*) SPA_POD_BODY (&_this)).to!string;
            case Choice : 
                // n_vals
                // choice
                uint32_t n_vals;
                uint32_t choice;
                spa_pod* child;
                child = spa_pod_get_values (&_this, &n_vals, &choice);
                return (cast (.Pod*) child).as_string;

            case Struct : 
                string s;
                s ~= "[";
                foreach (spa_pod* pod; (cast (.Pod*) &_this).struct_foreach) {
                    if (s.length > 1) s ~= ", ";
                    s ~= (cast (.Pod*) pod).as_string;
                }
                s ~= "]";
                return s;

            case Array : 
                string s;
                s ~= "[";
                foreach (spa_pod* pod; (cast (.Pod*) &_this).array_foreach) {
                    if (s.length > 1) s ~= ", ";
                    s ~= (cast (.Pod*) pod).as_string;
                }
                s ~= "]";
                return s;

            default:
        }
        return "?";
    }

    auto
    object_foreach () {
        return Object_range (cast (spa_pod_object*) &_this);
    }

    auto
    struct_foreach () {
        return Struct_range (cast (spa_pod_struct*) &_this);
    }

    auto
    array_foreach () {
        return Array_range (cast (spa_pod_array*) &_this);
    }

    spa_pod_prop*
    find_prop (uint32_t key) {
        assert (spa_pod_is_object (&_this));
        if (spa_pod_is_object (&_this))
        foreach (spa_pod_prop* prop; object_foreach)
            if (prop.key == key)
                return prop;
        return null;
    }

    // SPA_POD_OBJECT_FOREACH
    // SPA_POD_OBJECT_BODY_FOREACH (&(obj)->body, SPA_POD_BODY_SIZE(obj), iter)
    // SPA_POD_OBJECT_BODY_FOREACH (body, size, iter)
    // for ((iter) = spa_pod_prop_first(body);
    //      spa_pod_prop_is_inside(body, size, iter);
    //      (iter) = spa_pod_prop_next(iter))
    struct
    Object_range {  
        alias  OBJ   = spa_pod_object;       // pod, body, prop[]
        alias  BODY  = spa_pod_object_body;  // type, id,  prop[]
        alias  FRONT = spa_pod_prop;         // key, flag, value
        OBJ*   obj;
        BODY*  body;
        FRONT* front;
        bool   empty ()    { return !spa_pod_prop_is_inside (body, obj.pod.size, front); }
        void   popFront () { front = spa_pod_prop_next (front); }

        @disable this ();

        this (OBJ* obj) {
            this.obj   = obj;
            this.body  = &obj.body;
            this.front = spa_pod_prop_first (body);
        }
    }

    // SPA_POD_STRUCT_FOREACH (classes, iter)  // struct spa_pod *iter;
    // SPA_POD_STRUCT_FOREACH (pod, o)         // struct spa_pod *o;
    // SPA_POD_STRUCT_FOREACH (pod, o)         // struct spa_pod *o;
    // 
    // SPA_POD_STRUCT_FOREACH (obj, iter)
    // SPA_POD_FOREACH (SPA_POD_BODY(obj), SPA_POD_BODY_SIZE(obj), iter)
    // SPA_POD_FOREACH (pod, size, iter)
    //   for ((iter) = (pod);
    //     spa_pod_is_inside(pod, size, iter);
    //     (iter) = (__typeof__(iter))spa_pod_next(iter))
    struct
    Struct_range {
        alias  POD   = spa_pod_struct;  // spa_pod pod, ... spa_pod[]
        alias  FRONT = spa_pod;
        POD*   pod;
        FRONT* front;
        bool   empty ()    { return !spa_pod_is_inside (pod, pod.pod.size, front); }
        void   popFront () { front = cast (FRONT*) spa_pod_next (front); }

        @disable this ();

        this (spa_pod_struct* pod) {
            this.pod   = pod;
            this.front = cast (FRONT*) pod;
        }
    }

    // SPA_POD_ARRAY_FOREACH
    // SPA_POD_ARRAY_FOREACH (obj, iter)
    // SPA_POD_ARRAY_BODY_FOREACH (&(obj)->body, SPA_POD_BODY_SIZE(obj), iter)
    // SPA_POD_ARRAY_BODY_FOREACH (body, _size, iter)
    // for ((iter) = (__typeof__(iter))SPA_PTROFF((body), sizeof(struct spa_pod_array_body), void);
    //      (body)->child.size > 0 && spa_ptrinside(body, _size, iter, (body)->child.size, NULL);
    //      (iter) = (__typeof__(iter))SPA_PTROFF((iter), (body)->child.size, void))
    struct
    Array_range {
        alias  POD   = spa_pod_array;  // spa_pod pod, spa_pod_array_body body = spa_pod child, ...spa_pod[]
        alias  FRONT = spa_pod;
        POD*   pod;
        FRONT* front;
        bool   empty ()    { return !(pod.body.child.size > 0 && spa_ptrinside (&pod.body, pod.pod.size, front, pod.body.child.size, null)); }
        void   popFront () { front = cast (FRONT*) ((cast (void*) front) + pod.body.child.size); }

        @disable this ();

        this (POD* pod) {
            this.pod = pod;
            this.front = cast (FRONT*) ((cast (void*) &pod.body) + spa_pod_array_body.sizeof);
        }
    }
}

enum
spa_pod_type {
    None      = SPA_TYPE_None,
    Bool      = SPA_TYPE_Bool,
    Id        = SPA_TYPE_Id,
    //
    Int       = SPA_TYPE_Int,
    Long      = SPA_TYPE_Long,
    Float     = SPA_TYPE_Float,
    Double    = SPA_TYPE_Double,
    // 
    String    = SPA_TYPE_String,
    Bytes     = SPA_TYPE_Bytes,
    Rectangle = SPA_TYPE_Rectangle,
    Fraction  = SPA_TYPE_Fraction,
    Bitmap    = SPA_TYPE_Bitmap,
    //
    Array     = SPA_TYPE_Array,
    Struct    = SPA_TYPE_Struct,
    Object    = SPA_TYPE_Object,
    Sequence  = SPA_TYPE_Sequence,
    //
    Pointer   = SPA_TYPE_Pointer,
    Fd        = SPA_TYPE_Fd,
    Choice    = SPA_TYPE_Choice,
    Pod       = SPA_TYPE_Pod,
}

struct
Spa_list (CONTAINER=spa_list, string member="link") {
    spa_list _this;     // head // next: Struct_param* with spa_list member
    alias _this this;    //         prev: Struct_param* with spa_list member

    static assert (__traits (hasMember, CONTAINER, member), "expect field '"~member~"` in type '"~CONTAINER.stringof~"'");
    @disable this ();

    auto
    for_each_safe () {
        return Range!(CONTAINER,member) (&_this);
    }

    struct
    Range (CONTAINER, string member) {
        spa_list*  head;
        CONTAINER* front;
        spa_list*  tmp;
        bool       empty ()    { return  tmp is head; }
        void       popFront () { 
            tmp   = __traits (getMember, front, member).next; 
            front = cast (CONTAINER*) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof")); 
        }

        this (spa_list* head) {
            this.head  = head;
            this.tmp   = head.next; 
            this.front = cast (CONTAINER*) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof")); 
        }
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

auto
spa_list_for_each_safe (alias pos, alias tmp, alias head, string member) () {
    alias POS  = typeof (pos);
    alias TMP  = typeof (tmp);
    alias CURR = typeof (head);
    alias HEAD = typeof (head);
    return spa_list_for_each_safe_next!(POS,TMP,CURR,HEAD,member) (pos,tmp,head,head);
}

struct
spa_list_for_each_safe_next (POS,TMP,CURR,HEAD,string member) {
    POS   front;
    TMP   tmp;
    HEAD  head;
    alias pos = front;
    bool empty () {
        (tmp) = spa_list_next!(pos,member);
        return spa_list_is_end!member (pos, head);
    }
    void popFront () {
        (front) = (tmp);
    }

    this (POS pos,TMP tmp, CURR curr, HEAD head) {
        this.front = spa_list_first!(head, typeof (*(pos)), member);
        this.tmp   = tmp;
        this.head  = head;
    }
}


//template
//spa_list_next (alias pos, string member) {
//    enum spa_list_next = _spa_list_next!member (pos);
//}

//auto
//spa_list_append (LIST,ITEM) (LIST list, ITEM item) {
//    spa_list_insert ((list).prev, item);
//}

auto
SPA_CONTAINER_OF (alias p, TYPE, string member) () {
    return (cast (TYPE*) (cast (uintptr_t) (p) - mixin ("TYPE."~member~".offsetof")));
}

auto
spa_list_is_end (string member, POS, HEAD) (POS pos, HEAD head) {
    return mixin ("&(pos)."~member~" == (head)");
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


//enum 
//spa_type {
//    /* Basic types */
//    SPA_TYPE_START = 0x00000,
//    SPA_TYPE_None,
//    SPA_TYPE_Bool,
//    SPA_TYPE_Id,
//    SPA_TYPE_Int,
//    SPA_TYPE_Long,
//    SPA_TYPE_Float,
//    SPA_TYPE_Double,
//    SPA_TYPE_String,
//    SPA_TYPE_Bytes,
//    SPA_TYPE_Rectangle,
//    SPA_TYPE_Fraction,
//    SPA_TYPE_Bitmap,
//    SPA_TYPE_Array,
//    SPA_TYPE_Struct,
//    SPA_TYPE_Object,
//    SPA_TYPE_Sequence,
//    SPA_TYPE_Pointer,
//    SPA_TYPE_Fd,
//    SPA_TYPE_Choice,
//    SPA_TYPE_Pod,
//    _SPA_TYPE_LAST,             /**< not part of ABI */

//    /* Pointers */
//    SPA_TYPE_POINTER_START = 0x10000,
//    SPA_TYPE_POINTER_Buffer,
//    SPA_TYPE_POINTER_Meta,
//    SPA_TYPE_POINTER_Dict,
//    _SPA_TYPE_POINTER_LAST,         /**< not part of ABI */

//    /* Events */
//    SPA_TYPE_EVENT_START = 0x20000,
//    SPA_TYPE_EVENT_Device,
//    SPA_TYPE_EVENT_Node,
//    _SPA_TYPE_EVENT_LAST,           /**< not part of ABI */

//    /* Commands */
//    SPA_TYPE_COMMAND_START = 0x30000,
//    SPA_TYPE_COMMAND_Device,
//    SPA_TYPE_COMMAND_Node,
//    _SPA_TYPE_COMMAND_LAST,         /**< not part of ABI */

//    /* Objects */
//    SPA_TYPE_OBJECT_START = 0x40000,
//    SPA_TYPE_OBJECT_PropInfo,
//    SPA_TYPE_OBJECT_Props,
//    SPA_TYPE_OBJECT_Format,
//    SPA_TYPE_OBJECT_ParamBuffers,
//    SPA_TYPE_OBJECT_ParamMeta,
//    SPA_TYPE_OBJECT_ParamIO,
//    SPA_TYPE_OBJECT_ParamProfile,
//    SPA_TYPE_OBJECT_ParamPortConfig,
//    SPA_TYPE_OBJECT_ParamRoute,
//    SPA_TYPE_OBJECT_Profiler,
//    SPA_TYPE_OBJECT_ParamLatency,
//    SPA_TYPE_OBJECT_ParamProcessLatency,
//    SPA_TYPE_OBJECT_ParamTag,
//    _SPA_TYPE_OBJECT_LAST,          /**< not part of ABI */

//    /* vendor extensions */
//    SPA_TYPE_VENDOR_PipeWire    = 0x02000000,

//    SPA_TYPE_VENDOR_Other       = 0x7f000000,
//};

enum SPA_POD_PROP_FLAG_HINT_DICT = (1u<<2);

template
_Object_key_type (alias TObject) {
    static if (TObject == spa_type.SPA_TYPE_OBJECT_Props)               alias _Object_key_type = spa_prop;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamRoute)          alias _Object_key_type = spa_param_route;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamTag)            alias _Object_key_type = spa_param_tag;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamBuffers)        alias _Object_key_type = spa_param_buffers;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamMeta)           alias _Object_key_type = spa_param_meta;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamIO)             alias _Object_key_type = spa_param_io;
//    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamDict)           alias _Object_key_type = spa_param_dict;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_Format)              alias _Object_key_type = spa_media_type;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamLatency)        alias _Object_key_type = spa_param_latency;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamProcessLatency) alias _Object_key_type = spa_param_process_latency;
//    static if (TObject == spa_type.SPA_TYPE_OBJECT_PeerParam)           alias _Object_key_type = spa_peer_param;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamPortConfig)     alias _Object_key_type = spa_param_port_config;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_ParamProfile)        alias _Object_key_type = spa_param_profile  ;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_Profiler)            alias _Object_key_type = spa_profiler;
    static if (TObject == spa_type.SPA_TYPE_OBJECT_PropInfo)            alias _Object_key_type = spa_prop_info;
}

// Node
//   params
struct
Node_info_params_foreach {
    Param[]  params;
    alias params this;

    @disable this();

    this (const spa_param_info[] params) {
        this.params = cast (Param[]) params;
    }

    this (uint32_t n_params, const spa_param_info* params) {
        this.params = cast (Param[]) params[0..n_params];
    }
}
//   props
//struct
//Pod_object_foreach (alias TObject) { // SPA_POD_OBJECT_FOREACH
//    alias Key        = _Object_key_type!TObject;
//    alias Prop       = _Prop!Key;
//    alias Pod_object = _Pod_object!Prop;
//    Prop front;
//    bool empty ()    { return !obj.is_inside (front); }
//    void popFront () { front = front.next (); }
//    Pod_object obj;

//    @disable this();

//    this (spa_pod_object* obj) {  // pod*
//        this.obj   = Pod_object (obj);
//        this.front = this.obj.prop_first ();
//    }

//    this (spa_pod* pod) {
//        this (cast (spa_pod_object*) pod);
//    }
//}

//struct
//Pod_struct_foreach {  // SPA_POD_STRUCT_FOREACH
//    Pod  front;
//    bool empty ()    { return !pod_struct.is_inside (front); }
//    void popFront () { front = front.next (); }
//    Pod  pod_struct;  // size,type, ...[]

//    @disable this();

//    this (spa_pod* pod) {
//        this.pod_struct = Pod (pod);
//        this.front      = Pod (cast (spa_pod*) SPA_POD_BODY (pod));
//    }
//}

//struct
//Pod_array_foreach {  // SPA_POD_ARRAY_FOREACH, SPA_POD_ARRAY_BODY_FOREACH
//    Pod  front;
//    bool empty ()    { return !(pod_array.size > 0 && pod_array.is_inside (front)); }
//    void popFront () { front = front.next (); }
//    Pod  pod_array;  // size,type, ...[]

//    @disable this();

//    this (spa_pod* pod) {
//        this.pod_array = Pod (pod);
//        this.front     = Pod (cast (spa_pod*) SPA_POD_BODY (pod));
//    }
//}

//struct
//__Pod {
//    spa_pod* _this;
//    alias _this this;

//    Pod
//    next () {
//        return Pod (cast (spa_pod*) spa_pod_next (_this));
//    }

//    bool
//    is_inside (Pod pod) {
//        return spa_pod_is_inside (_this, _this.size, pod._this);
//    }

//    bool
//    find (spa_prop key) {  // SPA_PROP_volume, SPA_PROP_channelVolumes, SPA_PROP_softVolumes
//        return false;
//    }

//    bool
//    find_any (spa_prop[] key) {  // SPA_PROP_volume, SPA_PROP_channelVolumes, SPA_PROP_softVolumes
//        return false;
//    }

//    //Pod
//    //copy () {
//    //    auto _p = cast (spa_pod*) malloc (SPA_POD_SIZE (_this));
//    //    memcpy (_p, _this, SPA_POD_SIZE (_this));
//    //    return Pod (_p);
//    //}

//    string
//    as_string () {
//        switch (_this.type) with (spa_type) {
//            case SPA_TYPE_Bool   : return (cast (spa_pod_bool*)   _this).value.to!string;
//            case SPA_TYPE_Id     : return (cast (spa_pod_id*)     _this).value.to!string;
//            case SPA_TYPE_Int    : return (cast (spa_pod_int *)   _this).value.to!string;
//            case SPA_TYPE_Long   : return (cast (spa_pod_long *)  _this).value.to!string;
//            case SPA_TYPE_Float  : return (cast (spa_pod_float*)  _this).value.to!string;
//            case SPA_TYPE_Double : return (cast (spa_pod_double*) _this).value.to!string;
//            case SPA_TYPE_String : return fromStringz (cast (char*) SPA_POD_BODY (cast (spa_pod*) _this)).to!string;
//            case SPA_TYPE_Choice : 
//                // n_vals
//                // choice
//                uint32_t n_vals;
//                uint32_t choice;
//                spa_pod* child;
//                child = spa_pod_get_values (_this, &n_vals, &choice);
//                return Pod (child).as_string;

//            case SPA_TYPE_Struct : 
//                string s;
//                s ~= "[";
//                foreach (pod; Pod_struct_foreach (_this)) {
//                    if (s.length > 1) s ~= ", ";
//                    s ~= pod.as_string;
//                }
//                s ~= "]";
//                return s;

//            case SPA_TYPE_Array : 
//                string s;
//                s ~= "[";
//                foreach (pod; Pod_array_foreach (_this)) {
//                    if (s.length > 1) s ~= ", ";
//                    s ~= pod.as_string;
//                }
//                s ~= "]";
//                return s;

                
//            case SPA_TYPE_Object    : 
//                string s;
//                s ~= "[\n    ";

//                auto obj = cast (spa_pod_object*) _this;

//                switch (obj.body.id) with (spa_param_type) {
//                    case SPA_PARAM_Format:
//                        // SPA_PARAM_Format => SPA_TYPE_OBJECT_Format => spa_media_type
//                        foreach (prop; Pod_object_foreach!(spa_type.SPA_TYPE_OBJECT_Format) (obj)) {
//                            if (s.length > 7) s ~= ",\n    ";
//                            s ~= format!"%27s: %s" (prop.key, prop.value.as_string); 
//                        }
//                        break;
//                    case SPA_PARAM_PropInfo:
//                        // SPA_PARAM_PropInfo => SPA_TYPE_OBJECT_PropInfo => spa_prop_info[]
//                        foreach (prop; Pod_object_foreach!(spa_type.SPA_TYPE_OBJECT_PropInfo) (obj)) {
//                            if (s.length > 7) s ~= ",\n    ";
//                            s ~= format!"%27s: %s" (prop.key, prop.value.as_string); 
//                        }
//                        break;

//                    case SPA_PARAM_Props:
//                        // SPA_PARAM_Props => SPA_TYPE_OBJECT_Props => spa_prop[]
//                        foreach (prop; Pod_object_foreach!(spa_type.SPA_TYPE_OBJECT_Props) (obj)) {
//                            if (s.length > 7) s ~= ",\n    ";
//                            s ~= format!"%27s: %s" (prop.key, prop.value.as_string); 
//                        }
//                        break;

//                    case SPA_PARAM_IO:
//                        // SPA_PARAM_IO => SPA_TYPE_OBJECT_ParamIO => spa_param_io[]
//                        foreach (prop; Pod_object_foreach!(spa_type.SPA_TYPE_OBJECT_ParamIO) (obj)) {
//                            if (s.length > 7) s ~= ",\n    ";
//                            s ~= format!"%27s: %s" (prop.key, prop.value.as_string); 
//                        }
//                        break;

//                    case SPA_PARAM_Tag:
//                        break;

//                    default:
//                }

//                s ~= "]";
//                return s;

//            //case SPA_TYPE_OBJECT_Format   : return "?";
//            default                       :
//                return "? ("~(cast (spa_type) _this.type).to!string~")";
//        }
//    }

//    void
//    parse () {
//        switch (_this.type) with (spa_type) {
//            case SPA_TYPE_OBJECT_PropInfo : _parse_PropInfo (); break;
//            case SPA_TYPE_OBJECT_Props    : break;
//            case SPA_TYPE_OBJECT_Format   : break;
//            default                       :
//        }
//    }

//    void
//    _parse_PropInfo () {
//        uint32_t iid;

//        foreach (/*Prop*/ prop; Pod_object_foreach!(spa_type.SPA_TYPE_OBJECT_PropInfo) (_this)) {
//            writefln ("  %s: %s", prop.key, prop.value_type);
//            switch (prop.key) with (spa_prop_info) {
//                case SPA_PROP_INFO_id : break;
//                default:
//            }
//        }

//        spa_pod* info = cast (spa_pod*) SPA_POD_BODY (_this);
//    }

//    void
//    dump (string prefix="") {
//        switch (_this.type) with (spa_type) {
//            case SPA_TYPE_Bool   : writefln ("%s%d", prefix, (cast (spa_pod_bool*)   _this).value); break;
//            case SPA_TYPE_Id     : writefln ("%s%d", prefix, (cast (spa_pod_id*)     _this).value); break;
//            case SPA_TYPE_Int    : writefln ("%s%d", prefix, (cast (spa_pod_int *)   _this).value); break;
//            case SPA_TYPE_Long   : writefln ("%s%d", prefix, (cast (spa_pod_long *)  _this).value); break;
//            case SPA_TYPE_Float  : writefln ("%s%f", prefix, (cast (spa_pod_float*)  _this).value); break;
//            case SPA_TYPE_Double : writefln ("%s%f", prefix, (cast (spa_pod_double*) _this).value); break;
//            case SPA_TYPE_String : writefln ("%s%s", prefix, fromStringz (cast (char*) SPA_POD_BODY (cast (spa_pod*) _this)).to!string); break;
//            case SPA_TYPE_Array  : 
//                writefln ("%s%s", prefix, cast (spa_type) (cast (spa_pod_array*)  _this).body.child.type); 
//                // foreach array of pod.body.child.type
//                break;
//            case SPA_TYPE_Object : 
//                //foreach (Prop prop; Pod_object_foreach (_this)) {
//                //    writefln ("%s%s: %s", prefix, prop.key, prop.value_type);
//                //    Pod (prop.value).dump (prefix~" ");
//                //}
//                break;
//            case SPA_TYPE_Struct : 
//                foreach (Pod _param; Pod_struct_foreach (_this)) {
//                    _param.dump (prefix~" ");
//                }
//                break;
//            default              : writefln ("%s?", prefix);
//        }
//    }
//}

//struct
//_Pod_object (Prop) {
//    spa_pod_object* _this;

//    Prop
//    prop_first () {
//        return Prop (spa_pod_prop_first (&_this.body));
//    }

//    bool
//    is_inside (Prop prop) {
//        return spa_pod_prop_is_inside (&_this.body, _this.pod.size, prop._this);
//    }
//}

//struct
//_Prop (Key) {
//    spa_pod_prop* _this;

//    Key      key        () { return cast (Key)       _this.key; }
//    Pod      value      () { return Pod (cast (spa_pod*) &_this.value); }
//    spa_type value_type () { return cast (spa_type)  _this.value.type; }

//    _Prop!Key
//    next () {
//        return _Prop!Key (spa_pod_prop_next (_this));
//    }
//}

struct
Param {
    spa_param_info _this;
    alias _this this;

    spa_param_type id () { return cast (spa_param_type) _this.id; }

    //Param
    //next () {
    //    return Param (_this+1);
    //}
}

struct
Param_info {
    int      seq;
    uint32_t id;
    //uint32_t index;
    //uint32_t next;
    Pod      param;
}

//auto
//SPA_PTROFF (T,BASE) (BASE* base, size_t offset) {
//    return cast (T*) (base + offset);
//}

auto
SPA_PTROFF (alias ptr_, alias offset_, alias type_) () {
    alias uintptr_t = void*;
    alias ptrdiff_t = size_t;
    return (cast (type_*) (cast (uintptr_t) (ptr_) + cast (ptrdiff_t) (offset_)));
}

auto
SPA_POD_BODY (spa_pod* pod) {
    return SPA_PTROFF!((pod), (spa_pod).sizeof, void) ();
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


