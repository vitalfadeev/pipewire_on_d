import importc;
import context;
import std.stdio : writeln;
import spa;
import std.stdio : writefln;


extern (C)
int main (int argc, char** argv) {
    pw_init (&argc, &argv);

    auto context = new Context ();

    with (context) {
        // connect
        // wait connect
        connect ();
        core.roundtrip ();

        // registry
        // wait registry
        core.get_registry ();
        core.roundtrip ();
        //core.main_loop_run ();

        // print nodex
        writeln ("Node s: ", core.registry.nodes.length);
        foreach (node; core.registry.nodes) {
            writefln ("%2d", node.id);

            // info: params_info
            //if (node.info !is null) {
            //    with (cast (pw_node_info*) node.info) {
            //        //auto name = __find_node_name (cast (spa_dict*) props);
            //        //printf ("node id,name: %u, %s\n", id,name);
            //        writeln ("  props:");
            //        foreach (item; spa_dict_for_each (props))  // spa_dict_item* item
            //            printf ("    %27s: \"%s\"\n", item.key, item.value);
            //    }
            //}

            // params
            //writeln ("  params:");
            //with (cast (pw_node_info*) node.info)
            //foreach (ref Param param; Node_info_params_foreach (n_params,params)) {
            //    writefln ("  param: %2d: %s", param.id, param.id);
            //}

            //with (node)
            //foreach (Param_info param_info; params) {
            //    writefln ("  %d: %s", param_info.id, param_info.param.as_string);
            //}

                //switch (id) with (spa_param_type) {
                //    case SPA_PARAM_Format:
                //        // SPA_PARAM_Format => SPA_TYPE_OBJECT_Format => spa_media_type
                //        foreach (prop; Pod_object_foreach!SPA_TYPE_OBJECT_Format (param)) {
                //            writefln ("\t\tkey: %25s: %s", prop.key, prop.value.as_string); 
                //        }
                //        break;
                //    case SPA_PARAM_PropInfo:
                //        // SPA_PARAM_PropInfo => SPA_TYPE_OBJECT_PropInfo => spa_prop_info[]
                //        foreach (prop; Pod_object_foreach!SPA_TYPE_OBJECT_PropInfo (param)) {
                //            writefln ("\t\tkey: %25s: %s", prop.key, prop.value.as_string); 
                //            // SPA_PROP_INFO_id
                //            // SPA_PROP_INFO_name
                //            // SPA_PROP_INFO_description
                //            // SPA_PROP_INFO_type
                //            // ...
                //        }
                //        break;

                //    case SPA_PARAM_Props:
                //        // SPA_PARAM_Props => SPA_TYPE_OBJECT_Props => spa_prop[]
                //        foreach (prop; Pod_object_foreach!SPA_TYPE_OBJECT_Props (param)) {
                //            writefln ("\t\tkey: %25s: %s", prop.key, prop.value.as_string); 
                //        }
                //        break;

                //    case SPA_PARAM_IO:
                //        // SPA_PARAM_IO => SPA_TYPE_OBJECT_ParamIO => spa_param_io[]
                //        foreach (prop; Pod_object_foreach!SPA_TYPE_OBJECT_ParamIO (param)) {
                //            writefln ("\t\tkey: %25s: %s", prop.key, prop.value.as_string); 
                //        }
                //        break;

                //    case SPA_PARAM_Tag:
                //        break;
                //    default:
                //}
        }
    }

    return 0;
}

// Audio
//   SPA Device
//     spa_device_event
//       SPA_EVENT_DEVICE_START     
//       SPA_EVENT_DEVICE_Object     
//       SPA_EVENT_DEVICE_Props 
//       https://docs.pipewire.org/group__spa__device.html#details
//       spa_device_emit (hooks,info, 0, i)
//       
//       SPA_API_DEVICE int spa_device_add_listener     (   struct spa_device *     object,
//         struct spa_hook *   listener,
//         const struct spa_device_events *    events,
//         void *  data )
//
//       SPA_API_DEVICE int spa_device_enum_params  (   struct spa_device *     object,
//         int     seq,
//         uint32_t    id,
//         uint32_t    index,
//         uint32_t    max,
//         const struct spa_pod *  filter )
//

// Core
//   methods
//     add_listener
//     hello
//     sync
//     pong
//     error
//     get_registry
//     create_object   //////////////////////////
//     destroy 
//   events
//     info
//     done
//     ping
//     error
//
// Registry
//   methods
//   events
//
// Client
//   PW_TYPE_INTERFACE_Client
//   events
//     info
//   methods
//         ...
//
// Device
//   methods
//     add_listener 
//     subscribe_params /////////////////////////////
//     enum_params 
//     set_param 
//   events
//      info
//      params
//
// Module
//   methods
//     add_listener 
//   events
//      info
//
