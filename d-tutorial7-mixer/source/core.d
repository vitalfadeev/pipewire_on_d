module core_;

import importc;
import registry;
import context;
import std.stdio : writeln;

class
Core {
    pw_core*      _this;
    Context        context;
    Pendings       pendings;
    Registry       registry;

    this (pw_core* _this, Context context) {
        this._this   = _this;
        this.context = context;
    }

    Registry
    get_registry () {
        registry = new Registry (
            pw_core_get_registry (_this, PW_VERSION_REGISTRY, 0 /* user_data size */ ),
            this
        );
        return registry;
    }

    ~this () {
        pw_core_disconnect (_this);
    }

    extern (C)
    static void 
    on_coredone (void* _this, uint32_t id, int seq) {
        with (cast (Core) _this) {
            if (id == PW_ID_CORE) {
                pendings.remove (seq);

                if (pendings.all_done)
                    pw_main_loop_quit (context.loop);
            }
        }
    }

    static pw_core_events core_events = {
        PW_VERSION_CORE_EVENTS,
        done: &on_coredone,
    };

    void 
    roundtrip () {
        spa_hook core_listener;
        int err;

        pw_core_add_listener (_this, &core_listener, &core_events, cast (void*) this);

        add_pending ();

        if ((err = pw_main_loop_run (context.loop)) < 0)
            printf ("main_loop_run error:%d!\n", err);

        spa_hook_remove (&core_listener);
    }

    void
    add_pending () {
        auto seq = pendings.add ();
        auto _seq = pw_core_sync (_this, PW_ID_CORE, seq);
        pendings.update (seq,_seq);
    }

    void
    add_pending (int seq) {
        auto _seq = pw_core_sync (_this, PW_ID_CORE, seq);
        pendings.update (seq,_seq);
    }

    struct
    Pendings {
        int[int] s;  // int[seq]
        int      seq;

        bool
        all_done () {
            foreach (k,v; s) 
                if (v != 0)
                    return false;

            return true;
        }

        int  // seq
        add () {
            auto _seq = seq;
            s[seq] = 1;
            seq++;
            return _seq;
        }

        void
        remove (int seq) {
            s[seq] = 0;
        }

        void
        update (int old_seq, int new_seq) {
            s[old_seq] = 0;
            s[new_seq] = 1;
        }
    }
}
