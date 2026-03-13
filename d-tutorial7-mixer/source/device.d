import importc;
import ctx;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Device {
    pw_device* _this;
    spa_hook   device_listener;

    this (pw_device* _this, Ctx ctx) {
        this._this = _this;

        pw_device_add_listener (
            _this,
            &device_listener,
            &device_events, 
            cast (void*) ctx
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    device_info (void *ctx, const pw_device_info *info)
    {
        printf ("device: id:%u\n", info.id);
        printf ("\tparams:\n");

        const spa_param_info* ps = info.params;
        uint32_t              n  = info.n_params;

        for (auto i = 0; i < n; i++) {
            writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);
        }

        with (cast (Ctx) ctx)
        pw_main_loop_quit (loop);
    }

    static 
    pw_device_events device_events = {
        PW_VERSION_DEVICE_EVENTS,
        info: &device_info,
    };
}
