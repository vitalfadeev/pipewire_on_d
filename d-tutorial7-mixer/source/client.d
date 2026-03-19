module client;

import importc;
import core_;
import spa;
import interfaces;
import klass;

class
Client : Pw_object {
    pw_client*    _this () { return cast (pw_client*) proxy; }  // alias to proxy
    //
    static
    Klass          klass = {
        type:          PW_TYPE_INTERFACE_Client,
        version_:      PW_VERSION_CLIENT,
        events:        &events,
        name_key:      PW_KEY_CLIENT_NAME.ptr,
    };
    __gshared
    pw_client_events events = {
        PW_VERSION_CLIENT_EVENTS,
        info  : cast (typeof (pw_client_events.info))  &info_event,
    };

    this (Core core, uint32_t id, uint32_t permissions, const char*  type, uint32_t version_, const spa_dict* props)  {
        super (core, id, permissions, type, version_, props);
        _klass = &klass;
    }

    ~this () {
        if (info) {
            pw_client_info_free (cast (pw_client_info*) info);
            info = null;
        }
    }

    extern (C)
    void 
    info_event (/*void* _this,*/ const pw_client_info *info)
    {
        //printf ("client: id:%u\n", info.id);
        //printf ("\tprops:\n");

        //foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
            //printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    override
    void 
    dump () {
        //
    }
}


