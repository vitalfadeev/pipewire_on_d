module spa;

import importc;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import spa_list;

//static 
//void 
//print_props (proxy_data* data, const pw_client_info* info) {
//    printf ("\tprops:\n");

//    foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
//        printf ("\t\t%s: \"%s\"\n", item.key, item.value);
//}

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
//wp_core_find_object (WpCore* self, GEqualFunc func, gconstpointer data) {
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
//    GObject* p = wp_core_find_object (
//        core,
//        cast (GEqualFunc) find_plugin_func, 
//        GUINT_TO_POINTER (q)
//    );

//    return p;
//}
