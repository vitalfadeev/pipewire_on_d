module device;

import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Device {
    pw_device* _this;
    Core_       core_;
    spa_hook    device_listener;

    this (void* _this, Core_ core_) {
        this._this = cast (pw_device*) _this;
        this.core_ = core_;

        pw_device_add_listener (
            this._this,
            &device_listener,
            &device_events, 
            cast (void*) this
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    device_info (void* data, const pw_device_info *info)
    {
        //printf ("device: id:%u\n", info.id);
        //printf ("\tparams:\n");

        const spa_param_info* ps = info.params;
        uint32_t              n  = info.n_params;

        for (auto i = 0; i < n; i++) {
            //writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);
        }

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    extern (C)
    static void 
    event_param (void* _data, int seq, uint32_t id,
            uint32_t index, uint32_t next, spa_pod* param)
    {
        //proxy_data* data = _data;
        //param* p;

        ///* remove all params with the same id and older seq */
        //remove_params (data, id, seq);

        ///* add new param */
        //p = malloc (param.sizeof + SPA_POD_SIZE (param));
        //if (p is null) {
        //    pw_log_error ("can't add param: %m");
        //    return;
        //}

        //p.id = id;
        //p.seq = seq;
        //p.param = SPA_PTROFF (p, param.sizeof, spa_pod);
        //p.changed = true;
        //memcpy (p.param, param, SPA_POD_SIZE (param));
        //spa_list_append (&data.param_list, &p.link);
    }


    static 
    pw_device_events device_events = {
        PW_VERSION_DEVICE_EVENTS,
        info: &device_info,
        //param: &device_param,
    };
}
