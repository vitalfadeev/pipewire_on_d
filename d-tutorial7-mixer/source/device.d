module device;

import importc;
import core_;
import interfaces;
import klass;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;

class
Device : Pw_object {
    pw_device*    _this () { return cast (pw_device*) proxy; }  // alias to proxy
    Core           core;
    string[]       params;
    spa_hook       listener;
    //
    static
    Klass          klass = {
        type:          PW_TYPE_INTERFACE_Device,
        version_:      PW_VERSION_DEVICE,
        events:        &events,
        name_key:      PW_KEY_DEVICE_NAME.ptr,
    };
    __gshared
    pw_device_events events = {
        PW_VERSION_DEVICE_EVENTS,
        info  : cast (typeof (pw_device_events.info))  &info_event,
        param : cast (typeof (pw_device_events.param)) &param_event,
    };
    

    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
    }

    ~this () {
        if (info) {
            pw_device_info_free (cast (pw_device_info*) info);
            info = null;
        }
    }

    extern (C)
    void 
    info_event (/*void* _this, */const pw_device_info* _info) {
        printf ("device: id: %u\n", _info.id);
        printf ("\tparams: %u\n",   _info.n_params);

        const spa_param_info* ps = _info.params;
        uint32_t              n  = _info.n_params;

        for (auto i = 0; i < n; i++) {
            writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);
            params ~= (cast (spa_param_type) ps[i].id).to!string;

            if (!SPA_FLAG_IS_SET (ps[i].flags, SPA_PARAM_INFO_READ)) continue;

            auto seq = 0;
            pw_device_enum_params (_this, seq, ps[i].id, 0, 0, null);
            core.sync ();
        }

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    extern (C)
    void 
    param_event (/*void* _this, */int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        printf ("device param: id:%u\n", id);
        writefln ("  %s", cast (spa_param_type) id);

        if (param is null) goto done;

        done:
    }

    override
    void 
    dump () {
        //
    }
}
