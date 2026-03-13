import importc;
import ctx;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Module_ {
    pw_module* _this;
    spa_hook   module_listener;

    this (pw_module* _this, Ctx ctx) {
        this._this = _this;

        pw_module_add_listener (
            _this,
            &module_listener,
            &module_events, 
            cast (void*) ctx
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    module_info (void *ctx, const pw_module_info *info)
    {
        printf ("module: id:%u\n", info.id);
        printf ("\tilename: %s\n", info.filename);


        with (cast (Ctx) ctx)
        pw_main_loop_quit (loop);
    }

    static 
    pw_module_events module_events = {
        PW_VERSION_CLIENT_EVENTS,
        info: &module_info,
    };
}
