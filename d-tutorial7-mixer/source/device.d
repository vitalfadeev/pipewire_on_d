module device;

import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;

class
Device {
    pw_device* _this;
    Core       core;
    spa_hook    device_listener;
    string[]     params;

    this (void* _this, Core core) {
        this._this = cast (pw_device*) _this;
        this.core = core;

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
    device_info (void* _device, const pw_device_info* _info)
    {
        with (cast (Device) _device) {
            printf ("device: id: %u\n", _info.id);
            printf ("\tparams: %u\n",   _info.n_params);

            const spa_param_info* ps = _info.params;
            uint32_t              n  = _info.n_params;

            for (auto i = 0; i < n; i++) {
                writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);
                params ~= (cast (spa_param_type) ps[i].id).to!string;

                if (!SPA_FLAG_IS_SET (ps[i].flags, SPA_PARAM_INFO_READ)) continue;

                auto seq = core.pendings.add ();
                pw_device_enum_params (_this, seq, ps[i].id, 0, 0, null);
                core.add_pending (seq);
            }

            //with (cast (Ctx) ctx)
            //pw_main_loop_quit (loop);
        }
    }

    extern (C)
    static void 
    device_param (void* _device, int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param)
    {
        with (cast (Device) _device) {
            printf ("device param: id:%u\n", id);
            writefln ("  %s", cast (spa_param_type) id);

            if (param is null) goto done;
        }

        done:
    }


    static 
    pw_device_events device_events = {
        PW_VERSION_DEVICE_EVENTS,
        info  : &device_info,
        param : &device_param,
    };
}
