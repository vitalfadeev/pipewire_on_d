module client;

import importc;
import core_;
import spa;
import interfaces;
import klass;

class
Client {
    pw_client*    _this;
    Core           core;
    spa_hook       listener;
    //
    static
    Klass          klass = {
        type:          PW_TYPE_INTERFACE_Client,
        version_:      PW_VERSION_CLIENT,
        events:        &events,
        destroy_:      &destroy_,
        dump:          &dump,
        name_key:      PW_KEY_CLIENT_NAME.ptr,
    };
    __gshared
    pw_client_events events = {
        PW_VERSION_CLIENT_EVENTS,
        info  : cast (typeof (pw_client_events.info))  &info,
    };

    this (void* _this, Core core) {
        this._this = cast (pw_client*) _this;
        this.core = core;

        pw_client_add_listener (
            this._this,
            &listener,
            &events, 
            cast (void*) this
        );

        // pending++;
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    void 
    info (/*void* _this,*/ const pw_client_info *info)
    {
        //printf ("client: id:%u\n", info.id);
        //printf ("\tprops:\n");

        //foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
            //printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    void 
    destroy_ (Object_* o) {
        if (o.info) {
            pw_client_info_free (cast (pw_client_info*) o.info);
            o.info = null;
        }
    }

    void 
    dump (Object_* o) {
        //
    }
}


