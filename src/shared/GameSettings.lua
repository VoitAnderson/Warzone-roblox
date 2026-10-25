-- ReplicatedStorage > Shared > GameSettings (ModuleScript)
-- Конфиг всех режимов. Меняется одна строка — весь матч перестраивается.

return {
	-- === РЕЖИМ МАТЧА ===
	MODE = "Quads",        -- "Solo" | "Duos" | "Quads" | "Trios"
	MAX_PLAYERS = 100,
	SQUAD_SIZE = 4,

	-- === DBNO / ГУЛАГ ===
	DBNO_ENABLED = true,   -- Solo: false (смерть сразу), Quads: true
	DBNO_BLEEDOUT_TIME = 60,     -- секунд ползти с 0 HP
	REVIVE_TIME = 5,             -- сколько секунд тиммейт поднимает
	SELF_REVIVE_TIME = 8,        -- если есть Self-Revive Kit
	GULAG_ENABLED = true,
	GULAG_ROUND_TIME = 40,      -- таймер боя в Гулаге

	-- === ЗДОРОВЬЕ И БРОНЯ ===
	MAX_HEALTH = 100,
	PLATES_MAX = 3,
	PLATE_HP = 50,              -- каждая пластина +50 HP брони
	PLATE_EQUIP_TIME = 2.5,     -- секунд надеть пластину
	HEALTH_REGEN_DELAY = 5,     -- после урона — 5 сек до регенерации
	HEALTH_REGEN_RATE = 10,     -- HP в секунду

	-- === ЭКОНОМИКА ===
	START_CASH = 0,
	KILL_REWARD = 500,

	-- === ЗОНА / ГАЗ ===
	ZONE_INITIAL_RADIUS = 400,  -- стадов, стартовый круг
	ZONE_SHRINK_TIME = 300,     -- сек до начала сжатия
	GAS_DPS = 5,                -- урон от газа в секунду (растёт по фазам)
}
