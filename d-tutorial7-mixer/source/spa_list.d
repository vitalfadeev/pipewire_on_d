module spa_list;

// DList
struct 
spa_list {
    spa_list* next;
    spa_list* prev;

    void
    init_ () {  // spa_list_init
        this.next = &this;
        this.prev = &this;
    }

    int 
    is_initialized () {  // spa_list_is_initialized
        return !!prev;
    }

    bool 
    is_empty () {  // spa_list_is_empty
        return (next == &this);
    }

    void
    insert (spa_list* elem) {  // spa_list_insert
        elem.prev = &this;
        elem.next = this.next;
        this.next = elem;
        elem.next.prev = elem;
    }

    void 
    insert_list (spa_list* other) {  // spa_list_insert_list
        if (other.is_empty) return;
        other.next.prev = &this;
        other.prev.next = this.next;
        this.next.prev = other.prev;
        this.next = other.next;
    }

    void
    remove (spa_list* elem) {  // spa_list_remove
        elem.prev.next = elem.next;
        elem.next.prev = elem.prev;
    }

    void
    append (spa_list* item) {  // spa_list_append
        this.prev.insert (item);
    }

    void
    prepend (spa_list* item) {  // spa_list_prepend
        this.insert (item);
    }
}

auto
SPA_CONTAINER_OF (T,string m,P) (P p) {
    // return ((t*) ((uintptr_t)(p) - offsetof (t,m)));
    return cast (T*) ((cast (size_t) p) - __traits(getMember,T,m).offsetof);
}

auto
first (TYPE,string member,HEAD) (HEAD head) {  // spa_list_first
    return SPA_CONTAINER_OF!(TYPE,member) (mixin("head.next"));
}

template
last (alias head, alias type, string member) {  // spa_list_last
    enum last = SPA_CONTAINER_OF!((head).prev, type, member);
}

auto
next (TYPE,string member,POS) (POS pos) {  // spa_list_next
    return SPA_CONTAINER_OF!(TYPE,member) (mixin("pos."~member~".next"));
}

template
prev (alias pos, string member) {  // spa_list_prev
    enum prev = SPA_CONTAINER_OF!(__traits(getMember,(pos),member).prev, typeof(*(pos)), member);
}

auto
is_end (string member,POS,HEAD) (POS pos, HEAD head) {  // spa_list_is_end
    return (&__traits(getMember,(pos),member) == (head));
}

auto
consume (POS,HEAD,MEMBER) (POS pos, HEAD head, MEMBER member) {  // spa_list_consume
    struct 
    _range (POS,HEAD,MEMBER) {
        POS  front;
        bool empty () { return is_empty (head); }
        void popFront () {
            front = first!(head, typeof (*(pos)), member);
        }

        this (POS pos, HEAD head, MEMBER member) {
            front = first!(head, typeof (*(pos)), member);
        }
    }

    return _range!(POS,HEAD,MEMBER) (pos,head,member);

    //for ((pos) = first (head, typeof (*(pos)), member);
    //     !is_empty (head);
    //     (pos) = first (head, typeof (*(pos)), member)) 
    //{
    //    //
    //}
}

template
for_each_next (POS,HEAD,CURR, string member) {  // spa_list_for_each_next
    struct 
    _range (POS,HEAD,CURR) {
        HEAD head;
        POS* front;
        bool empty () { return is_end!member (front, head); }
        void popFront () {
            front = next!(POS,member) (front);
        }

        this (POS* pos, HEAD head, CURR curr) {
            this.front = first!(POS,member) (curr);
            this.head = head;
        }
    }

    alias for_each_next = _range!(POS,HEAD,CURR);

    //for ((pos) = first (curr, typeof (*(pos)), member);
    //     !is_end (pos, head, member);
    //     (pos) = next (pos, member)) 
    //{
    //    //
    //}
}

auto
for_each_prev (POS,HEAD,CURR,MEMBER) (POS pos, HEAD head, CURR curr, MEMBER member) {  // spa_list_for_each_prev
    struct 
    _range (POS,HEAD,CURR,MEMBER) {
        POS  front;
        bool empty () { return is_end!(pos, head, member); }
        void popFront () {
            front = prev!(front,member);
        }

        this (POS pos, HEAD head, CURR curr, MEMBER member) {
            front = last!(curr, typeof(*(pos)), member);
        }
    }

    return _range!(POS,HEAD,CURR,MEMBER) (pos,head,curr,member);

    //for ((pos) = last (curr, typeof(*(pos)), member);
    //     !is_end (pos, head, member);
    //     (pos) = prev (pos, member)) 
    //{
    //    //
    //}
}
                            //             &data.object_list
                            // object*     &d.global_list  link
                            // proxy_data, &d.global_list, global_link
auto                        // param*    , spa_list*,      link
for_each (string member,POS,HEAD) (POS* pos, HEAD head) {  // spa_list_for_each
    //alias POS  = typeof (*pos);   // object_*
    //alias HEAD = typeof (head);  // spa_list*
    return for_each_next!(POS,HEAD,HEAD,member) (pos,head,head);
    // object
    //   spa_list link
    // data
    //   spa_list object_list
    // param
    //   spa_list link
}

auto
for_each_reverse (POS,HEAD,MEMBER) (POS pos, HEAD head, MEMBER member) {  // spa_list_for_each_reverse
    return for_each_prev (pos, head, head, member);
}

auto
for_each_safe_next (POS,TMP,HEAD,CURR,MEMBER) (POS pos, TMP tmp, HEAD head, CURR curr, MEMBER member) {  // spa_list_for_each_safe_next
    struct 
    _range (POS,TMP,HEAD,CURR,MEMBER) {
        POS  front;
        TMP  tmp;
        bool empty () { 
            tmp = next!(pos, member);
            return is_end!(pos,head,member);
        }
        void popFront () {
            front = (tmp);
        }

        this (POS pos, HEAD head, CURR curr, MEMBER member) {
            front = first!(curr, typeof (*(pos)), member);
        }
    }

    return _range!(POS,TMP,HEAD,CURR,MEMBER) (pos,tmp,head,curr,member);

    //for ((pos) = first (curr, typeof (*(pos)), member);
    //     (tmp) = next (pos, member),
    //     !is_end (pos, head, member);
    //     (pos) = (tmp)) 
    //{
    //    //
    //}
}

auto
for_each_safe_prev  (POS,TMP,HEAD,CURR,MEMBER) (POS pos, TMP tmp, HEAD head, CURR curr, MEMBER member) {  // spa_list_for_each_safe_prev
    struct 
    _range (POS,TMP,HEAD,CURR,MEMBER) {
        POS  front;
        TMP  tmp;
        bool empty () { 
            tmp = prev!(pos, member);
            return is_end!(pos,head,member);
        }
        void popFront () {
            front = (tmp);
        }

        this (POS pos, HEAD head, CURR curr, MEMBER member) {
            front = last!(curr, typeof(*(pos)), member);
        }
    }

    return _range!(POS,TMP,HEAD,CURR,MEMBER) (pos,tmp,head,curr,member);

    //for ((pos) = last (curr, typeof(*(pos)), member);
    //     (tmp) = prev (pos, member),
    //     is_end (pos, head, member);
    //     (pos) = (tmp))
    //{
    //    //
    //}
}

auto
for_each_safe (POS,TMP,HEAD,MEMBER) (POS pos, TMP tmp, HEAD head, MEMBER member) {  // spa_list_for_each_safe
    return for_each_safe_next (pos, tmp, head, head, member);
}

void
for_each_safe_reverse  (POS,TMP,HEAD,MEMBER) (POS pos, TMP tmp, HEAD head, MEMBER member) {  // spa_list_for_each_safe_reverse
    return for_each_safe_prev (pos, tmp, head, head, member);
}

auto
cursor_start (CURSOR,HEAD,MEMBER) (CURSOR cursor, HEAD head, MEMBER member) {  // spa_list_cursor_start
    return prepend (head, &(cursor).member);
}

auto
for_each_cursor (POS,CURSOR,HEAD,MEMBER) (POS pos, CURSOR cursor, HEAD head, MEMBER member) {  // spa_list_for_each_cursor
    struct 
    _range (POS,CURSOR,HEAD,MEMBER) {
        POS  front;
        CURSOR cursor;
        bool empty () { 
            remove (&(pos).member);
            append (&(cursor).member, &(pos).member);
            return is_end!(pos,head,member);
        }
        void popFront () {
            front = next!(&(cursor), member);
        }

        this (POS pos, CURSOR cursor, HEAD head, MEMBER member) {
            front = first!(&(cursor).member, typeof(*(pos)), member);
        }
    }

    return _range!(POS,TMP,HEAD,CURR,MEMBER) (pos,tmp,head,curr,member);


    //for ((pos) = first (&(cursor).member, typeof(*(pos)), member);
    //    remove (&(pos).member),
    //    append (&(cursor).member, &(pos).member),
    //    !is_end (pos, head, member);
    //    (pos) = next (&(cursor), member)) 
    //{
    //    //
    //}
}

auto
cursor_end (CURSOR,MEMBER) (CURSOR cursor, MEMBER member) {  // spa_list_cursor_end
    return remove (&(cursor).member);
}

unittest {
    auto list = spa_list ();
    list.init_ ();
    assert (list.is_initialized);
    assert (list.is_empty);
}

unittest {
    auto list = spa_list ();
    auto elem = spa_list ();
    list.init_ ();
    elem.init_ ();
    list.insert (&elem);
    assert (list.is_initialized);
    assert (!list.is_empty);
}

unittest {
    auto list  = spa_list ();
    auto elem  = spa_list ();
    list.init_ ();
    elem.init_ ();
    list.insert (&elem);
    auto other = spa_list ();
    auto elem2 = spa_list ();
    other.init_ ();
    elem2.init_ ();
    other.insert (&elem2);
    list.insert_list (&other);
    assert (list.is_initialized);
    assert (!list.is_empty);
}

unittest {
    auto list  = spa_list ();
    auto elem  = spa_list ();
    list.init_ ();
    elem.init_ ();
    list.insert (&elem);
    auto other = spa_list ();
    auto elem2 = spa_list ();
    other.init_ ();
    elem2.init_ ();
    other.insert (&elem2);
    list.insert_list (&other);
    list.remove (&elem);
    assert (list.is_initialized);
    assert (!list.is_empty);
    list.remove (&elem2);
    assert (list.is_initialized);
    assert (list.is_empty);
}

unittest {
    auto list  = spa_list ();
    auto elem  = spa_list ();
    auto elem2 = spa_list ();
    list.init_ ();
    elem.init_ ();
    elem2.init_ ();
    list.insert (&elem);
    list.append (&elem2);
    assert (list.is_initialized);
    assert (!list.is_empty);
    list.remove (&elem);
    assert (list.is_initialized);
    assert (!list.is_empty);
    list.remove (&elem2);
    assert (list.is_initialized);
    assert (list.is_empty);
}

unittest {
    auto list  = spa_list (null);
    auto elem  = spa_list (null);
    auto elem2 = spa_list (null);
    list.init_ ();
    elem.init_ ();
    elem2.init_ ();
    list.insert (&elem);
    list.prepend (&elem2);
    assert (list.is_initialized);
    assert (!list.is_empty);
    list.remove (&elem);
    assert (list.is_initialized);
    assert (!list.is_empty);
    list.remove (&elem2);
    assert (list.is_initialized);
    assert (list.is_empty);
}

unittest {
    auto list  = spa_list (null);
    auto elem  = spa_list (null);
    auto elem2 = spa_list (null);
    list.init_ ();
    elem.init_ ();
    elem2.init_ ();
    list.insert (&elem);
    list.append (&elem2);

    struct param {
        uint32_t id;
        int32_t  seq;
        spa_list link;
        spa_pod* param;
        alias spa_pod  = void;
        alias uint32_t = uint;
        alias int32_t  = int;
    };

    struct object_ {          // pos,pos2
        spa_list link;        // member
    }

    struct data_ {
        spa_list object_list;  // head
    }

    // head
    data_   d;
    d.object_list.init_();
    // pos
    object_ obj;
    obj.link.init_ ();
    d.object_list.insert (&obj.link);
    // pos 2
    object_ obj2;
    obj2.link.init_ ();
    d.object_list.append (&obj2.link);
    int i;
    foreach (ref e; for_each!"link" (&obj, &d.object_list)) {
        if (i == 0)
            assert (&e.link == &obj.link);
        else 
        if (i == 1)
            assert (&e.link == &obj2.link);
        i++;
    }
    assert (i == 2);
}

