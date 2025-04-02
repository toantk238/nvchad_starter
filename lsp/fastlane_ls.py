from lsprotocol.types import (
    Hover,
    HoverParams,
    InitializeParams,
    InitializeResult,
    MarkupContent,
    MarkupKind,
    TextDocumentSyncKind,
)
from pygls.server import LanguageServer


class CustomLanguageServer(LanguageServer):
    CMD_HELLO_WORLD = 'helloWorld'

    def __init__(self):
        super().__init__('custom_lsp', 'v0.1')

    async def initialize(self, params: InitializeParams) -> InitializeResult:
        capabilities = {
            'textDocumentSync': TextDocumentSyncKind.Incremental,
            'hoverProvider': True,
        }
        return InitializeResult(capabilities=capabilities)


server = CustomLanguageServer()


@server.feature('textDocument/hover')
async def hover(self, params: HoverParams) -> Hover:
    # Provide hover information
    content = MarkupContent(kind=MarkupKind.PlainText, value="Hello from Custom LSP!")
    return Hover(contents=content)


def main():
    server.start_io()


if __name__ == '__main__':
    main()
