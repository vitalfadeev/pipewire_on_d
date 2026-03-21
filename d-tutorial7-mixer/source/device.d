module device;

import importc;
import core_;
import interfaces;
import klass;
import spa;
import set_volume_mute : Volume, NODE_FLAG_SINK, NODE_FLAG_SOURCE;
import set_volume_mute : NODE_FLAG_DEVICE_VOLUME, NODE_FLAG_DEVICE_MUTE;
import set_volume_mute : volume_from_linear;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;

class
Device : Pw_object {
    pw_device*    _this () { return cast (pw_device*) proxy; }  // alias to proxy
    //
    static
    enum klass_type     = PW_TYPE_INTERFACE_Device;
    enum klass_version_ = PW_VERSION_DEVICE;
    enum klass_events   = &events;
    enum klass_name_key = PW_KEY_DEVICE_NAME.ptr;
    __gshared
    pw_device_events events = {
        PW_VERSION_DEVICE_EVENTS,
        info  : cast (typeof (pw_device_events.info))  &info_event,
        param : cast (typeof (pw_device_events.param)) &param_event,
    };
    //
    uint32_t active_route_output;
    uint32_t active_route_input;
    uint32_t flags;
    float    volume;
    bool     mute;
    Volume   channel_volume;


    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
    }

    ~this () {
        if (info) {
            pw_device_info_free (cast (pw_device_info*) info);
            info = null;
        }
    }

    extern (C)
    void 
    info_event (/*void* _this, */const pw_device_info* info) {
        uint32_t n;

        if (info.change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
            for (n = 0; n < info.n_params; n++) {
                if (!(info.params[n].flags & SPA_PARAM_INFO_READ))
                    continue;

                switch (info.params[n].id) {
                            case SPA_PARAM_Route:
                                    pw_device_enum_params (cast (pw_device*) proxy,
                                            0, info.params[n].id, 0, -1, null);
                                    break;
                            default:
                                    break;
                            }
                    }

        }
        core.sync ();
    }

    extern (C)
    void 
    param_event (/*void* _this, */int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        switch (id) {
            case SPA_PARAM_Route:
            {
                uint32_t      idx;
                uint32_t      device;
                spa_direction direction;
                spa_pod*      props;

                if (spa_pod_parse_object (param,
                        SPA_TYPE_OBJECT_ParamRoute, null,
                        SPA_PARAM_ROUTE_index,      SPA_POD_Int(&idx),
                        SPA_PARAM_ROUTE_direction,  SPA_POD_Id(&direction),
                        SPA_PARAM_ROUTE_device,     SPA_POD_Int(&device),
                        SPA_PARAM_ROUTE_props,      SPA_POD_OPT_Pod(&props)) < 0) 
                {
                    //pw_log_warn("device %d: can't parse route", g.id);
                    return;
                }
                if (direction == SPA_DIRECTION_OUTPUT)
                    active_route_output = idx;
                else
                    active_route_input = idx;

                //pw_log_debug("device %d: active %s route %d", g.id,
                //        direction == SPA_DIRECTION_OUTPUT ? "output" : "input",
                //        idx);

                auto node = core.registry.find_node_for_route (id, device);
                if (props && node)
                    parse_props (props, true);
                break;
            }
            default:
                break;
        }
    }

    void 
    parse_props (const (spa_pod)* param, bool device) {
        foreach (spa_pod_prop* prop; Pod_object_foreach (param)) {
            switch (prop.key) {
                case SPA_PROP_volume:
                    if (spa_pod_get_float (&prop.value, &volume) < 0)
                        continue;
                    //pw_log_debug ("update node %d volume", id);
                    spa.SPA_FLAG_UPDATE (flags, NODE_FLAG_DEVICE_VOLUME, device);
                    break;

                case SPA_PROP_mute:
                    if (spa_pod_get_bool (&prop.value, &mute) < 0)
                        continue;
                    spa.SPA_FLAG_UPDATE (flags, NODE_FLAG_DEVICE_MUTE, device);
                    //pw_log_debug ("update node %d mute", g.id);
                    break;

                case SPA_PROP_channelVolumes: {
                    float[SPA_AUDIO_MAX_CHANNELS] volumes;
                    uint32_t n_volumes, i;

                    n_volumes = spa_pod_copy_array (&prop.value, SPA_TYPE_Float,
                            volumes.ptr, SPA_AUDIO_MAX_CHANNELS);

                    channel_volume.channels = n_volumes;
                    for (i = 0; i < n_volumes; i++)
                        channel_volume.values[i] =
                            volume_from_linear (volumes[i], core.registry.volume_method);

                    spa.SPA_FLAG_UPDATE (flags, NODE_FLAG_DEVICE_VOLUME, device);
                    //pw_log_debug("update node %d channelVolumes", g.id);
                    break;
                }

                default:
                    break;
            }
        }
    }

    override
    void 
    dump () {
        //
    }
}
