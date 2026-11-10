//! Versemend production host (D-861): the Rust host adopted from the
//! engine spike — Bevy + mlua with the vendored Lua 5.5.1 — running
//! the playable slice's game unchanged.
//!
//! The game (`game/*.lua`, embedded verbatim; byte-identity with the
//! slice tree is a gate, not a hope) was written engine-independently
//! against a small platform interface: draw primitives, fixed text
//! metrics, sound cues, one save slot, text-input focus. This host
//! implements that interface three ways, like the slice's C host did:
//!
//! * the GUI platform (Bevy UI nodes + Bevy audio) for play,
//! * an in-memory platform factory for `--selftest`, which runs the
//!   game's own 147-check proof script (full playthrough included)
//!   inside this binary's Lua state — its transcript must equal the
//!   system-Lua runs byte for byte, and the gate records must
//!   reproduce their recorded checksums exactly,
//! * the same GUI platform driven by the slice's `shots.lua` walk
//!   for `--screenshot`, capturing the named beats as PNGs.
//!
//! Text measurement returns the mock platform's fixed metrics in
//! every mode: layout is part of the game's determinism, and the
//! shipped fonts are chosen to sit close to that grid (the C host's
//! stated law, kept).
//!
//! The Lua state is created with mlua's unsafe constructor for the
//! same reason the spike documented: the game's gate harness needs
//! the debug library (instruction-budget count hooks, including
//! inside player-created coroutines) in the TRUSTED host state.
//! Player code never sees that state: the harness builds a whitelist
//! environment for player chunks, and no Rust callbacks are exposed
//! to player code.

use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use mlua::prelude::*;

// ---------------------------------------------------------------------------
// Embedded Lua modules — the slice's sources, verbatim.

const MODULES: &[(&str, &str)] = &[
    ("app", include_str!("../game/app.lua")),
    ("boss", include_str!("../game/boss.lua")),
    ("boss2", include_str!("../game/boss2.lua")),
    ("content", include_str!("../game/content.lua")),
    ("effects", include_str!("../game/effects.lua")),
    ("gate", include_str!("../game/gate.lua")),
    ("levels", include_str!("../game/levels.lua")),
    ("save", include_str!("../game/save.lua")),
    ("fixtures", include_str!("../tests/fixtures.lua")),
    ("mock_platform", include_str!("../tests/mock_platform.lua")),
    ("selftest", include_str!("../tests/selftest.lua")),
    ("shots", include_str!("../tests/shots.lua")),
];

fn install_searcher(lua: &Lua) -> LuaResult<()> {
    let searcher = lua.create_function(|lua, name: String| {
        for (n, src) in MODULES {
            if *n == name.as_str() {
                let f = lua.load(*src).set_name(name.clone()).into_function()?;
                return Ok(LuaValue::Function(f));
            }
        }
        Ok(LuaValue::String(lua.create_string(format!(
            "\n\tno embedded module '{name}'"
        ))?))
    })?;
    let package: LuaTable = lua.globals().get("package")?;
    let searchers: LuaTable = package.get("searchers")?;
    // Position 1 replaces the preload searcher: embedded modules win,
    // and every game/test module resolves from the table above.
    searchers.set(1, searcher)?;
    Ok(())
}

fn new_lua() -> LuaResult<Lua> {
    // See the module docs: the unsafe constructor is deliberate and
    // scoped — debug is used only by the trusted harness's own count
    // hooks over player chunks; player environments are whitelists.
    let lua = unsafe { Lua::unsafe_new_with(mlua::StdLib::ALL, LuaOptions::default()) };
    install_searcher(&lua)?;
    Ok(lua)
}

fn require(lua: &Lua, name: &str) -> LuaResult<LuaTable> {
    lua.load(format!("return require('{name}')")).eval()
}

// ---------------------------------------------------------------------------
// The platform interface

/// The mock platform's fixed text metrics (tests/mock_platform.lua),
/// returned by every platform in every mode.
pub fn metrics_of(kind: &str) -> (f32, f32) {
    match kind {
        "title" => (30.0, 64.0),
        "display" => (16.0, 38.0),
        "code" => (11.0, 24.0),
        "code_small" => (9.0, 20.0),
        "small" => (8.0, 20.0),
        // body, body_bold, and anything unknown
        _ => (10.0, 26.0),
    }
}

/// One screenshot beat: a name plus the draw commands of its frame.
pub type ShotList = Vec<(String, Vec<DrawCmd>)>;

#[derive(Clone, Debug, PartialEq)]
pub enum DrawCmd {
    Rect {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        color: String,
        alpha: f32,
    },
    Image {
        name: String,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        alpha: f32,
    },
    Text {
        x: f32,
        y: f32,
        text: String,
        kind: String,
        color: String,
    },
}

#[derive(Default)]
pub struct PlatState {
    pub draws: Vec<DrawCmd>,
    pub sounds: Vec<String>,
    pub save_mem: Option<String>,
    pub save_path: Option<PathBuf>,
    pub text_input: bool,
}

pub type SharedPlat = Arc<Mutex<PlatState>>;

pub fn save_path() -> PathBuf {
    if let Ok(p) = std::env::var("VERSEMEND_SAVE") {
        if !p.is_empty() {
            return PathBuf::from(p);
        }
    }
    #[cfg(target_os = "android")]
    {
        if let Some(app) = bevy_android::ANDROID_APP.get() {
            if let Some(dir) = app.internal_data_path() {
                return dir.join("versemend-save.txt");
            }
        }
    }
    PathBuf::from("versemend-save.txt")
}

fn make_platform(lua: &Lua, state: SharedPlat) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    let s = state.clone();
    t.set(
        "draw_rect",
        lua.create_function(
            move |_, (x, y, w, h, color, alpha): (f32, f32, f32, f32, String, Option<f32>)| {
                s.lock().unwrap().draws.push(DrawCmd::Rect {
                    x,
                    y,
                    w,
                    h,
                    color,
                    alpha: alpha.unwrap_or(255.0),
                });
                Ok(())
            },
        )?,
    )?;

    let s = state.clone();
    t.set(
        "draw_image",
        lua.create_function(
            move |_, (name, x, y, w, h, alpha): (String, f32, f32, f32, f32, Option<f32>)| {
                s.lock().unwrap().draws.push(DrawCmd::Image {
                    name,
                    x,
                    y,
                    w,
                    h,
                    alpha: alpha.unwrap_or(255.0),
                });
                Ok(())
            },
        )?,
    )?;

    let s = state.clone();
    t.set(
        "draw_text",
        lua.create_function(
            move |_, (x, y, text, kind, color): (f32, f32, String, String, String)| {
                s.lock().unwrap().draws.push(DrawCmd::Text {
                    x,
                    y,
                    text,
                    kind,
                    color,
                });
                Ok(())
            },
        )?,
    )?;

    t.set(
        "measure",
        lua.create_function(|_, (text, kind): (String, String)| {
            let (cw, lh) = metrics_of(&kind);
            Ok((text.len() as f32 * cw, lh))
        })?,
    )?;

    let s = state.clone();
    t.set(
        "sound",
        lua.create_function(move |_, name: String| {
            s.lock().unwrap().sounds.push(name);
            Ok(())
        })?,
    )?;

    let s = state.clone();
    t.set(
        "read_save",
        lua.create_function(move |_, ()| {
            let st = s.lock().unwrap();
            if let Some(path) = &st.save_path {
                Ok(std::fs::read_to_string(path).ok())
            } else {
                Ok(st.save_mem.clone())
            }
        })?,
    )?;

    let s = state.clone();
    t.set(
        "write_save",
        lua.create_function(move |_, bytes: String| {
            let mut st = s.lock().unwrap();
            if let Some(path) = &st.save_path {
                let path = path.clone();
                let _ = std::fs::write(path, &bytes);
            } else {
                st.save_mem = Some(bytes);
            }
            Ok(())
        })?,
    )?;

    let s = state.clone();
    t.set(
        "set_text_input",
        lua.create_function(move |_, on: bool| {
            s.lock().unwrap().text_input = on;
            Ok(())
        })?,
    )?;

    Ok(t)
}

/// A factory in the mock platform's shape: `{ new = fn }`, each call
/// returning a platform with its own in-memory save slot.
fn make_factory(lua: &Lua) -> LuaResult<LuaTable> {
    let factory = lua.create_table()?;
    factory.set(
        "new",
        lua.create_function(|lua, ()| {
            let state: SharedPlat = Arc::new(Mutex::new(PlatState::default()));
            make_platform(lua, state)
        })?,
    )?;
    Ok(factory)
}

// ---------------------------------------------------------------------------
// The game, held in one Lua state

pub struct Game {
    lua: Lua,
    app_key: LuaRegistryKey,
}

impl Game {
    pub fn new(platform: LuaTable) -> LuaResult<Self> {
        let lua = new_lua()?;
        let app_mod = require(&lua, "app")?;
        let new_fn: LuaFunction = app_mod.get("new")?;
        let app: LuaTable = new_fn.call(platform)?;
        let app_key = lua.create_registry_value(app)?;
        Ok(Self { lua, app_key })
    }

    /// The GUI path: the platform table must be built in the game's
    /// own Lua state, bound to the host's shared platform state.
    pub fn new_with_plat(plat: SharedPlat) -> LuaResult<Self> {
        let lua = new_lua()?;
        let platform = make_platform(&lua, plat)?;
        let app_mod = require(&lua, "app")?;
        let new_fn: LuaFunction = app_mod.get("new")?;
        let app: LuaTable = new_fn.call(platform)?;
        let app_key = lua.create_registry_value(app)?;
        Ok(Self { lua, app_key })
    }

    fn app(&self) -> LuaResult<LuaTable> {
        self.lua.registry_value(&self.app_key)
    }

    pub fn event_click(&self, x: f32, y: f32) -> LuaResult<()> {
        let ev = self.lua.create_table()?;
        ev.set("type", "click")?;
        ev.set("x", x)?;
        ev.set("y", y)?;
        let app = self.app()?;
        let f: LuaFunction = app.get("event")?;
        f.call::<()>((app, ev))?;
        Ok(())
    }

    pub fn event_text(&self, text: &str) -> LuaResult<()> {
        let ev = self.lua.create_table()?;
        ev.set("type", "text")?;
        ev.set("text", text)?;
        let app = self.app()?;
        let f: LuaFunction = app.get("event")?;
        f.call::<()>((app, ev))?;
        Ok(())
    }

    pub fn event_key(&self, key: &str) -> LuaResult<()> {
        let ev = self.lua.create_table()?;
        ev.set("type", "key")?;
        ev.set("key", key)?;
        let app = self.app()?;
        let f: LuaFunction = app.get("event")?;
        f.call::<()>((app, ev))?;
        Ok(())
    }

    pub fn update(&self, dt_ms: i64) -> LuaResult<()> {
        let app = self.app()?;
        let f: LuaFunction = app.get("update")?;
        f.call::<()>((app, dt_ms))?;
        Ok(())
    }

    pub fn render(&self) -> LuaResult<()> {
        let app = self.app()?;
        let f: LuaFunction = app.get("render")?;
        f.call::<()>(app)?;
        Ok(())
    }
}

/// One full frame against the platform: clear the draw list, render,
/// hand back the frame's commands.
pub fn render_frame(game: &Game, state: &SharedPlat) -> LuaResult<Vec<DrawCmd>> {
    state.lock().unwrap().draws.clear();
    game.render()?;
    Ok(state.lock().unwrap().draws.clone())
}

// ---------------------------------------------------------------------------
// Headless modes

/// The slice's proof script against this host: returns (transcript,
/// failure count). The transcript must match the C host's byte for
/// byte — that equality is the adoption gate, checked by the build
/// harness, not assumed here.
pub fn run_selftest() -> LuaResult<(String, i64)> {
    let lua = new_lua()?;
    let factory = make_factory(&lua)?;
    let selftest = require(&lua, "selftest")?;
    let run: LuaFunction = selftest.get("run")?;
    run.call(factory)
}

pub fn selftest() -> i32 {
    match run_selftest() {
        Ok((transcript, failures)) => {
            print!("{transcript}");
            failures as i32
        }
        Err(e) => {
            eprintln!("selftest harness error: {e}");
            2
        }
    }
}

/// The game's own gate, run once: (record, passed, checksum) for a
/// level id from the fixtures' reference solution.
fn game_gate_check(lua: &Lua, level_id: &str) -> LuaResult<(String, bool, String)> {
    let gate = require(lua, "gate")?;
    let levels = require(lua, "levels")?;
    let fixtures = require(lua, "fixtures")?;
    let mut level: Option<LuaTable> = None;
    for item in levels.sequence_values::<LuaTable>() {
        let item = item?;
        let id: String = item.get("id")?;
        if id == level_id {
            level = Some(item);
            break;
        }
    }
    let level = level.ok_or_else(|| LuaError::runtime(format!("no level {level_id}")))?;
    let fix: LuaTable = fixtures.get(level_id)?;
    let solution: String = fix.get("solution")?;
    let run: LuaFunction = gate.get("run")?;
    let (record, passed): (String, bool) = run.call((level, solution))?;
    let checksum_fn: LuaFunction = gate.get("checksum")?;
    let sum: String = checksum_fn.call(record.clone())?;
    Ok((record, passed, sum))
}

/// D-833 strand proof, production wiring: the spine verdict is the
/// game's own Domain 1 gate (Level 1's reference solution must pass
/// with the slice's recorded checksum 89ce2596) in this process's
/// Lua 5.5 state; the strand verdict comes from the separate LuaJIT
/// runner subprocess — two processes, because mlua's version
/// features are mutually exclusive per build. The runner's harness
/// runs interpreted (jit.off() law: LuaJIT count hooks die under
/// trace compilation).
pub fn strand_proof() -> i32 {
    let lua = match new_lua() {
        Ok(l) => l,
        Err(e) => {
            eprintln!("lua load failed: {e}");
            return 2;
        }
    };
    let (record, passed, sum) = match game_gate_check(&lua, "d1l1") {
        Ok(r) => r,
        Err(e) => {
            eprintln!("spine gate failed to run: {e}");
            return 2;
        }
    };
    let spine_pass = passed && sum == "89ce2596";
    println!(
        "### strand-proof spine (game gate d1l1, Lua 5.5 in-process) checksum={sum}\n{record}"
    );

    let runner = std::env::var("VERSEMEND_JITRUNNER").unwrap_or_else(|_| {
        let mut p = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("."));
        p.pop();
        p.push("versemend-jitrunner");
        p.to_string_lossy().to_string()
    });
    match std::process::Command::new(&runner).arg("solution").output() {
        Ok(out) => {
            let jitrec = String::from_utf8_lossy(&out.stdout);
            println!("### strand-proof strand (LuaJIT, subprocess {runner})\n{jitrec}");
            let jit_pass = out.status.success() && jitrec.contains("verdict PASS");
            println!(
                "STRAND-PROOF spine-5.5={} strand-luajit={} route=two-process",
                if spine_pass { "PASS" } else { "FAIL" },
                if jit_pass { "PASS" } else { "FAIL" }
            );
            if spine_pass && jit_pass {
                0
            } else {
                6
            }
        }
        Err(e) => {
            println!("STRAND-PROOF runner spawn FAILED: {e}");
            5
        }
    }
}

/// Runs the slice's screenshot walk against a real platform state,
/// returning (beat name, frame draw commands) pairs in walk order.
pub fn collect_shots(state: SharedPlat) -> LuaResult<ShotList> {
    let lua = new_lua()?;
    let platform = make_platform(&lua, state.clone())?;
    let factory = lua.create_table()?;
    factory.set(
        "new",
        lua.create_function(move |_, ()| Ok(platform.clone()))?,
    )?;
    let shots_log: Arc<Mutex<ShotList>> = Arc::new(Mutex::new(Vec::new()));
    let log = shots_log.clone();
    let st = state.clone();
    lua.globals().set(
        "HOST_SHOT",
        lua.create_function(move |_, name: String| {
            // Drain semantics: the beat's frame is everything drawn
            // since the previous beat. Intermediate renders inside a
            // click sequence composite correctly because every game
            // screen paints a full-screen base first (painter's
            // order), so the segment's final visual is the beat's.
            let frame = std::mem::take(&mut st.lock().unwrap().draws);
            log.lock().unwrap().push((name, frame));
            Ok(())
        })?,
    )?;
    let shots = require(&lua, "shots")?;
    let run: LuaFunction = shots.get("run")?;
    let _: bool = run.call(factory)?;
    let out = shots_log.lock().unwrap().clone();
    Ok(out)
}

// ---------------------------------------------------------------------------
// Bevy GUI — the platform's third implementation (play + screenshots)

use std::time::Instant;

use bevy::asset::UntypedHandle;
use bevy::audio::{AudioPlayer, PlaybackSettings};
use bevy::input::keyboard::{Key, KeyboardInput};
use bevy::input::touch::{TouchInput, TouchPhase};
use bevy::input::ButtonState;
use bevy::prelude::*;
use bevy::render::view::screenshot::{save_to_disk, Screenshot};
use bevy::ui::widget::NodeImageMode;
use bevy::window::PrimaryWindow;

pub const GAME_W: f32 = 1280.0;
pub const GAME_H: f32 = 800.0;

fn color_of(name: &str) -> Color {
    // The C host's palette, verbatim; an unknown name is magenta
    // there too — a visible bug report, not a silent default.
    let (r, g, b) = match name {
        "parchment" => (232, 213, 163),
        "amber" => (232, 166, 58),
        "ink" => (43, 36, 51),
        "ink_blue" => (46, 74, 110),
        "leaf" => (90, 122, 58),
        _ => (255, 0, 255),
    };
    Color::srgb_u8(r, g, b)
}

fn font_size_of(kind: &str) -> f32 {
    // The C host's TTF sizes for the same kinds.
    match kind {
        "title" => 42.0,
        "display" => 30.0,
        "body" | "body_bold" => 20.0,
        "code" => 17.0,
        "code_small" | "small" => 15.0,
        _ => 20.0,
    }
}

#[derive(Resource)]
struct Art {
    town: Handle<Image>,
    keeper: Handle<Image>,
    frame: Handle<Image>,
    font_title: Handle<Font>,
    font_display: Handle<Font>,
    font_body: Handle<Font>,
    font_body_bold: Handle<Font>,
    font_code: Handle<Font>,
    font_code_small: Handle<Font>,
    font_small: Handle<Font>,
    snd_bell: Handle<AudioSource>,
    snd_page: Handle<AudioSource>,
    snd_thud: Handle<AudioSource>,
    snd_lamp: Handle<AudioSource>,
}

impl Art {
    fn font_of(&self, kind: &str) -> Handle<Font> {
        match kind {
            "title" => self.font_title.clone(),
            "display" => self.font_display.clone(),
            "body_bold" => self.font_body_bold.clone(),
            "code" => self.font_code.clone(),
            "code_small" => self.font_code_small.clone(),
            "small" => self.font_small.clone(),
            _ => self.font_body.clone(),
        }
    }
    fn image_of(&self, name: &str) -> Option<Handle<Image>> {
        match name {
            "town" => Some(self.town.clone()),
            "keeper" => Some(self.keeper.clone()),
            "frame" => Some(self.frame.clone()),
            _ => None,
        }
    }
    fn sound_of(&self, name: &str) -> Option<Handle<AudioSource>> {
        match name {
            "bell" => Some(self.snd_bell.clone()),
            "page" => Some(self.snd_page.clone()),
            "thud" => Some(self.snd_thud.clone()),
            "lamp" => Some(self.snd_lamp.clone()),
            _ => None,
        }
    }
    fn visual_handles(&self) -> Vec<UntypedHandle> {
        vec![
            self.town.clone().untyped(),
            self.keeper.clone().untyped(),
            self.frame.clone().untyped(),
            self.font_title.clone().untyped(),
            self.font_display.clone().untyped(),
            self.font_body.clone().untyped(),
            self.font_body_bold.clone().untyped(),
            self.font_code.clone().untyped(),
            self.font_code_small.clone().untyped(),
            self.font_small.clone().untyped(),
        ]
    }
}

#[derive(Resource)]
struct GameRes {
    game: Game,
    plat: SharedPlat,
}

#[derive(Resource, Default)]
struct DrawRes {
    cmds: Vec<DrawCmd>,
    version: u64,
}

#[derive(Resource, Default)]
struct EventQueue(Vec<GameEvent>);

#[derive(Clone, Debug)]
enum GameEvent {
    Click { x: f32, y: f32 },
    Text(String),
    Key(String),
}

#[derive(Resource)]
struct Metrics {
    started: Instant,
    first_frame_done: bool,
}

#[derive(Resource)]
struct ShotPlayback {
    shots: Vec<(String, Vec<DrawCmd>)>,
    idx: usize,
    frames: u32,
    captured: bool,
    dir: PathBuf,
}

#[derive(Component)]
struct DrawRoot;

/// Game space -> window logical space: uniform scale, centered.
fn view_transform(win_w: f32, win_h: f32) -> (f32, f32, f32) {
    let s = (win_w / GAME_W).min(win_h / GAME_H);
    (s, (win_w - GAME_W * s) / 2.0, (win_h - GAME_H * s) / 2.0)
}

fn to_game(win: &Window, pos: Vec2) -> Vec2 {
    let (s, ox, oy) = view_transform(win.width(), win.height());
    Vec2::new((pos.x - ox) / s, (pos.y - oy) / s)
}

fn base_app() -> App {
    let mut app = App::new();
    app.add_plugins(DefaultPlugins.set(WindowPlugin {
        primary_window: Some(Window {
            title: "Versemend".to_string(),
            resolution: (1280u32, 800u32).into(),
            ime_enabled: true,
            ..default()
        }),
        ..default()
    }))
    .insert_resource(ClearColor(Color::srgb_u8(16, 18, 24)))
    .insert_resource(DrawRes::default())
    .insert_resource(EventQueue::default())
    .insert_resource(Metrics {
        started: Instant::now(),
        first_frame_done: false,
    })
    .add_systems(Startup, setup_art)
    .add_systems(
        Update,
        (
            input_mouse_touch,
            input_keyboard,
            game_tick,
            build_draws,
            metrics_system,
        )
            .chain(),
    );
    #[cfg(target_os = "android")]
    app.add_systems(Update, ime_text_sync.before(game_tick));
    app
}

fn setup_art(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn(Camera2d);
    commands.insert_resource(Art {
        town: asset_server.load("plate-town.png"),
        keeper: asset_server.load("keeper.png"),
        frame: asset_server.load("frame.png"),
        font_title: asset_server.load("fonts/LiberationSerif-Bold.ttf"),
        font_display: asset_server.load("fonts/LiberationSerif-Bold.ttf"),
        font_body: asset_server.load("fonts/LiberationSerif-Regular.ttf"),
        font_body_bold: asset_server.load("fonts/LiberationSerif-Bold.ttf"),
        font_code: asset_server.load("fonts/DejaVuSansMono.ttf"),
        font_code_small: asset_server.load("fonts/DejaVuSansMono.ttf"),
        font_small: asset_server.load("fonts/LiberationSerif-Regular.ttf"),
        snd_bell: asset_server.load("bell.wav"),
        snd_page: asset_server.load("page.wav"),
        snd_thud: asset_server.load("thud.wav"),
        snd_lamp: asset_server.load("lamp.wav"),
    });
}

pub fn run_app() {
    let plat: SharedPlat = Arc::new(Mutex::new(PlatState {
        save_path: Some(save_path()),
        ..Default::default()
    }));
    let mut app = base_app();
    let game = Game::new_with_plat(plat.clone()).expect("game loads");
    app.insert_resource(GameRes { game, plat });
    app.run();
}

pub fn run_screenshot_mode(dir: PathBuf) {
    let plat: SharedPlat = Arc::new(Mutex::new(PlatState::default()));
    let shots = collect_shots(plat).expect("screenshot walk runs");
    println!("SHOTS_COLLECTED {}", shots.len());
    let mut app = base_app();
    app.insert_resource(ShotPlayback {
        shots,
        idx: 0,
        frames: 0,
        captured: false,
        dir,
    });
    app.add_systems(Update, shot_driver.after(build_draws));
    app.run();
}

fn input_mouse_touch(
    mouse: Res<ButtonInput<MouseButton>>,
    mut touches: MessageReader<TouchInput>,
    windows: Query<&Window, With<PrimaryWindow>>,
    mut queue: ResMut<EventQueue>,
    playback: Option<Res<ShotPlayback>>,
) {
    if playback.is_some() {
        return;
    }
    let Ok(win) = windows.single() else { return };
    if mouse.just_pressed(MouseButton::Left) {
        if let Some(pos) = win.cursor_position() {
            let g = to_game(win, pos);
            queue.0.push(GameEvent::Click { x: g.x, y: g.y });
        }
    }
    for ev in touches.read() {
        if ev.phase == TouchPhase::Started {
            // Touch positions are logical window pixels (the spike's
            // finding); our UI lives in logical space too, so the
            // same transform as the mouse applies — no physical-pixel
            // conversion is needed or wanted here.
            let g = to_game(win, ev.position);
            queue.0.push(GameEvent::Click { x: g.x, y: g.y });
        }
    }
}

fn named_key(key: &Key) -> Option<&'static str> {
    match key {
        Key::Enter => Some("return"),
        Key::Backspace => Some("backspace"),
        Key::Delete => Some("delete"),
        Key::Tab => Some("tab"),
        Key::Escape => Some("escape"),
        Key::ArrowLeft => Some("left"),
        Key::ArrowRight => Some("right"),
        Key::ArrowUp => Some("up"),
        Key::ArrowDown => Some("down"),
        Key::Home => Some("home"),
        Key::End => Some("end"),
        Key::PageUp => Some("pageup"),
        Key::PageDown => Some("pagedown"),
        Key::F5 => Some("f5"),
        Key::Space => Some("space"),
        _ => None,
    }
}

fn input_keyboard(
    mut events: MessageReader<KeyboardInput>,
    mut queue: ResMut<EventQueue>,
    playback: Option<Res<ShotPlayback>>,
) {
    if playback.is_some() {
        return;
    }
    for ev in events.read() {
        if ev.state != ButtonState::Pressed {
            continue;
        }
        if let Some(name) = named_key(&ev.logical_key) {
            queue.0.push(GameEvent::Key(name.to_string()));
            // Space is both a named key (dialogue advance) and text
            // (the writing surface): the game routes each correctly.
            if name == "space" {
                queue.0.push(GameEvent::Text(" ".to_string()));
            }
            continue;
        }
        if let Some(text) = &ev.text {
            let s: &str = text;
            if !s.is_empty() && s.chars().all(|c| !c.is_control()) {
                queue.0.push(GameEvent::Text(s.to_string()));
            }
        }
    }
}

/// Android soft-keyboard text — the state-sync half of the IME
/// bridge. The show/hide half lives in game_tick (the game's own
/// set_text_input edge calls AndroidApp::show_soft_input).
///
/// Why polling: winit 0.30's Android backend never surfaces IME text
/// as window `Ime` events, and the GameActivity text protocol
/// (android-activity 0.6) is state-based, not event-based — the IME
/// edits a TextInputState the app owns (text + selection + composing
/// region), and the app reads it back with `text_input_state()`.
/// So while the writing surface is focused we poll that state each
/// tick and translate its delta into the game's own text/key
/// events: growth past the common prefix is inserted text, shrinkage
/// is backspaces. Composing text therefore appears live, suggestion
/// commits are no-ops (same text, region cleared), and autocorrect
/// rewrites map to backspace + retype at the caret — the same
/// contract a native edit field presents.
#[cfg(target_os = "android")]
fn ime_text_sync(
    game_res: Option<Res<GameRes>>,
    mut queue: ResMut<EventQueue>,
    mut shadow: Local<String>,
    mut active: Local<bool>,
) {
    let Some(game_res) = game_res else { return };
    let on = game_res.plat.lock().unwrap().text_input;
    let Some(app) = bevy_android::ANDROID_APP.get() else {
        return;
    };
    if on && !*active {
        *active = true;
        shadow.clear();
        app.set_text_input_state(android_activity::input::TextInputState {
            text: String::new(),
            selection: android_activity::input::TextSpan { start: 0, end: 0 },
            compose_region: None,
        });
    } else if !on && *active {
        *active = false;
        shadow.clear();
    }
    if !*active {
        return;
    }
    let state = app.text_input_state();
    if state.text != *shadow {
        let old: Vec<char> = shadow.chars().collect();
        let new: Vec<char> = state.text.chars().collect();
        let mut p = 0;
        while p < old.len() && p < new.len() && old[p] == new[p] {
            p += 1;
        }
        for _ in p..old.len() {
            queue.0.push(GameEvent::Key("backspace".to_string()));
        }
        if p < new.len() {
            let suffix: String = new[p..].iter().collect();
            queue.0.push(GameEvent::Text(suffix));
        }
        *shadow = state.text;
    }
}

fn game_tick(
    mut commands: Commands,
    game_res: Option<Res<GameRes>>,
    mut queue: ResMut<EventQueue>,
    mut draw: ResMut<DrawRes>,
    art: Option<Res<Art>>,
    mut last_text_input: Local<bool>,
    playback: Option<Res<ShotPlayback>>,
) {
    if playback.is_some() {
        return;
    }
    let Some(game_res) = game_res else { return };
    let game = &game_res.game;
    for ev in queue.0.drain(..) {
        let r = match &ev {
            GameEvent::Click { x, y } => game.event_click(*x, *y),
            GameEvent::Text(t) => game.event_text(t),
            GameEvent::Key(k) => game.event_key(k),
        };
        if let Err(e) = r {
            eprintln!("game event error: {e}");
        }
    }
    if let Err(e) = game.update(16) {
        eprintln!("game update error: {e}");
    }
    match render_frame(game, &game_res.plat) {
        Ok(cmds) => {
            if cmds != draw.cmds {
                draw.cmds = cmds;
                draw.version += 1;
            }
        }
        Err(e) => eprintln!("game render error: {e}"),
    }
    // Sound cues: fire-and-forget one-shots, as the C host's mixer
    // channels were. Verification is by cue log in headless modes —
    // the AUDIO SILENCE RULE governs all testing (null sink only).
    let sounds: Vec<String> = {
        let mut st = game_res.plat.lock().unwrap();
        std::mem::take(&mut st.sounds)
    };
    if let Some(art) = &art {
        for name in &sounds {
            if let Some(handle) = art.sound_of(name) {
                commands.spawn((AudioPlayer(handle), PlaybackSettings::ONCE));
            }
        }
    }
    // Text-input focus edges drive the Android IME bridge (D-861
    // Stage 2): the game's platform contract already says exactly
    // when the writing surface is focused — set_text_input(true) on
    // entering the editor, (false) on leaving it.
    let text_input = game_res.plat.lock().unwrap().text_input;
    if text_input != *last_text_input {
        *last_text_input = text_input;
        println!("TEXT_INPUT {}", if text_input { "on" } else { "off" });
        #[cfg(target_os = "android")]
        {
            if let Some(app) = bevy_android::ANDROID_APP.get() {
                if text_input {
                    app.show_soft_input(true);
                } else {
                    app.hide_soft_input(false);
                }
            }
        }
    }
}

fn build_draws(
    mut commands: Commands,
    draw: Res<DrawRes>,
    mut built: Local<u64>,
    roots: Query<Entity, With<DrawRoot>>,
    art: Option<Res<Art>>,
    windows: Query<&Window, With<PrimaryWindow>>,
) {
    if draw.version == *built {
        return;
    }
    let Some(art) = art else { return };
    let Ok(win) = windows.single() else { return };
    *built = draw.version;
    for e in &roots {
        commands.entity(e).despawn();
    }
    let (s, ox, oy) = view_transform(win.width(), win.height());
    let root = commands
        .spawn((
            DrawRoot,
            Node {
                position_type: PositionType::Absolute,
                left: Val::Px(0.0),
                top: Val::Px(0.0),
                width: Val::Percent(100.0),
                height: Val::Percent(100.0),
                ..default()
            },
        ))
        .id();
    let mut children: Vec<Entity> = Vec::with_capacity(draw.cmds.len());
    for cmd in &draw.cmds {
        let node = |x: f32, y: f32, w: f32, h: f32| Node {
            position_type: PositionType::Absolute,
            left: Val::Px(ox + x * s),
            top: Val::Px(oy + y * s),
            width: Val::Px(w * s),
            height: Val::Px(h * s),
            ..default()
        };
        let e = match cmd {
            DrawCmd::Rect {
                x,
                y,
                w,
                h,
                color,
                alpha,
            } => commands
                .spawn((
                    node(*x, *y, *w, *h),
                    BackgroundColor(color_of(color).with_alpha(*alpha / 255.0)),
                ))
                .id(),
            DrawCmd::Image {
                name,
                x,
                y,
                w,
                h,
                alpha,
            } => match art.image_of(name) {
                Some(handle) => {
                    // Stretch, not the default Auto: the platform
                    // contract is the C host's draw_image, which
                    // stretches the texture into the destination
                    // rect and ignores its aspect (the plates are
                    // 1280x1024 drawn into 1280x800). Auto would
                    // preserve aspect and letterbox the plate.
                    let mut img = ImageNode::new(handle);
                    img.color = Color::WHITE.with_alpha(*alpha / 255.0);
                    img.image_mode = NodeImageMode::Stretch;
                    commands.spawn((node(*x, *y, *w, *h), img)).id()
                }
                None => continue,
            },
            DrawCmd::Text {
                x,
                y,
                text,
                kind,
                color,
            } => {
                if text.is_empty() {
                    continue;
                }
                commands
                    .spawn((
                        Node {
                            position_type: PositionType::Absolute,
                            left: Val::Px(ox + x * s),
                            top: Val::Px(oy + y * s),
                            ..default()
                        },
                        Text::new(text.clone()),
                        TextFont {
                            font: art.font_of(kind).into(),
                            font_size: FontSize::Px(font_size_of(kind) * s),
                            ..default()
                        },
                        TextColor(color_of(color)),
                    ))
                    .id()
            }
        };
        children.push(e);
    }
    commands.entity(root).add_children(&children);
}

fn metrics_system(mut metrics: ResMut<Metrics>) {
    if metrics.first_frame_done {
        return;
    }
    metrics.first_frame_done = true;
    println!("FIRST_FRAME_MS {}", metrics.started.elapsed().as_millis());
}

fn shot_driver(
    mut commands: Commands,
    mut pb: ResMut<ShotPlayback>,
    mut draw: ResMut<DrawRes>,
    art: Option<Res<Art>>,
    asset_server: Res<AssetServer>,
    mut exit: MessageWriter<AppExit>,
) {
    if pb.idx >= pb.shots.len() {
        exit.write(AppExit::Success);
        return;
    }
    // Wait until every visual asset is resident: a screenshot taken
    // during streaming would show the plate-less frame, not the game.
    let Some(art) = art else { return };
    let ready = art.visual_handles().iter().all(|h| {
        matches!(
            asset_server.load_state(h.id()),
            bevy::asset::LoadState::Loaded
        )
    });
    if !ready {
        return;
    }
    let (name, cmds) = pb.shots[pb.idx].clone();
    if draw.cmds != cmds {
        draw.cmds = cmds;
        draw.version += 1;
    }
    pb.frames += 1;
    if pb.frames == 4 && !pb.captured {
        let path = pb.dir.join(format!("{name}.png"));
        commands
            .spawn(Screenshot::primary_window())
            .observe(save_to_disk(path));
        pb.captured = true;
    }
    let file = pb.dir.join(format!("{name}.png"));
    if pb.frames >= 8 && file.exists() {
        println!("SHOT_OK {name}");
        pb.idx += 1;
        pb.frames = 0;
        pb.captured = false;
    } else if pb.frames > 900 {
        eprintln!("SHOT_TIMEOUT {name}");
        pb.idx += 1;
        pb.frames = 0;
        pb.captured = false;
    }
}

/// Mobile entry point (Android `android_main` via `#[bevy_main]`).
#[cfg(target_os = "android")]
#[bevy_main]
pub fn main() {
    run_app();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn metrics_match_the_mock_platform() {
        assert_eq!(metrics_of("title"), (30.0, 64.0));
        assert_eq!(metrics_of("display"), (16.0, 38.0));
        assert_eq!(metrics_of("body"), (10.0, 26.0));
        assert_eq!(metrics_of("body_bold"), (10.0, 26.0));
        assert_eq!(metrics_of("code"), (11.0, 24.0));
        assert_eq!(metrics_of("code_small"), (9.0, 20.0));
        assert_eq!(metrics_of("small"), (8.0, 20.0));
    }

    /// The adoption gate in miniature: all eight gate records (six
    /// commissions, two bosses) reproduce inside this host's
    /// Lua 5.5 state, at their recorded checksums.
    #[test]
    fn slice_gate_records_reproduce() {
        let lua = new_lua().expect("lua loads");
        for (level, want) in [
            ("d1l1", "89ce2596"),
            ("d1l2", "157fd7ed"),
            ("d1l3", "6047aa34"),
            ("d2l1", "b04849ed"),
            ("d2l2", "5c1ac886"),
            ("d2l3", "2e51dccd"),
        ] {
            let (_, passed, sum) = game_gate_check(&lua, level).expect("gate runs");
            assert!(passed, "{level} solution must pass");
            assert_eq!(sum, want, "{level} checksum");
        }
        let gate = require(&lua, "gate").expect("gate module");
        let fixtures = require(&lua, "fixtures").expect("fixtures");
        for (module, act1_key, act2_key, want) in [
            ("boss", "boss_act1", "boss_act2", "d447229a"),
            ("boss2", "boss2_act1", "boss2_act2", "be96136b"),
        ] {
            let boss = require(&lua, module).expect("boss module");
            let a1: LuaTable = fixtures.get(act1_key).expect("act1");
            let a2: LuaTable = fixtures.get(act2_key).expect("act2");
            let srcs = lua.create_table().expect("srcs");
            srcs.set(1, a1.get::<String>("solution").expect("s1"))
                .expect("set1");
            srcs.set(2, a2.get::<String>("solution").expect("s2"))
                .expect("set2");
            let run: LuaFunction = gate.get("run").expect("run fn");
            let (record, passed): (String, bool) = run.call((boss, srcs)).expect("boss run");
            let checksum: LuaFunction = gate.get("checksum").expect("checksum fn");
            let sum: String = checksum.call(record).expect("boss checksum");
            assert!(passed, "{module} solution must pass");
            assert_eq!(sum, want, "{module} checksum");
        }
    }

    /// The full 147-check harness, in-process: zero failures and
    /// the unit checksums present in the transcript.
    #[test]
    fn selftest_transcript_is_clean() {
        let (transcript, failures) = run_selftest().expect("selftest runs");
        assert_eq!(failures, 0, "{transcript}");
        assert!(transcript.contains("SELFTEST failures 0"));
        for sum in [
            "89ce2596", "157fd7ed", "6047aa34", "d447229a", "b04849ed", "5c1ac886", "2e51dccd",
            "be96136b", "602d252b",
        ] {
            assert!(transcript.contains(sum), "missing {sum}");
        }
        let passes = transcript
            .lines()
            .filter(|l| l.starts_with("check ") && l.ends_with(" PASS"))
            .count();
        let fails = transcript
            .lines()
            .filter(|l| l.starts_with("check ") && l.ends_with(" FAIL"))
            .count();
        assert_eq!(passes, 147, "expected 147 check PASS lines, got {passes}");
        assert_eq!(fails, 0, "expected no check FAIL lines, got {fails}");
    }
}
