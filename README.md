# Plinko

Мини-игра на **Defold**: шары падают через поле кеглей в корзины внизу.

Вероятности попадания задаются **вручную** (веса в конфиге / редакторе). Падение — кинематическая траектория к уже выбранной корзине, без Box2D.

---

## Как играть

| Действие | Управление |
|----------|------------|
| Один шар | **DROP 1** |
| Несколько шаров | **DROP N** (тратит сколько есть, если шаров меньше N) |
| Тест: добавить шары | **ADD** |
| Ускорение ×2 | **x2** |
| Редактор уровня | Main Menu → **Editor** |
| Сброс прогресса + уровня | Main Menu → **Reset** |

На поле под корзинами — debug-статистика через `draw_text`: hits, score корзины, %, общий Score.

---

## Соответствие ТЗ

| Требование | Статус | Где смотреть |
|------------|--------|--------------|
| Кегли + корзины | ✅ | `common/board_layout.lua`, `modules/field.lua` |
| Падение через кегли | ✅* | `modules/path.lua` + `modules/fall.lua` |
| Вероятности из конфига | ✅ | `configs/level.lua` → `baskets[].weight` |
| Очки за корзину | ✅ | `baskets[].score` → resolve по `target` |
| 10 корзин | ✅ | дефолт в конфиге; в editor 5…11 |
| Лимит шаров | ✅ | `economy` |
| Реген 1 шар / N сек | ✅ | `game.regen_one_ball_seconds` |
| Cap регена + cheat выше cap | ✅ | `balls_regen_cap`, кнопка ADD |
| UI: drop 1 / many / add / balls / timer | ✅ | `game.gui` + `game.gui_script` |
| Debug: hits / % / score → `draw_text` | ✅ | `modules/debug_stats.lua` |
| **Доп.** Save состояния | ✅ | `common/save_data.lua` |
| **Доп.** Настраиваемое число корзин | ✅ | Level Editor |

\*Исход выбирается **до** анимации (`pick_by_weight`). Path только визуализирует путь в выбранную корзину. Очки и hits пишутся **только по `target`**, не по «физическому» контакту — так вероятности из конфига всегда выполняются.

```
DROP → spend ball → RNG(target) → path.build → fall → credit target
```

---

## Структура репозитория

```
plinkoGame/
├── build/                готовый HTML5-бандл
├── ТЗ.md
└── src/                  Defold-проект (открывать в редакторе)
    ├── main/             bootstrap, камера, Monarch-вход
    ├── screens/
    │   ├── main_menu/    Play / Editor / Sound / Reset
    │   ├── game/         геймплей + modules/ + objects/
    │   └── level_editor/ веса, очки, layout, game-параметры + preview
    ├── configs/          только данные (без логики)
    │   ├── level.lua     корзины, layout, экономика
    │   └── fall.lua      feel падения
    ├── common/           shared: level_*, save, board_layout, consts…
    └── assets/           атласы, шрифты, звуки
```

Зависимости (см. `src/game.project`): **Monarch** (экраны), **Druid** (GUI), **ludobits** (savetable), defold-event.

---

## Архитектура

### Экраны

`main` поднимает save → sounds → Monarch. Экраны: `main_menu` / `game` / `level_editor` (`screens/screens.lua`).  
GUI шлёт команды в game-скрипт через `consts.MSG` (`DROP_BALL`, `DROP_MANY`, `ADD_BALLS`, `TOGGLE_SPEED`, …); обратно — `UI_UPDATE`.

### Слои (game)

| Модуль | Роль |
|--------|------|
| `controller` | оркестратор: economy / session / field / save / UI |
| `session` | спавн, burst, resolve in-flight шаров |
| `field` | создание/очистка GO (корзины, пины, лунка) |
| `baskets` | обёртка над списком корзин + RNG за сессию |
| `path` + `fall` | waypoints → Bezier-анимация |
| `economy` | шары, реген до cap, cheat-add |
| `debug_stats` | hits / % / Score → `@render:` `draw_text` |

`game.script` — тонкий адаптер на `controller` (init/update/message).

### Common (без зависимости от `screens`)

| Модуль | Роль |
|--------|------|
| `board_layout` | геометрия поля (пины, слоты корзин, hole) |
| `level_schema` | normalize, defaults, `composition_key`, лимиты editor |
| `level_rng` | `pick_by_weight`, Monte Carlo `simulate` |
| `level_edit` | мутации уровня для editor |
| `level` | фасад schema + rng + edit (удобный require) |
| `level_store` | активный уровень: save override или `configs/level.lua` |
| `save_data` | прогресс игрока + override уровня (`gamedata`) |
| `consts` | MSG / URL / BOARD / tint |

Владение данными: `configs/*` → `level_store.get()` → `controller` (economy + baskets + field). Прогресс пишет только `controller` через `save_data`.

---

## Конфиг уровня

`configs/level.lua` — чистые данные:

```lua
baskets = {
  { id = 1, weight = 1, score = 10 },
  -- …
}
game = {
  balls_start = 10,
  regen_one_ball_seconds = 5,
  balls_regen_cap = 20,
  cheat_add_balls = 10,
  drop_many_count = 5,
  drop_many_spawn_interval_seconds = 0.05,
}
```

Вероятность корзины: **`weight / sum(weights)`**.

Пустой `layout` → пирамида строится автоматически. Feel падения — `configs/fall.lua` (`duration`, `gravity`, `bounce_*`, …).

---

## Level Editor

- число корзин 5…11;
- вес и очки каждой корзины;
- вкл/выкл пинов на сетке;
- game-параметры: старт шаров, drop many, реген, **regen cap**, **cheat add**;
- **Simulate** — Monte Carlo по весам без спавна GO (`level_rng`);
- превью поля — `level_editor/modules/preview.lua`;
- **Save** пишет уровень в save (`level_store.set`); при смене `composition_key` прогресс сбрасывается.

---

## Сохранение

Файл `gamedata` (ludobits savetable):

| Ключ | Содержание |
|------|------------|
| корень | `balls`, `regen_elapsed`, `score`, `hits`, `total_hits`, `level_key`, `sound` |
| `level` | override уровня (иначе дефолт из `configs/level.lua`) |

Смена уровня (другой `composition_key`: корзины / веса / scores / layout / game-параметры) или **Reset** в меню → полный сброс прогресса.

---

## Зачем kinematic, а не Box2D

ТЗ требует **ручные вероятности**. При честной физике распределение уезжает от конфига. Поэтому:

1. RNG выбирает корзину по весам;
2. path строит правдоподобную траекторию через кегли к ней;
3. статистика и очки всегда совпадают с заданными вероятностями.

Это осознанный production-паттерн для ивентов/экономики, где важен контроль дропа.
