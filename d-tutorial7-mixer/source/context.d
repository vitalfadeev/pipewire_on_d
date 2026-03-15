module context;

import importc;
import core_;

class
Context {
    pw_context*  _this;
    pw_main_loop* loop;

    this () {
        loop  = pw_main_loop_new (null /* properties */ );
        _this = pw_context_new (
            pw_main_loop_get_loop (loop),
            null /* properties */ ,
            0 /* user_data size */ 
        );
    }

    ~this () {
        pw_main_loop_destroy (loop);
        pw_context_destroy (_this);
    }

    Core_
    connect () {
        return new Core_ (
            pw_context_connect (
                _this, 
                null /* properties */ ,
                0 /* user_data size */ 
            ),
            this
        );
    }

    void
    main_loop_run () {
        pw_main_loop_run (loop);
    }
}
