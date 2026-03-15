import importc;

version(X):
spa_pod_prop* prop;
alias iter = prop;

auto
SPA_POD_BODY_SIZE (T) (T pod) {
    return (cast (spa_pod*) pod).size;
}

auto
SPA_POD_OBJECT_FOREACH (T,ITER,DG) (T obj, ITER iter, DG dg) {
    return SPA_POD_OBJECT_BODY_FOREACH (&obj.body, SPA_POD_BODY_SIZE (obj), iter, dg);
}

auto
SPA_POD_OBJECT_BODY_FOREACH  (BODY,SIZE,ITER,DG) (BODY body, SIZE size, ITER iter, DG dg) {
    // spa_pod_prop* iter
    for (auto iter = spa_pod_prop_first (body);
         spa_pod_prop_is_inside (body, size, iter);
         iter = spa_pod_prop_next (iter)) 
    {
        dg (iter);
    }
}
