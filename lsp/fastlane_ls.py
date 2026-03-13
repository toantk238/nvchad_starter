import asyncio
import json
import os
import re
import subprocess
from pathlib import Path

from lsprotocol import types
from pygls.server import LanguageServer

from utils.log import logger

env = os.environ.copy()
env["FASTLANE_DISABLE_COLORS"] = "1"

# Load static API data at module level
_DATA_PATH = Path(__file__).parent / "data" / "fastlane_api.json"
_API_DATA: dict = {}
try:
    with open(_DATA_PATH) as f:
        _API_DATA = json.load(f)
    logger.info(f"Loaded fastlane API data from {_DATA_PATH}")
except FileNotFoundError:
    logger.warning(
        f"fastlane API data not found at {_DATA_PATH}. "
        "Run scripts/generate_fastlane_data.rb to generate it."
    )
except Exception as e:
    logger.warning(f"Failed to load fastlane API data: {e}")

_ACTIONS_BY_NAME: dict = {a["name"]: a for a in _API_DATA.get("actions", [])}
_MODULES: dict = _API_DATA.get("modules", {})
_DSL_KEYWORDS: dict = {k["name"]: k for k in _API_DATA.get("dsl_keywords", [])}

server = LanguageServer("fastlane-ls", "v2")


def is_fastlane_file(uri: str) -> bool:
    path = uri.replace("file://", "")
    basename = os.path.basename(path)
    if basename in {"Fastfile", "Appfile", "Matchfile", "Pluginfile"}:
        return True
    if basename.endswith("Fastfile"):
        return True
    if "/fastlane/" in path:
        return True
    return False


def _word_range(line: str, pos_char: int) -> tuple[int, int]:
    """Return (start, end) character indices for the word at pos_char."""
    start = pos_char
    while start > 0 and (line[start - 1].isalnum() or line[start - 1] in "_!?"):
        start -= 1
    end = pos_char
    while end < len(line) and (line[end].isalnum() or line[end] in "_!?"):
        end += 1
    return start, end


def _detect_dot_prefix(line: str, pos_char: int) -> str | None:
    """Detect ModuleName. prefix before cursor, return module name if known."""
    before = line[:pos_char]
    m = re.search(r"([A-Z][a-zA-Z]*)\.[\w!?]*$", before)
    if m:
        module_name = m.group(1)
        if module_name in _MODULES:
            return module_name
    return None


def _detect_module_method(line: str, pos_char: int) -> tuple[str, str] | None:
    """Detect Module.method pattern at cursor, return (module, method) or None."""
    word_start, word_end = _word_range(line, pos_char)
    word = line[word_start:word_end]
    if word_start >= 2 and line[word_start - 1] == ".":
        m = re.search(r"([A-Z][a-zA-Z]*)$", line[: word_start - 1])
        if m:
            module_name = m.group(1)
            if module_name in _MODULES:
                return (module_name, word)
    return None


async def _run_fastlane_action_cli(word: str) -> str | None:
    """Run `fastlane action <word>` CLI and return extracted documentation."""
    try:
        result = await asyncio.to_thread(
            subprocess.run,
            ["fastlane", "action", word],
            capture_output=True,
            env=env,
            timeout=10,
        )
        if result.returncode != 0:
            return None
        stdout = result.stdout.decode("utf-8")
        if "Couldn't find action" in stdout:
            return None
        extracted = []
        started = False
        for line in stdout.splitlines():
            if "Loading documentation for" in line:
                started = True
            if "More information can be found" in line:
                break
            if started:
                extracted.append(line)
        content = "\n".join(extracted[1:])
        return content if content else None
    except Exception as e:
        logger.error(f"Error running fastlane action CLI: {e}")
        return None


@server.feature(
    types.TEXT_DOCUMENT_COMPLETION,
    types.CompletionOptions(trigger_characters=["."]),
)
async def completion(
    ls: LanguageServer, params: types.CompletionParams
) -> types.CompletionList:
    uri = params.text_document.uri
    if not is_fastlane_file(uri):
        return types.CompletionList(is_incomplete=False, items=[])

    document = ls.workspace.get_text_document(uri)
    pos = params.position
    line = document.lines[pos.line] if pos.line < len(document.lines) else ""
    items = []

    # Dot-completion context: return module-specific methods
    module_name = _detect_dot_prefix(line, pos.character)
    if module_name:
        for method in _MODULES.get(module_name, []):
            items.append(
                types.CompletionItem(
                    label=method["name"],
                    kind=types.CompletionItemKind.Method,
                    detail=method.get("signature", ""),
                    documentation=types.MarkupContent(
                        kind=types.MarkupKind.Markdown,
                        value=method.get("description", ""),
                    ),
                    insert_text=method["name"],
                )
            )
        return types.CompletionList(is_incomplete=False, items=items)

    # General completions: actions + DSL keywords + module names
    for action in _API_DATA.get("actions", []):
        items.append(
            types.CompletionItem(
                label=action["name"],
                kind=types.CompletionItemKind.Function,
                detail=(action.get("description") or "")[:80],
                documentation=types.MarkupContent(
                    kind=types.MarkupKind.Markdown,
                    value=action.get("description") or "",
                ),
                insert_text=action["name"],
            )
        )

    for kw in _API_DATA.get("dsl_keywords", []):
        items.append(
            types.CompletionItem(
                label=kw["name"],
                kind=types.CompletionItemKind.Keyword,
                detail=kw.get("description", ""),
                documentation=types.MarkupContent(
                    kind=types.MarkupKind.Markdown,
                    value=kw.get("description", ""),
                ),
                insert_text=kw.get("snippet", kw["name"]),
                insert_text_format=types.InsertTextFormat.Snippet,
            )
        )

    for mod_name in _MODULES:
        items.append(
            types.CompletionItem(
                label=mod_name,
                kind=types.CompletionItemKind.Module,
                detail=f"Fastlane {mod_name} module",
                insert_text=mod_name,
            )
        )

    return types.CompletionList(is_incomplete=False, items=items)


@server.feature(types.TEXT_DOCUMENT_HOVER)
async def hover(ls: LanguageServer, params: types.HoverParams) -> types.Hover | None:
    uri = params.text_document.uri
    if not is_fastlane_file(uri):
        return None

    document = ls.workspace.get_text_document(uri)
    pos = params.position

    try:
        word = document.word_at_position(pos)
    except IndexError:
        return None

    if not word:
        return None

    line = document.lines[pos.line] if pos.line < len(document.lines) else ""
    word_start, word_end = _word_range(line, pos.character)
    hover_range = types.Range(
        start=types.Position(line=pos.line, character=word_start),
        end=types.Position(line=pos.line, character=word_end),
    )

    # Priority 1: Module.method pattern
    mod_method = _detect_module_method(line, pos.character)
    if mod_method:
        module_name, method_name = mod_method
        for method in _MODULES.get(module_name, []):
            if method["name"] == method_name:
                md = f"## `{module_name}.{method_name}`\n\n"
                if method.get("signature"):
                    md += f"**Signature:** `{method['signature']}`\n\n"
                if method.get("description"):
                    md += method["description"]
                return types.Hover(
                    contents=types.MarkupContent(
                        kind=types.MarkupKind.Markdown, value=md
                    ),
                    range=hover_range,
                )

    # Priority 2: Static actions data
    if word in _ACTIONS_BY_NAME:
        action = _ACTIONS_BY_NAME[word]
        md = f"## `{action['name']}`\n\n"
        if action.get("description"):
            md += f"{action['description']}\n\n"
        if action.get("return_value"):
            md += f"**Returns:** {action['return_value']}\n\n"
        opts = action.get("options", [])[:10]
        if opts:
            md += "**Options:**\n\n"
            for opt in opts:
                opt_line = f"- `{opt['key']}`"
                if opt.get("description"):
                    opt_line += f": {opt['description']}"
                if not opt.get("optional", True):
                    opt_line += " *(required)*"
                md += opt_line + "\n"
        return types.Hover(
            contents=types.MarkupContent(kind=types.MarkupKind.Markdown, value=md),
            range=hover_range,
        )

    # Priority 3: DSL keywords
    if word in _DSL_KEYWORDS:
        kw = _DSL_KEYWORDS[word]
        md = f"## `{kw['name']}`\n\n{kw.get('description', '')}"
        if kw.get("snippet"):
            md += f"\n\n**Snippet:**\n```ruby\n{kw['snippet']}\n```"
        return types.Hover(
            contents=types.MarkupContent(kind=types.MarkupKind.Markdown, value=md),
            range=hover_range,
        )

    # Priority 4: Fallback to fastlane action CLI
    content = await _run_fastlane_action_cli(word)
    if content:
        return types.Hover(
            contents=types.MarkupContent(
                kind=types.MarkupKind.PlainText, value=content
            ),
            range=hover_range,
        )

    return None


def main():
    server.start_io()


if __name__ == "__main__":
    main()
