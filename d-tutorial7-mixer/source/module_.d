module module_;

import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Module_ {
    pw_module* _this;
    Core       core;
    spa_hook    module_listener;

    this (void* _this, Core core) {
        this._this = cast (pw_module*) _this;
        this.core = core;

        pw_module_add_listener (
            this._this,
            &module_listener,
            &module_events, 
            cast (void*) this
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    module_info (void* data, const pw_module_info *info)
    {
        //printf ("module: id:%u\n", info.id);
        //printf ("\tilename: %s\n", info.filename);


        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    static 
    pw_module_events module_events = {
        PW_VERSION_MODULE_EVENTS,
        info: &module_info,
    };
}
