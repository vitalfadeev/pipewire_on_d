import importc;
import context;
import std.stdio : writeln;



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

        // print nodex
        writeln ("Nodes: ", core.registry.nodes.length);
        foreach (node; core.registry.nodes) {
            writeln ("  ", node.info.id, " ", node.info.n_params);
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
