import importc;
import core_;
import interfaces;
import std.stdio : writeln;
import std.stdio : writefln;
import std.conv : to;

class
Node {
    pw_node*    _this;
    Core_        core_;
    spa_hook     node_listener;
    pw_node_info info;
    string[]     params;

    this (void* _this, Core_ core_) {
        this._this = cast (pw_node*) _this;
        this.core_ = core_;

        pw_node_add_listener (
            this._this,
            &node_listener,
            &node_events, 
            cast (void*) this
        );        
    }

    ~this () {
        pw_proxy_destroy (cast (pw_proxy *) _this);        
    }

    //int 
    //enum_params (void* object, int seq, uint32_t id, uint32_t start, uint32_t num, const spa_pod* filter) {
    //    //auto res = 
    //    //    spa_node_enum_params (_this, 0, id, start, 1, filter);
    //}

    extern (C)
    static void 
    node_info (void* _node, const pw_node_info *_info) {
        with (cast (Node) _node) {
            //printf ("node: id:%u\n", info.id);
            info = cast (pw_node_info) (*_info);

            //printf ("\tparams:\n");

            params.length = 0;
            const spa_param_info* ps = _info.params;
            uint32_t              n  = _info.n_params;

            for (auto i = 0; i < n; i++) {
                //writefln ("\t\t%2d: %s", ps[i].id, cast (spa_param_type) ps[i].id);

                params ~= (cast (spa_param_type) ps[i].id).to!string;

                if (info.params[i].user == 0) continue;
                if (!SPA_FLAG_IS_SET (ps[i].flags, SPA_PARAM_INFO_READ)) continue;

                pw_node_enum_params (_this, 0, ps[i].id, 0, 0, null);

                //ps[i].user = 0;
                core_.add_pending ();
            }
            //add_pending (data);

            //with (cast (Ctx) ctx)
            //pw_main_loop_quit (loop);
        }
    }

    extern (C)
    static void
    node_param (void* _node, int seq, uint32_t id, uint32_t index, uint32_t next, spa_pod* param) {
        with (cast (Node) _node) {
            //printf ("\t\tparam: id:%u\n", id);

            if (param is null) goto done;

            switch (id) {
                case SPA_PARAM_Format:
                    uint32_t media_type, media_subtype;
                    if (_spa_format_parse (param, &media_type, &media_subtype) < 0) goto done;
                    switch (media_type) {
                        case SPA_MEDIA_TYPE_audio: break;
                        case SPA_MEDIA_TYPE_video: break;
                        case SPA_MEDIA_TYPE_application: break;
                        default:
                    }
                    break;
                default:
            }

            done:
        }
    }

    static 
    pw_node_events node_events = {
        PW_VERSION_NODE_EVENTS,
        info:  &node_info,
        param: &node_param
    };
}
