import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Factory {
    pw_factory* _this;
    Core        core;
    spa_hook     factory_listener;

    this (void* _this, Core core) {
        this._this = cast (pw_factory*) _this;
        this.core = core;

        pw_factory_add_listener (
            this._this,
            &factory_listener,
            &factory_events, 
            cast (void*) this
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    factory_info (void* data, const pw_factory_info *info)
    {
        //printf ("factory: id:%u\n", info.id);
        //printf ("\ttype: :%s\n", info.type);

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    static 
    pw_factory_events factory_events = {
        PW_VERSION_FACTORY_EVENTS,
        info: &factory_info,
    };
}
