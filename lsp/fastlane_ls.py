import os
import subprocess

from lsprotocol import types
from pygls.server import LanguageServer

from utils.log import logger

env = os.environ.copy()
env["FASTLANE_DISABLE_COLORS"] = "1"


DATE_FORMATS = [
    "%H:%M:%S",
    "%d/%m/%y",
    "%Y-%m-%d",
    "%Y-%m-%dT%H:%M:%S",
]
server = LanguageServer("hover-server", "v1")


@server.feature(types.TEXT_DOCUMENT_HOVER)
async def hover(ls: LanguageServer, params: types.HoverParams) -> types.Hover:
    pos = params.position
    document_uri = params.text_document.uri
    if not document_uri.endswith("Fastfile"):
        return None

    document = ls.workspace.get_text_document(document_uri)
    logger.info(f"pos = {pos}")
    word = ""

    try:
        word = document.word_at_position(pos)
    except IndexError:
        return None

    # for fmt in DATE_FORMATS:
    #     try:
    #         value = datetime.strptime(line.strip(), fmt)
    #         break
    #     except ValueError:
    #         pass
    #
    # else:
    #     # No valid datetime found.
    #     return None

    # hover_content = [
    #     f"# {value.strftime('%a %d %b %Y')}",
    #     "",
    #     "| Format | Value |",
    #     "|:-|-:|",
    #     *[f"| `{fmt}` | {value.strftime(fmt)} |" for fmt in DATE_FORMATS],
    # ]
    if not word:
        return None
    doc = subprocess.Popen(
        ["fastlane", "action", word],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env
    )

    # Capture the stdout and stderr
    stdout, stderr = doc.communicate()

    # Check for errors
    if doc.returncode != 0 or stderr:
        error_message = stderr.decode('utf-8')
        logger.error(f"Error executing fastlane action: {error_message}")
        return None

    # Decode the stdout to a string
    stdout_decoded = stdout.decode('utf-8')

    if "Couldn't find action" in stdout_decoded:
        logger.error(f"Couldn't find action: {word}")
        return None

    # Initialize variables for extraction
    extracted_lines = []
    start_extraction = False

    # Split the output into lines and iterate
    for line in stdout_decoded.splitlines():
        if "Loading documentation for" in line:
            start_extraction = True
        if "More information can be found" in line:
            break
        if start_extraction:
            extracted_lines.append(line)

    # Join the extracted lines into a single string
    extracted_content = "\n".join(extracted_lines[1:])

    # Check if no content was extracted
    if not extracted_content:
        logger.error(f"No documentation found for action: {word}")
        return None

    logger.info(f"stdout_decoded = {extracted_content}")

    return types.Hover(
        contents=types.MarkupContent(
            kind=types.MarkupKind.PlainText,
            value=extracted_content,
        ),
        range=types.Range(
            start=types.Position(line=pos.line, character=0),
            end=types.Position(line=pos.line + 1, character=0),
        ),
    )


def main():
    server.start_io()


if __name__ == '__main__':
    main()
