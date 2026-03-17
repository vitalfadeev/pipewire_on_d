module spa;

import importc;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import core.stdc.stdarg;
import spa_list;


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