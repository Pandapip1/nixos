{ lib, pkgs, ... }:

let
  fetchModel = {
    repoId,
    rev,
    hash,
  }:
    pkgs.fetchFromHuggingFace {
      inherit repoId rev hash;
      backend = "lfs";
    };

  models = {
    qwen3-5-9b-q4-k-m = {
      repoId = "bartowski/Qwen_Qwen3.5-9B-GGUF";
      rev = "182be2fd6c7bc44887d88a91cb03ff009cc9f549";
      file = "Qwen_Qwen3.5-9B-Q4_K_M.gguf";
      hash = "sha256-14TOntoaWntR6PcFqeYxCES/Txc2VNEVgjx3X96lbUM=";

      settings.ctx-size = "57344";

      patches = [
        ./qwen3.5-developer.patch
      ];
    };
  };

  ggufPython = pkgs.python3.withPackages (ps: [
    ps.gguf
  ]);

  mkChatTemplate =
    {
      model,
      patches ? [ ],
    }:
    pkgs.runCommand "chat-template" {
      nativeBuildInputs = [
        ggufPython
        pkgs.patch
      ];

      patchInputs = patches;
    } ''
      python - "${model}" "$TMPDIR/template.jinja" <<'PY'
      import sys
      from gguf import GGUFReader

      model = sys.argv[1]
      output = sys.argv[2]

      reader = GGUFReader(model)
      field = reader.get_field("tokenizer.chat_template")

      if field is None:
          raise SystemExit("GGUF does not contain tokenizer.chat_template")

      template = field.contents()

      if not isinstance(template, str):
          raise TypeError(
              f"tokenizer.chat_template has unexpected type: "
              f"{type(template).__name__}"
          )

      with open(output, "w", encoding="utf-8") as f:
          f.write(template)
      PY

      ${lib.concatMapStringsSep "\n" (
        patch:
        ''
          patch "$TMPDIR/template.jinja" < ${patch}
        ''
      ) patches}

      cp "$TMPDIR/template.jinja" "$out"
    '';

  modelsIni = pkgs.writeText "llama-models.ini" (
    ''
      version = 1

      [*]
      n-gpu-layers = 999
      jinja = true

    ''
    + builtins.concatStringsSep "\n" (
      lib.mapAttrsToList
        (alias: model:
          let
            modelFile = pkgs.fetchurl {
              url = "https://huggingface.co/${model.repoId}/resolve/${model.rev}/${model.file}";
              inherit (model) hash;
            };

            template =
              if model ? patches
              then mkChatTemplate {
                model = modelFile;
                patches = model.patches;
              }
              else null;
          in
          ''
            [${alias}]
            model = ${modelFile}
            ${lib.optionalString (template != null) "chat-template-file = ${template}"}
            ctx-size = ${model.settings.ctx-size}
          ''
        )
        models
    )
  );
in
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;

    settings = {
      host = "::1";
      port = 8480;

      models-preset = modelsIni;

      models-max = 1;
      models-autoload = true;

    verbosity = 5;
    };
  };
}
