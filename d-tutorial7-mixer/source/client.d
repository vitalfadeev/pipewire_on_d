module client;

import importc;
import core_;
import spa;
import interfaces;

class
Client {
    pw_client* _this;
    Core_       core_;
    spa_hook    client_listener;

    this (void* _this, Core_ core_) {
        this._this = cast (pw_client*) _this;
        this.core_ = core_;

        pw_client_add_listener (
            this._this,
            &client_listener,
            &client_events, 
            cast (void*) this
        );

        // pending++;
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    client_info (void* data, const pw_client_info *info)
    {
        //printf ("client: id:%u\n", info.id);
        //printf ("\tprops:\n");

        //foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
            //printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        //with (cast (Ctx) ctx)
        //pw_main_loop_quit (loop);
    }

    static 
    pw_client_events client_events = {
        PW_VERSION_CLIENT_EVENTS,
        info: &client_info,
    };
}


