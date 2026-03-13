/**
 * Мониторинг системной громкости напрямую через libpipewire
 * Компиляция: gcc -o pw-monitor pw-monitor.c $(pkg-config --cflags --libs libpipewire-0.3)
 */

#include <pipewire/pipewire.h>
#include <spa/param/props.h>
#include <spa/pod/parser.h>
#include <stdio.h>
#include <string.h>

// Структура данных приложения
struct app_data {
    struct pw_main_loop *loop;
    struct pw_core *core;
    struct spa_hook core_listener;
    struct pw_registry *registry;
    struct spa_hook registry_listener;
    struct pw_proxy *node_proxy;
    struct spa_hook node_listener;
    uint32_t target_node_id;
    int sync;
};

// --- Колбэки для обработки параметров узла (САМОЕ ВАЖНОЕ) ---
static void on_node_param_changed(void *data, uint32_t id, const struct spa_pod *pod) {
    if (id != SPA_PARAM_Props || pod == NULL)
        return;

    // Парсим POD, чтобы найти значение громкости
    float volume = -1.0f;
    uint32_t channelVolumes[2]; // Для хранения, если понадобятся каналы

    struct spa_pod_parser parser;
    spa_pod_parser_init(&parser, pod->data, pod->size);

    // Мы ожидаем объект типа SPA_TYPE_OBJECT_Props
    if (spa_pod_parser_get_object(&parser,
            SPA_TYPE_OBJECT_Props,    // тип объекта
            NULL,                      // тип параметра (не важен)
            NULL,                      // не нужен
            NULL) < 0) {                // не нужен
        return;
    }

    uint32_t prop_id;
    const struct spa_pod *prop_value;

    // Перебираем все свойства объекта
    while (spa_pod_parser_get_prop(&parser, &prop_id, NULL, &prop_value) > 0) {
        if (prop_id == SPA_PROP_channelVolumes) {
            // Проверяем, что значение - массив float-ов
            if (spa_pod_is_array(prop_value)) {
                uint32_t n_values = spa_pod_array_get_info(prop_value, NULL, NULL);
                if (n_values > 0) {
                    const float *vols = (const float*)spa_pod_array_get_values(prop_value);
                    if (vols) {
                        volume = vols[0]; // Берём громкость первого канала
                        printf("Громкость изменена: %.2f (%.0f%%)\n", volume, volume * 100.0f);
                    }
                }
            }
            break; // Нашли, что искали
        }
    }
}

// Структура с колбэками узла
static const struct pw_proxy_events node_proxy_events = {
    .version = PW_VERSION_PROXY_EVENTS,
    .param_changed = on_node_param_changed,
};

// --- Колбэки реестра (поиск устройств) ---
static void registry_event_global(void *data, uint32_t id,
                                   uint32_t permissions, const char *type,
                                   uint32_t version, const struct spa_dict *props)
{
    struct app_data *app = data;

    if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0 && props) {
        const char *media_class = spa_dict_lookup(props, PW_KEY_MEDIA_CLASS);
        if (media_class && strcmp(media_class, "Audio/Sink") == 0) {
            const char *node_name = spa_dict_lookup(props, PW_KEY_NODE_NAME);
            const char *node_desc = spa_dict_lookup(props, PW_KEY_NODE_DESCRIPTION);
            printf("Найден Audio Sink: id=%u, name=%s\n", id, node_name ? node_name : "unnamed");

            if (app->target_node_id == 0) {
                app->target_node_id = id;
                printf("Целевой ID установлен: %u\n", id);
            }
        }
    }
}

static void registry_event_global_remove(void *data, uint32_t id) {
    struct app_data *app = data;
    if (app->target_node_id == id) {
        printf("Целевое устройство %u отключено\n", id);
        app->target_node_id = 0;
    }
}

static const struct pw_registry_events registry_events = {
    .version = PW_VERSION_REGISTRY_EVENTS,
    .global = registry_event_global,
    .global_remove = registry_event_global_remove,
};

// --- Колбэки ядра (core) ---
static void on_core_done(void *data, uint32_t id, int seq) {
    struct app_data *app = data;
    if (id == PW_ID_CORE && seq == app->sync) {
        app->sync = 0;
        pw_main_loop_quit(app->loop);
    }
}

static void on_core_error(void *data, uint32_t id, int seq, int res, const char *message) {
    fprintf(stderr, "Ошибка ядра: %s\n", message);
    struct app_data *app = data;
    pw_main_loop_quit(app->loop);
}

static const struct pw_core_events core_events = {
    .version = PW_VERSION_CORE_EVENTS,
    .done = on_core_done,
    .error = on_core_error,
};

// --- Главная функция ---
int main(int argc, char *argv[]) {
    struct app_data app = {0};
    struct pw_context *context = NULL;

    pw_init(&argc, &argv);

    // 1. Создание главного цикла
    app.loop = pw_main_loop_new(NULL);
    if (!app.loop) {
        fprintf(stderr, "Не удалось создать главный цикл\n");
        return -1;
    }

    // 2. Создание контекста и подключение к серверу
    context = pw_context_new(pw_main_loop_get_loop(app.loop), NULL, 0);
    if (!context) {
        fprintf(stderr, "Не удалось создать контекст\n");
        pw_main_loop_destroy(app.loop);
        return -1;
    }

    app.core = pw_context_connect(context, NULL, 0);
    if (!app.core) {
        fprintf(stderr, "Не удалось подключиться к серверу\n");
        pw_context_destroy(context);
        pw_main_loop_destroy(app.loop);
        return -1;
    }

    // 3. Добавление слушателя ядра
    pw_core_add_listener(app.core, &app.core_listener, &core_events, &app);

    // 4. Получение реестра и подписка на события
    app.registry = pw_core_get_registry(app.core, PW_VERSION_REGISTRY, 0);
    pw_registry_add_listener(app.registry, &app.registry_listener, &registry_events, &app);

    // 5. Синхронизация для загрузки реестра
    app.sync = pw_core_sync(app.core, PW_ID_CORE, 0);
    while (app.sync) {
        pw_main_loop_run(app.loop);
    }

    // 6. Если нашли устройство, создаём прокси и начинаем слушать
    if (app.target_node_id != 0) {
        app.node_proxy = pw_registry_bind(app.registry,
                                           app.target_node_id,
                                           PW_TYPE_INTERFACE_Node,
                                           PW_VERSION_NODE,
                                           0);
        if (app.node_proxy) {
            pw_proxy_add_listener(app.node_proxy, &app.node_listener, &node_proxy_events, &app);
            printf("Ожидание изменений громкости...\n");
            pw_main_loop_run(app.loop);
        }
    } else {
        fprintf(stderr, "Не найдено устройство вывода (Audio Sink)\n");
    }

    // 7. Очистка
    if (app.node_proxy)
        pw_proxy_destroy(app.node_proxy);
    if (app.registry)
        pw_proxy_destroy((struct pw_proxy*)app.registry);
    if (app.core)
        pw_core_disconnect(app.core);
    if (context)
        pw_context_destroy(context);
    if (app.loop)
        pw_main_loop_destroy(app.loop);

    pw_deinit();
    return 0;
}