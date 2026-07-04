from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
SCREENSHOTS = DOCS / "assets" / "screenshots" / "candidates"
OUTPUT = DOCS / "captains-ui-library-guide.pdf"

PAGE_WIDTH, PAGE_HEIGHT = letter
MARGIN_X = 0.62 * inch
MARGIN_Y = 0.58 * inch
CONTENT_WIDTH = PAGE_WIDTH - (MARGIN_X * 2)

BG = colors.HexColor("#2b2b2b")
PANEL = colors.HexColor("#3a3a3a")
PANEL_DARK = colors.HexColor("#252525")
PANEL_LIGHT = colors.HexColor("#4a4a4a")
TEXT = colors.HexColor("#e8e8e8")
MUTED = colors.HexColor("#b8b8b8")
ACCENT = colors.HexColor("#ffd27a")
GREEN = colors.HexColor("#00d765")
LINE = colors.HexColor("#151515")


def make_styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=30,
            leading=34,
            textColor=ACCENT,
            alignment=TA_LEFT,
            spaceAfter=14,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=12,
            leading=17,
            textColor=TEXT,
            spaceAfter=20,
        ),
        "h1": ParagraphStyle(
            "h1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=18,
            leading=22,
            textColor=ACCENT,
            spaceBefore=10,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=17,
            textColor=TEXT,
            spaceBefore=8,
            spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.6,
            leading=14,
            textColor=TEXT,
            spaceAfter=7,
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.5,
            leading=12,
            textColor=MUTED,
            spaceAfter=5,
        ),
        "caption": ParagraphStyle(
            "caption",
            parent=base["BodyText"],
            fontName="Helvetica-Oblique",
            fontSize=8,
            leading=10,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceBefore=5,
            spaceAfter=6,
        ),
        "code": ParagraphStyle(
            "code",
            parent=base["Code"],
            fontName="Courier",
            fontSize=7.7,
            leading=10,
            textColor=colors.HexColor("#f0f0f0"),
        ),
        "toc": ParagraphStyle(
            "toc",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=15,
            textColor=TEXT,
            spaceAfter=5,
        ),
    }


STYLES = make_styles()


def page_bg(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG)
    canvas.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=1, stroke=0)
    canvas.setFillColor(colors.HexColor("#1b1b1b"))
    canvas.rect(0, PAGE_HEIGHT - 0.22 * inch, PAGE_WIDTH, 0.22 * inch, fill=1, stroke=0)
    canvas.rect(0, 0, PAGE_WIDTH, 0.22 * inch, fill=1, stroke=0)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(MARGIN_X, 0.12 * inch, "Captain's UI Library")
    canvas.drawRightString(PAGE_WIDTH - MARGIN_X, 0.12 * inch, f"Page {doc.page}")
    canvas.restoreState()


def p(text, style="body"):
    return Paragraph(text, STYLES[style])


def section(title):
    return p(title, "h1")


def subsection(title):
    return p(title, "h2")


def code_block(text):
    block = Preformatted(text.strip("\n"), STYLES["code"])
    return Table(
        [[block]],
        colWidths=[CONTENT_WIDTH],
        style=TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PANEL_DARK),
                ("BOX", (0, 0), (-1, -1), 1.0, LINE),
                ("INNERPADDING", (0, 0), (-1, -1), 8),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        ),
    )


def callout(title, body, accent=ACCENT):
    content = [
        p(title, "h2"),
        p(body, "body"),
    ]
    return Table(
        [[content]],
        colWidths=[CONTENT_WIDTH],
        style=TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PANEL),
                ("BOX", (0, 0), (-1, -1), 1.0, LINE),
                ("LINEBEFORE", (0, 0), (0, -1), 4, accent),
                ("INNERPADDING", (0, 0), (-1, -1), 9),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        ),
    )


def image_flowable(name, caption, max_width=CONTENT_WIDTH, max_height=4.8 * inch):
    path = SCREENSHOTS / name
    if not path.exists():
        return callout("Missing screenshot", f"Expected <b>{name}</b> in docs/assets/screenshots/candidates.", colors.red)

    with PILImage.open(path) as img:
        width, height = img.size

    box_width = min(max_width, CONTENT_WIDTH)
    scale = min(box_width / width, max_height / height)
    draw_width = width * scale
    draw_height = height * scale

    image = Image(str(path), width=draw_width, height=draw_height)
    image.hAlign = "CENTER"
    box = Table(
        [[image], [p(caption, "caption")]],
        colWidths=[box_width],
        style=TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PANEL_DARK),
                ("BOX", (0, 0), (-1, -1), 1, LINE),
                ("INNERPADDING", (0, 0), (-1, -1), 6),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ]
        ),
    )
    box.hAlign = "CENTER"
    return box


def two_column_images(left, left_caption, right, right_caption):
    col_width = (CONTENT_WIDTH - 10) / 2
    return Table(
        [
            [
                image_flowable(left, left_caption, col_width, 1.7 * inch),
                image_flowable(right, right_caption, col_width, 1.7 * inch),
            ]
        ],
        colWidths=[col_width, col_width],
        style=TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ]
        ),
    )


def bullet(items):
    rows = []
    for item in items:
        rows.append([p("+", "body"), p(item, "body")])
    return Table(
        rows,
        colWidths=[0.22 * inch, CONTENT_WIDTH - 0.22 * inch],
        style=TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("TEXTCOLOR", (0, 0), (0, -1), ACCENT),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 1),
            ]
        ),
    )


def build_story():
    story = []

    story.extend(
        [
            Spacer(1, 0.55 * inch),
            p("Captain's UI Library", "title"),
            p(
                "A practical guide for building native-looking Factorio 2.1 mod interfaces with reusable Lua helpers.",
                "subtitle",
            ),
            image_flowable(
                "full-editor-output-active.png",
                "Example editor with fulfilled conditions and active normal output.",
                max_height=5.7 * inch,
            ),
            Spacer(1, 8),
            callout(
                "Purpose",
                "This library helps mods render Factorio-style GUI sections, rows, controls, decider-like conditions, outputs, else outputs, and immediate visual feedback without each mod rebuilding the same foundation.",
                GREEN,
            ),
            PageBreak(),
            section("Contents"),
            p("1. Quick start", "toc"),
            p("2. Panel placement", "toc"),
            p("3. Core modules", "toc"),
            p("4. Decider editor state", "toc"),
            p("5. Rendering and events", "toc"),
            p("6. Conditions, outputs, and else outputs", "toc"),
            p("7. Evaluation, wires, and serialization", "toc"),
            p("8. Styling notes and screenshots", "toc"),
            Spacer(1, 10),
            callout(
                "Version target",
                "The guide assumes Factorio 2.1 and the current Captain's UI Library control-stage API.",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Quick Start"),
            p(
                "Add the UI library as a dependency, then require the public API from your mod's control stage.",
            ),
            code_block(
                """
local ui = require("__captainjhory-ui-library__.scripts.ui")
"""
            ),
            p(
                "For the decider editor, store one state table per player, entity, or editor instance. The UI should be rebuilt from that state whenever the player changes a value.",
            ),
            code_block(
                """
local state = ui.decider_state.new_state()

ui.decider_editor.add(parent_element, state, {
  red = {
    ["item/iron-ore/normal"] = 20,
  },
  green = {
    ["virtual/signal-S/normal"] = 1,
  },
})
"""
            ),
            callout(
                "Important",
                "The GUI is not the source of truth. The state table is. The GUI is only a visual rendering of state, plus tagged controls that tell event handlers what changed.",
                GREEN,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Panel Placement"),
            p(
                "The decider editor can be rendered anywhere a consuming mod can add GUI children. The library provides two frame helpers for the common cases: anchored relative panels and floating screen windows.",
            ),
            subsection("Relative to a native GUI"),
            p(
                "Use a relative panel when your UI should appear beside a supported Factorio window, such as a reactor, decider combinator, constant combinator, container, or the controller inventory.",
            ),
            code_block(
                """
ui.relative_panel.open_relative_panel(player, {
  name = "my_mod_reactor_panel",
  caption = { "my-mod.reactor-panel-title" },
  gui = defines.relative_gui_type.reactor_gui,
  position = defines.relative_gui_position.right,
}, function(frame)
  ui.decider_editor.add(frame, state, signal_values)
end)
"""
            ),
            subsection("Floating screen window"),
            p(
                "Use a floating panel when the editor should be its own draggable window. The helper creates a frame directly under player.gui.screen and auto-centers it unless you pass a location.",
            ),
            code_block(
                """
ui.relative_panel.open_floating_panel(player, {
  name = "my_mod_decider_window",
  caption = { "my-mod.decider-window-title" },
}, function(frame)
  ui.decider_editor.add(frame, state, signal_values)
end)
"""
            ),
            callout(
                "Rebuild behavior",
                "Both panel helpers destroy an existing frame with the same name before adding a fresh one. That makes immediate UI rebuilds predictable after tagged GUI events.",
                GREEN,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Core Modules"),
            bullet(
                [
                    "<b>scripts.ui</b>: public entry point that exports the library modules.",
                    "<b>decider_state</b>: creates, normalizes, evaluates, moves, and serializes editor state.",
                    "<b>decider_editor</b>: handles GUI events and mutates state based on element tags.",
                    "<b>components</b>: renders the native-looking rows, buttons, backgrounds, and sections.",
                    "<b>relative_panel</b>: opens panels relative to native game GUIs or as floating screen windows.",
                    "<b>mod_primitives</b>: small reusable styling/layout primitives.",
                ]
            ),
            subsection("Recommended ownership"),
            p(
                "A consuming mod should own its domain data. The library owns rendering helpers and generic editor state tools. When the player confirms, closes, or when your mod needs to run logic, serialize the editor state into your mod's own data shape.",
            ),
            code_block(
                """
local serialized = ui.decider_state.serialize_decider_editor(state)
-- Store or translate `serialized` into your mod's domain settings.
"""
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Decider Editor State"),
            p(
                "The editor state contains three row collections: conditions, outputs, and else_outputs. It also stores evaluated flags such as condition.fulfilled, output.fulfilled, and state.conditions_fulfilled.",
            ),
            code_block(
                """
local state = {
  conditions_fulfilled = false,
  conditions = { ... },
  outputs = { ... },
  else_outputs = { ... },
}
"""
            ),
            subsection("Normalization"),
            p(
                "Call normalize_state when reading old saved data or accepting partially-built tables. It fills missing defaults, ensures each section has at least one row, and protects the renderer from nil-heavy edge cases.",
            ),
            code_block(
                """
state = ui.decider_state.normalize_state(state)
"""
            ),
            image_flowable(
                "conditions-inactive.png",
                "A condition section with one inactive row and native-looking empty background slots.",
                max_height=3.1 * inch,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Rendering And Events"),
            p(
                "Build the visible editor from state. Controls use tags so event handlers can identify the section, row index, and field that changed.",
            ),
            code_block(
                """
ui.decider_editor.add(parent, state, signal_values)
"""
            ),
            p(
                "After a handled event changes the editor structure, destroy and rebuild the editor content. This keeps indexes, rows, dropdown choices, and selected signal values synchronized.",
            ),
            code_block(
                """
local changed = ui.decider_editor.handle_click(state, event)
if changed then
  rebuild_editor_for_player(player)
end
"""
            ),
            callout(
                "Why rebuild?",
                "Factorio GUI elements are not automatically bound to your Lua state. Rebuilding is the simple, reliable way to keep structural UI changes honest after add, remove, move, dropdown, text, or signal selection changes.",
            ),
            callout(
                "Signal slot editing",
                "Signal slots stay as native choose-element buttons, so players can pick a signal with one click and use Factorio's hover + Q copy behavior. The current resolved value is shown as a compact label inside the slot.",
                GREEN,
            ),
            subsection("Frequent value refresh"),
            p(
                "When only circuit values changed, do not rebuild. Refresh updates existing tagged GUI elements in place, so an open choose-element picker stays open.",
            ),
            code_block(
                """
ui.decider_editor.refresh(parent, state, signal_values)
"""
            ),
            two_column_images(
                "condition-inactive-row.png",
                "Inactive condition row.",
                "condition-fulfilled-row.png",
                "Fulfilled condition row.",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Conditions"),
            p(
                "A condition row compares a left signal value against either a constant or another signal. The left and right red/green checkboxes are separate input filters.",
            ),
            bullet(
                [
                    "<b>left_signal</b>: selected signal on the left side.",
                    "<b>comparator_index</b>: selected comparison operator.",
                    "<b>right_operand_type_index</b>: constant or signal.",
                    "<b>right_constant</b> or <b>right_signal</b>: right side value source.",
                    "<b>left_red_enabled</b> and <b>left_green_enabled</b>: left-side input wire filters.",
                    "<b>right_red_enabled</b> and <b>right_green_enabled</b>: right-side input wire filters.",
                    "<b>joiner</b>: and/or grouping with the previous row.",
                ]
            ),
            image_flowable(
                "conditions-joiners-mixed-fulfilled.png",
                "Joiners are placed between condition rows. Green rows are currently fulfilled.",
                max_height=3.8 * inch,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Outputs And Else Outputs"),
            p(
                "Outputs are active when the whole condition expression is true. Else outputs are active when it is false. Both row types share the same output data shape.",
            ),
            two_column_images(
                "output-inactive-row.png",
                "Inactive output row.",
                "output-active-row.png",
                "Active output row.",
            ),
            subsection("Output modes"),
            bullet(
                [
                    "<b>constant</b>: output the selected signal with the typed constant.",
                    "<b>input_count</b>: output the selected signal with the count read from enabled input wires.",
                ]
            ),
            image_flowable(
                "full-editor-else-active-and-conditions.png",
                "Example editor with else output active because the full condition expression is false.",
                max_height=5.8 * inch,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Evaluation"),
            p(
                "Pass signal values as separate red and green tables. The evaluator sums only the wire tables enabled by each row's checkboxes.",
            ),
            code_block(
                """
local signal_values = {
  red = {
    ["virtual/signal-T/normal"] = 500,
  },
  green = {
    ["item/uranium-fuel-cell/normal"] = 2,
  },
}

state = ui.decider_state.evaluate_decider_editor(state, signal_values)
"""
            ),
            callout(
                "Signal keys",
                "The evaluator accepts keys with quality, without quality, or with colon syntax. Prefer type/name/quality, for example item/iron-ore/normal.",
            ),
            subsection("AND and OR grouping"),
            p(
                "Consecutive AND rows form a group. OR starts a new group. The whole condition expression is true when any group is true.",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Serialization"),
            p(
                "Serialization converts editor state into a smaller data table that is easier for a consuming mod to store or translate into its own runtime logic.",
            ),
            code_block(
                """
local condition_data = ui.decider_state.serialize_condition(condition)
local output_data = ui.decider_state.serialize_output(output)
local editor_data = ui.decider_state.serialize_decider_editor(state)
"""
            ),
            p(
                "Use serialized data when your mod needs to save configuration, sync entity settings, or convert the editor into behavior. Do not use serialization just to render the UI; render from normalized editor state.",
            ),
            image_flowable(
                "full-editor-output-active.png",
                "Full editor overview with active normal output.",
                max_height=5.8 * inch,
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            section("Production Checklist"),
            bullet(
                [
                    "Keep state in <b>storage</b>, keyed by player, entity unit number, or your mod's editor id.",
                    "Normalize old state after migrations or when loading incomplete data.",
                    "Rebuild the editor immediately after meaningful GUI events.",
                    "Evaluate with current red and green signal tables before rendering fulfilled state.",
                    "Serialize only when handing data to your mod's own logic layer.",
                    "Use locale keys for visible text in public mods.",
                    "Keep the built-in demo disabled unless actively developing the library.",
                ]
            ),
            Spacer(1, 10),
            callout(
                "Design goal",
                "The best modded UI should feel like it belongs in Factorio. Match native spacing, use compact rows, keep controls immediate, and avoid apply buttons unless the native interaction would use one.",
                GREEN,
            ),
        ]
    )

    return story


def build_pdf():
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=letter,
        rightMargin=MARGIN_X,
        leftMargin=MARGIN_X,
        topMargin=MARGIN_Y,
        bottomMargin=MARGIN_Y,
        title="Captain's UI Library Guide",
        author="CaptainJhory",
    )
    doc.build(build_story(), onFirstPage=page_bg, onLaterPages=page_bg)


if __name__ == "__main__":
    build_pdf()
