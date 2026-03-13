import importc;
import ctx;
import interfaces;

class
Client {
    pw_client* _this;
    spa_hook   client_listener;

    this (pw_client* _this, Ctx ctx) {
        this._this = _this;

        pw_client_add_listener (
            _this,
            &client_listener,
            &client_events, 
            cast (void*) ctx
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    extern (C)
    static void 
    client_info (void *ctx, const pw_client_info *info)
    {
        printf ("client: id:%u\n", info.id);
        printf ("\tprops:\n");

        foreach (item; spa_dict_for_each (info.props))  // spa_dict_item* item
            printf ("\t\t%s: \"%s\"\n", item.key, item.value);

        with (cast (Ctx) ctx)
        pw_main_loop_quit (loop);
    }

    static 
    pw_client_events client_events = {
        PW_VERSION_CLIENT_EVENTS,
        info: &client_info,
    };
}


auto removeConst (T) (T value) {
    static if (is (T == const U, U)) {
        return cast (U) value;
    } else {
        return value;
    }
}

auto
spa_dict_for_each (DICT) (DICT dict) {
    auto  items = removeConst (dict.items);
    alias ITEMS = typeof (items);
    return _spa_dict_for_each!(DICT,ITEMS) (dict,items);
}

struct
_spa_dict_for_each (DICT,ITEMS) {
    DICT  dict;
    ITEMS front;
    bool  empty () { return front >= &dict.items[dict.n_items]; }
    void  popFront () { front++; }

    this (DICT dict, ITEMS items) {
        this.dict  = dict;
        this.front = items;
    }
}
