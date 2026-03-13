import importc;
import ctx;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;

class
Node {
    pw_node* _this;
    spa_hook  node_listener;

    this (pw_node* _this, Ctx ctx) {
        this._this = _this;

        pw_node_add_listener (
            _this,
            &node_listener,
            &node_events, 
            cast (void*) ctx
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    node_info (void *ctx, const pw_node_info *info)
    {
        printf ("node: id:%u\n", info.id);

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
    pw_node_events node_events = {
        PW_VERSION_CLIENT_EVENTS,
        info: &node_info,
    };
}
