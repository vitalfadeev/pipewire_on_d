import importc;
import context;
import spa;
import klass;
import std.stdio : writeln;
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

            foreach (Struct_param* p; Spa_list (&node.pending_list)) {
                if (p.param !is null)
                    writeln (p.id, ": ", (cast (Pod*) p.param).as_string);
            }
        }

        // set volume
        import set_volume_mute : set_volume_mute, Volume, NODE_FLAG_SOURCE, NODE_FLAG_SINK;
        import node : Node;

        char*  name = core.registry.default_source.ptr;
        Volume volume;
        int    mute;
        Node   node;
        Node   sink;
        if (core.registry.default_source[0] == '\0')
          node = core.registry.find_best_node (NODE_FLAG_SOURCE);
        if (core.registry.default_sink[0] == '\0')
          sink = core.registry.find_best_node (NODE_FLAG_SINK);
        if (node !is null)
          printf ("DEFAULT_SOURCE : %s\n", node.name);
        if (sink !is null)
          printf ("DEFAULT_SINK   : %s\n", sink.name);
        //set_volume_mute (core.registry, name, &volume, &mute);
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

// pw-cli ls Device
// ...
//id 48, type PipeWire:Interface:Device/3
//    object.serial = "48"
//    factory.id = "15"
//    client.id = "47"
//    device.api = "alsa"
//    device.description = "Встроенное аудио"
//    device.name = "alsa_card.pci-0000_00_1b.0"
//    device.nick = "HDA Intel PCH"
//    media.class = "Audio/Device"      <--------------------------------
//    object.path = "alsa:acp:PCH"
// ...

// pw-cli e 48 Route
// ...
//Prop: key Spa:Pod:Object:Param:Route:props (10), flags 00000000
//  Object: size 200, type Spa:Pod:Object:Param:Props (262146), id Spa:Enum:ParamId:Route (13)
//    Prop: key Spa:Pod:Object:Param:Props:mute (65540), flags 00000002
//      Bool false
//    Prop: key Spa:Pod:Object:Param:Props:channelVolumes (65544), flags 00000002
//      Array: child.size 4, child.type Spa:Float
//        Float 0,752141  <-----------------------------------------------
//        Float 0,713230
// ...
//Object: size 848, type Spa:Pod:Object:Param:Route (262153), id Spa:Enum:ParamId:Route (13)
//    Prop: key Spa:Pod:Object:Param:Route:index (1), flags 00000000
//      Int 2  <----------------------------------------------------------
//
// ...
//Prop: key Spa:Pod:Object:Param:Route:device (3), flags 00000000
//  Int 4      <----------------------------------------------------------

// set volume
// pw-cli s 48 Route \
//  '{ index:  <route-index>, 
//     device: <card-profile-device>, 
//     props: { mute: false, channelVolumes: [ 0.5, 0.5 ] }, save: true 
//   }'

// pw-cli s 48 Route '{ index: 2, device: 4,  props: { mute: false, channelVolumes: [ 0.1, 0.1 ] }, save: true }'

// pw-cli e <node-id> Props
// pw-cli s <node-id> Props '{ mute: false, channelVolumes: [ 0.3, 0.3 ] }'

enum doc = "
  Pw_graph              Pw_graph
    Node                  Node
   Source                 Sink
  |      |              |      |
port     |            port     |
port     |            port     |
port     |            port     |
  |     port - link - port     |
  |      |              |      |
   ------                ------
";

enum doc2 = "
           ALSA
           Sink
         |      |
front-left      |
front-right     |
         |      |
          ------

           ALSA
          Source
         |      |
         |     front-left
         |     front-right
         |      |
          ------
";

enum doc3 = "
  Client - UNIX socket - Server
";

enum doc4 = "
  Node
";

enum doc5 = "
Session manager
  Object
    parameters    - Sample rates, Channel count, Sample format, Available monitor ports
    properties    - attached from Modules. object type => properties
    methods
    events
    permissions   - object_ID and 4 flags: Read, Write, eXecute, Metadata, Link
      Read     : the object can be seen and events can be received;
      Write    : the object can be modified, usually through methods (which requires the execute flag)
      eXecute  : methods can be called;
      Metadata : metadata can be set on the object.
      Link     : any link can be made even to a port that is not visible by the owner of the port.
";


enum doc6 = "
Object types
  Core
  Client
  Module
  Node
    process
    (dsp port or passthrough port)
  Port
    dsp: one port for channel, 32-bit floating point. 
    passthrough: one port for multichannel data
  Link
    passive / active
  Device
    id
    // profile
  Factory
  Context
    // create context by reading config

  Pw_object
    add_listener
";


