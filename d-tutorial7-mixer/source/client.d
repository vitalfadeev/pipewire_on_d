import importc;
import ctx;

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

enum PW_TYPE_INFO_BASE           = "PipeWire:";
enum PW_TYPE_INFO_Object         = PW_TYPE_INFO_BASE ~ "Object";
enum PW_TYPE_INFO_OBJECT_BASE    = PW_TYPE_INFO_Object ~ ":";
enum PW_TYPE_INFO_Interface      = PW_TYPE_INFO_BASE ~ "Interface";
enum PW_TYPE_INFO_INTERFACE_BASE = PW_TYPE_INFO_Interface ~ ":";
enum PW_TYPE_INTERFACE_Client    = PW_TYPE_INFO_INTERFACE_BASE ~ "Client";


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
