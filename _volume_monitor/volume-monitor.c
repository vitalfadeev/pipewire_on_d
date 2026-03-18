/**
 * Пример мониторинга громкости через libpipewire
 * Компиляция: gcc -o volume-monitor volume-monitor.c $(pkg-config --cflags --libs libpipewire-0.3)
 */

#include <pipewire/pipewire.h>
#include <spa/param/props.h>
#include <spa/pod/parser.h>
#include <stdio.h>
#include <string.h>

struct app_data {
    struct pw_main_loop *loop;
    struct pw_core *core;
    struct pw_registry *registry;
    struct pw_proxy *node_proxy;
    uint32_t target_node_id;
    int sync;
};

// --- КОЛБЭК НА ИЗМЕНЕНИЕ ПАРАМЕТРОВ (САМОЕ ВАЖНОЕ) ---
static void on_node_param_changed(void *data, uint32_t id, const struct spa_pod *pod) {
    if (id != SPA_PARAM_Props || pod == NULL)
        return;

    float volume = -1.0f;
    struct spa_pod_parser parser;
    spa_pod_parser_init(&parser, pod->data, pod->size);

    // Парсим POD-объект в поисках свойства channelVolumes
    if (spa_pod_parser_get_object(&parser, SPA_TYPE_OBJECT_Props, NULL, NULL, NULL) < 0)
        return;

    uint32_t prop_id;
    const struct spa_pod *prop_value;
    while (spa_pod_parser_get_prop(&parser, &prop_id, NULL, &prop_value) > 0) {
        if (prop_id == SPA_PROP_channelVolumes && spa_pod_is_array(prop_value)) {
            const float *vols = (const float*)spa_pod_array_get_values(prop_value);
            if (vols) {
                volume = vols[0]; // Берем громкость первого канала
                printf("Громкость изменена: %.2f (%.0f%%)\n", volume, volume * 100.0f);
            }
            break;
        }
    }
}

// --- ВСПОМОГАТЕЛЬНЫЕ КОЛБЭКИ ДЛЯ ПОИСКА УСТРОЙСТВА ---
static void registry_event_global(void *data, uint32_t id, uint32_t permissions,
                                   const char *type, uint32_t version, const struct spa_dict *props) {
    struct app_data *app = data;
    if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0 && props) {
        const char *media_class = spa_dict_lookup(props, PW_KEY_MEDIA_CLASS);
        if (media_class && strcmp(media_class, "Audio/Sink") == 0) {
            printf("Найден Audio Sink: id=%u\n", id);
            if (app->target_node_id == 0) {
                app->target_node_id = id;
            }
        }
    }
}

static void on_core_done(void *data, uint32_t id, int seq) {
    struct app_data *app = data;
    if (id == PW_ID_CORE && seq == app->sync) {
        app->sync = 0;
        pw_main_loop_quit(app->loop);
    }
}

// --- ГЛАВНАЯ ФУНКЦИЯ ---
int main(int argc, char *argv[]) {
    struct app_data app = {0};
    pw_init(&argc, &argv);
    app.loop = pw_main_loop_new(NULL);
    struct pw_context *context = pw_context_new(pw_main_loop_get_loop(app.loop), NULL, 0);
    app.core = pw_context_connect(context, NULL, 0);

    // Получение реестра и поиск устройств
    app.registry = pw_core_get_registry(app.core, PW_VERSION_REGISTRY, 0);
    static const struct pw_registry_events registry_events = {
        PW_VERSION_REGISTRY_EVENTS,
        .global = registry_event_global,
    };
    pw_registry_add_listener(app.registry, &app.registry_listener, &registry_events, &app);

    // Синхронизация для загрузки реестра
    app.sync = pw_core_sync(app.core, PW_ID_CORE, 0);
    while (app.sync) {
        pw_main_loop_run(app.loop);
    }

    // Если нашли устройство, создаем прокси и подписываемся на события
    if (app.target_node_id != 0) {
        app.node_proxy = pw_registry_bind(app.registry, app.target_node_id,
                                          PW_TYPE_INTERFACE_Node, PW_VERSION_NODE, 0);
        static const struct pw_proxy_events node_proxy_events = {
            .version = PW_VERSION_PROXY_EVENTS,
            .param_changed = on_node_param_changed,
        };
        pw_proxy_add_listener(app.node_proxy, &app.node_listener, &node_proxy_events, &app);
        printf("Ожидание изменений громкости...\n");
        pw_main_loop_run(app.loop); // Бесконечный цикл
    }

    // Очистка ресурсов (в примере опущена для краткости)
    return 0;
}
