module metadata;

import importc;
import core_;
import interfaces;
import klass;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;

class
Metadata : Pw_object {
    pw_metadata* _this () { return cast (pw_metadata*) proxy; }  // alias to proxy
    //
    static
    enum klass_type     = PW_TYPE_INTERFACE_Metadata;
    enum klass_version_ = PW_VERSION_METADATA;
    enum klass_events   = &events;
    enum klass_name_key = PW_KEY_METADATA_NAME.ptr;
    __gshared
    pw_metadata_events events = {
        PW_VERSION_METADATA_EVENTS,
        property: cast (typeof (pw_metadata_events.property))  &property,
    };
    

    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
    }

    ~this () {
        if (info) {
            //pw_metadata_info_free (cast (pw_metadata_info*) info);
            info = null;
        }
    }

    extern (C)
    int 
    property (/*void* _this, */uint32_t subject, const char* key, const char* type, const char* value) {
        return 0;
    }
    //void 
    //info_event (/*void* _this, */const pw_metadata_info* _info) {
    //    printf ("metadata: id: %u\n", _info.id);
    //    printf ("\tparams: %u\n",   _info.n_params);

    //    const spa_param_info* ps = _info.params;
    //    uint32_t              n  = _info.n_params;

    //    for (auto i = 0; i < n; i++) {
    //        writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);

    //        if (!SPA_FLAG_IS_SET (ps[i].flags, SPA_PARAM_INFO_READ)) continue;

    //        auto seq = 0;
    //        pw_metadata_enum_params (_this, seq, ps[i].id, 0, 0, null);
    //        core.sync ();
    //    }

    //    //with (cast (Ctx) ctx)
    //    //pw_main_loop_quit (loop);
    //}

    //extern (C)
    //void 
    //param_event (/*void* _this, */int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
    //    printf ("metadata param: id:%u\n", id);
    //    writefln ("  %s", cast (spa_param_type) id);

    //    if (param is null) goto done;

    //    done:
    //}

    override
    void 
    dump () {
        //
    }
}
