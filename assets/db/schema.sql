CREATE TABLE body_parts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)

CREATE TABLE daily_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL
  )

  CREATE TABLE daily_meal_foods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER,
    food_id INTEGER,
    servingSize REAL NOT NULL,
    FOREIGN KEY (meal_id) REFERENCES daily_meals (id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
  )

  CREATE TABLE daily_meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    log_id INTEGER,
    meal_type TEXT NOT NULL,
    FOREIGN KEY (log_id) REFERENCES daily_logs (id) ON DELETE CASCADE
  )

  CREATE TABLE equipment (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)

CREATE TABLE exercise_sets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	workout_log_id INTEGER,
	workout_id INTEGER,
    exercise_id TEXT NOT NULL,
    set_number INTEGER NOT NULL,
    weight REAL,
    reps INTEGER,
	is_finished INTEGER DEFAULT 0,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
	FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
	FOREIGN KEY (workout_log_id) REFERENCES workout_logs(id) ON DELETE CASCADE
)

CREATE TABLE exercise_types (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)

CREATE TABLE exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type_id INTEGER NOT NULL,
    muscle_id INTEGER NOT NULL,
    equipment_id INTEGER NOT NULL,
    bodyPart_id INTEGER NOT NULL,
    mediaId TEXT,
    own_type TEXT DEFAULT 'custom',
	priority INTEGER NOT NULL DEFAULT 10,
    FOREIGN KEY (type_id) REFERENCES exercise_types(id),
    FOREIGN KEY (muscle_id) REFERENCES muscles(id),
    FOREIGN KEY (equipment_id) REFERENCES equipment(id),
    FOREIGN KEY (bodyPart_id) REFERENCES body_parts(id)
)

CREATE TABLE food_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT
)

CREATE TABLE foods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  calories REAL,
  servingSize REAL,
  measure TEXT,
  fat REAL,
  protein REAL,
  carbohydrate REAL,
  type TEXT
)

CREATE TABLE general (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	db_version INTEGER DEFAULT 1
)

CREATE TABLE muscles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)

CREATE TABLE plan_meal_food (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  meal_id INTEGER NOT NULL,
  food_id INTEGER NOT NULL,
  servingSize REAL NOT NULL, -- The dynamic serving size for the food
  FOREIGN KEY (meal_id) REFERENCES plan_meals(id),
  FOREIGN KEY (food_id) REFERENCES foods(id)
)

CREATE TABLE plan_meals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER,
  meal_type TEXT,
  FOREIGN KEY(plan_id) REFERENCES food_plans(id)
)

CREATE TABLE recipe_foods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id INTEGER,
  food_id INTEGER,
  FOREIGN KEY(recipe_id) REFERENCES recipes(id),
  FOREIGN KEY(food_id) REFERENCES foods(id)
)

CREATE TABLE recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT
)

CREATE TABLE workout_exercises (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id INTEGER NOT NULL,
    exercise_id TEXT NOT NULL,
	order_index INTEGER,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
)

CREATE TABLE workout_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id INTEGER,
    start_date TEXT NOT NULL, -- Stored as ISO 8601 (YYYY-MM-DD HH:MM:SS)
    end_date TEXT, -- Stored as ISO 8601 (YYYY-MM-DD HH:MM:SS)
    is_finished INTEGER DEFAULT 0,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
)

CREATE TABLE workouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
)