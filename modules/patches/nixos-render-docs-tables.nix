{ lib, ... }:

let
  # Built from plain "..." nix strings (not ''...''), so nix's automatic
  # common-indentation stripping can never reflow the Python whitespace
  # these depend on for correctness.
  initOld = "        self._font_stack = []";
  initNew = initOld + "\n        self._in_thead = False\n        self._table_col_idx = 0";

  textOld = "    def text(self, token: Token, tokens: Sequence[Token], i: int) -> str:\n        return man_escape(token.content)";
  textNew = "    def text(self, token: Token, tokens: Sequence[Token], i: int) -> str:\n        if self._in_thead:\n            return \"\"\n        return man_escape(token.content)";

  tailOld = "    def ordered_list_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:\n        self._list_stack.pop()\n        return \"\"\n";
  newMethods = lib.concatStringsSep "\n" [
    "    def table_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \".RS 4\""
    "    def table_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \".RE\""
    "    def thead_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        self._in_thead = True"
    "        return \"\""
    "    def thead_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        self._in_thead = False"
    "        return \"\""
    "    def tbody_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \"\""
    "    def tbody_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \"\""
    "    def tr_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        self._table_col_idx = 0"
    "        return \"\" if self._in_thead else \".PP\""
    "    def tr_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        if self._in_thead:"
    "            return \"\""
    "        if self._table_col_idx <= 1:"
    "            return \"\\\\fP\" if self._table_col_idx == 1 else \"\""
    "        return \".RE\""
    "    def _table_cell_open(self) -> str:"
    "        if self._in_thead:"
    "            return \"\""
    "        idx = self._table_col_idx"
    "        self._table_col_idx += 1"
    "        if idx == 0:"
    "            return \"\\\\fB\""
    "        elif idx == 1:"
    "            return \"\\\\fP\\n.RS 4\""
    "        else:"
    "            return \", \""
    "    def th_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return self._table_cell_open()"
    "    def th_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \"\""
    "    def td_open(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return self._table_cell_open()"
    "    def td_close(self, token: Token, tokens: Sequence[Token], i: int) -> str:"
    "        return \"\""
    ""
  ];
  tailNew = tailOld + newMethods;
in
{
  # nixos-render-docs' ManpageRenderer never implements the table_* /
  # thead_* / tr_* / th_* / tbody_* / td_* markdown-it tokens (only its
  # HTMLRenderer does), so any option description containing a Markdown
  # table crashes the "nixos-configuration-reference-manpage" build with
  # `RuntimeError: ('md token not supported', Token(type='table_open', ...))`.
  # nixos/lib/utils.nix's mkStateRevisionOption (used by services.seerr,
  # among others) generates exactly such a table, so this now breaks
  # building the reference manpage for any configuration, whether or not
  # services.seerr is used, since the manpage documents every option.
  #
  # Render tables the same way a two-column key/description list would
  # read: the first cell in each row becomes a bold "term", the rest are
  # joined after it. Header rows are dropped since they're just column
  # labels, not content.
  # TODO: Report upstream
  nixpkgs.overlays = [
    (_: prev: {
      nixos-render-docs = prev.nixos-render-docs.overrideAttrs (old: {
        postPatch = ''
          ${old.postPatch or ""}
          substituteInPlace nixos_render_docs/manpage.py \
            --replace-fail ${lib.escapeShellArg initOld} ${lib.escapeShellArg initNew}
          substituteInPlace nixos_render_docs/manpage.py \
            --replace-fail ${lib.escapeShellArg textOld} ${lib.escapeShellArg textNew}
          substituteInPlace nixos_render_docs/manpage.py \
            --replace-fail ${lib.escapeShellArg tailOld} ${lib.escapeShellArg tailNew}
        '';
      });
    })
  ];
}
