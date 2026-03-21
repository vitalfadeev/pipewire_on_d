module spa;

import importc;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import core.stdc.stdarg;
import std.conv : to;
import std.string : fromStringz;
import std.format : format;
import std.traits;


auto
spa_pod_parse_object (POD,TYPE,ID,ARGS...) (POD pod,TYPE type,ID id, ARGS args) {
    return __spa_pod_parse_object (pod,type,id,args);
}


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
        mixin (_Pod_as_string!"bool");
        mixin (_Pod_as_string!"int");
        mixin (_Pod_as_string!"long");
        mixin (_Pod_as_string!"float");
        mixin (_Pod_as_string!"double");

        mixin (Object_as_string!SPA_TYPE_OBJECT_PropInfo);
        mixin (Object_as_string!SPA_TYPE_OBJECT_Props);
        mixin (Object_as_string!SPA_TYPE_OBJECT_Format);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamBuffers);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamMeta);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamIO);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamProfile);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamPortConfig);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamRoute);
        mixin (Object_as_string!SPA_TYPE_OBJECT_Profiler);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamLatency);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamProcessLatency);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamTag);
        mixin (Object_as_string!SPA_TYPE_OBJECT_PeerParam);
        mixin (Object_as_string!SPA_TYPE_OBJECT_ParamDict);

        switch (type) with (spa_pod_type) {
            case Id     : return (cast (spa_pod_id) _this).value.to!string;
            case String : return fromStringz (cast (char*) SPA_POD_BODY (&_this)).to!string;
            case Choice : 
                // n_vals
                // choice
                uint32_t n_vals;
                uint32_t choice;
                spa_pod* child;
                child = spa_pod_get_values (&_this, &n_vals, &choice);
                return Pod_as_string (child);

            case Struct : 
                string s;
                s ~= "[";
                foreach (spa_pod* pod; Pod_struct_foreach (&_this) ) {
                    if (s.length > 1) s ~= ", ";
                    s ~= Pod_as_string (pod);
                }
                s ~= "]";
                return s;

            case Array : 
                string s;
                s ~= "[";
                foreach (spa_pod* pod; Pod_array_foreach (&_this)) {
                    if (s.length > 1) s ~= ", ";
                    s ~= Pod_as_string (pod);
                }
                s ~= "]";
                return s;

            default:
        }
        
        return "? "~_this.type.to!string;
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

auto
Pod_object_foreach (spa_pod* pod) {
    return (cast (Pod*) pod).object_foreach;
}

auto
Pod_struct_foreach (spa_pod* pod) {
    return (cast (Pod*) pod).struct_foreach;
}

auto
Pod_array_foreach (spa_pod* pod) {
    return (cast (Pod*) pod).array_foreach;
}

string 
Pod_as_string (spa_pod* pod) {
    return (cast (Pod*) pod).as_string;
}

template
Object_as_string (uint32_t SPA_TYPE_OBJECT_) {  // SPA_TYPE_OBJECT_PropInfo
    enum Object_as_string = format!"
        if (spa_pod_is_object_type (&_this, %d))
            return _Object_as_string (&this, %d);
    " 
    (SPA_TYPE_OBJECT_, SPA_TYPE_OBJECT_);
}
auto
_Object_as_string (Pod* pod, uint32_t SPA_TYPE_OBJECT_) {  // SPA_TYPE_OBJECT_PropInfo
    string s = "[\n";
    foreach (spa_pod_prop* prop; pod.object_foreach) {
        s ~= "  " ~ prop.key.to!string ~ ": "~ (Pod_as_string (&prop.value)) ~ ",\n";
    }
    s ~= "]\n";
    return s;
}

template
_Pod_as_string (string type) {
    enum _Pod_as_string = format!"
        if (spa_pod_is_%s (&_this)) {
            %s _value;
            spa_pod_get_%s (&_this, &_value); 
            return _value.to!string;
        }
    "
    (type, type, type);
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
auto
Spa_list_for_each (T) (spa_list* list) {
    return (cast (Spa_list!T*) list).for_each_safe;
}

auto
Spa_list_for_each_safe (T) (spa_list* list) {
    //return (cast (Spa_list!T*) list).for_each_safe;
    return (cast (Spa_list!T*) list).for_each_safe;
}

struct
Spa_list {
    enum string member="link";
    spa_list* _this;     // head // next: Struct_param* with spa_list member
    alias _this this;    //         prev: Struct_param* with spa_list member

    //@disable this ();

    import std.traits : ParameterTypeTuple;  // introspection template
    import std.traits : PointerTarget;

    int 
    opApply (Dg) (scope Dg dg)
        if (ParameterTypeTuple!Dg.length == 1) // foreach with 1 parameters
    {
        alias CONTAINER_PTR = ParameterTypeTuple!Dg[0];  // 1st foreach-parameter
        alias CONTAINER     = PointerTarget!CONTAINER_PTR;
        static assert (__traits (hasMember, CONTAINER, member), "expect field '"~member~"` in type '"~CONTAINER.stringof~"'");

        spa_list* tmp = this.next;
        for (CONTAINER_PTR front = cast (CONTAINER_PTR) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof"));
            tmp !is _this;
            tmp   = __traits (getMember, front, member).next,
            front = cast (CONTAINER_PTR) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof")))
        {
            if (auto res = dg (front))
                return 1;
        }

        return 0;
    }

    //auto
    //for_each_safe () {
    //    return Range!(CONTAINER,member) (_this);
    //}

    //struct
    //Range (CONTAINER, string member) {
    //    spa_list*  head;
    //    CONTAINER* front;
    //    spa_list*  tmp;
    //    bool       empty ()    { return  tmp is head; }
    //    void       popFront () { 
    //        tmp   = __traits (getMember, front, member).next; 
    //        front = cast (CONTAINER*) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof")); 
    //    }

    //    this (spa_list* head)  {
    //        this.head  = head;
    //        this.tmp   = head.next; 
    //        this.front = cast (CONTAINER*) ((cast (void*) tmp) - mixin ("CONTAINER."~member~".offsetof")); 
    //    }
    //}
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


struct
Param_info {
    int      seq;
    uint32_t id;
    //uint32_t index;
    //uint32_t next;
    Pod      param;
}

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


enum
X {
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
}
static foreach (e; EnumMembers!X) {
    pragma (msg, e.stringof, "\t", cast (uint) e);
}

auto
SPA_FLAG_IS_SET (FIELD, FLAG) (FIELD field, FLAG flag) {
    return SPA_FLAG_MASK (field, flag, flag);
}

auto
SPA_FLAG_MASK (FIELD, MASK, FLAG) (FIELD field, MASK mask, FLAG flag) {
    return (((field) & (mask)) == (flag));
}
