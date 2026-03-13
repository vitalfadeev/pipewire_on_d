import importc;
import core_;

class
Context {
    pw_context* _this;

    this (pw_main_loop* loop) {
        _this = pw_context_new (
            pw_main_loop_get_loop (loop),
            null /* properties */ ,
            0 /* user_data size */ 
        );
    }

    ~this () {
        //pw_context_destroy (_this);
    }

    Core_
    connect () {
        return new Core_ (
            pw_context_connect (
                _this, 
                null /* properties */ ,
                0 /* user_data size */ 
            )
        );
    }
}
