import importc;
import registry;
import ctx;

class
Core_ {
    pw_core* _this;

    this (pw_core* _this) {
        this._this = _this;
    }

    Registry
    get_registry (Ctx ctx) {
        return new Registry (
            pw_core_get_registry (
                _this, 
                PW_VERSION_REGISTRY,
                0 /* user_data size */ 
            ),
            ctx
        );
    }

    ~this () {
        pw_core_disconnect (_this);
    }
}
