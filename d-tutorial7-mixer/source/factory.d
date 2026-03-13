import importc;
import ctx;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Factory {
    pw_factory* _this;
    spa_hook    factory_listener;

    this (pw_factory* _this, Ctx ctx) {
        this._this = _this;

        pw_factory_add_listener (
            _this,
            &factory_listener,
            &factory_events, 
            cast (void*) ctx
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    factory_info (void *ctx, const pw_factory_info *info)
    {
        printf ("factory: id:%u\n", info.id);
        printf ("\ttype: :%s\n", info.type);

        with (cast (Ctx) ctx)
        pw_main_loop_quit (loop);
    }

    static 
    pw_factory_events factory_events = {
        PW_VERSION_FACTORY_EVENTS,
        info: &factory_info,
    };
}
