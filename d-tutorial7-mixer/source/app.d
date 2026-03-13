import importc;
import ctx;



extern (C)
int main (int argc, char** argv) {
    pw_init (&argc, &argv);

    auto ctx = new Ctx ();
    ctx.run ();

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
//