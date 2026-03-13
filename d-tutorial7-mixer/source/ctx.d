import importc;
import context;
import core_;
import registry;
import client;

class
Ctx {
    pw_main_loop* loop;
    Context       context;
    Core_         core;
    Registry      registry;
    Client        client;

    this () {
        loop     = pw_main_loop_new (null /* properties */ );
        context  = new Context (loop);
        core     = context.connect ();
        registry = core.get_registry (this);
    }

    void
    run () {
        pw_main_loop_run (loop);
    }

    ~this () {
        pw_main_loop_destroy (loop);
    }
}


