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

      settings.ctx-size = "262144";
    };
  };

  modelsIni = pkgs.writeText "llama-models.ini" (
    ''
      version = 1

      [*]
      n-gpu-layers = 999
      jinja = true

    ''
    + builtins.concatStringsSep "\n" (
      lib.mapAttrsToList
        (alias: model: ''
          [${alias}]
          model = ${pkgs.fetchurl { url = "https://huggingface.co/${model.repoId}/resolve/${model.rev}/${model.file}"; inherit (model) hash; }}
          ctx-size = ${model.settings.ctx-size}
        '')
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
    };
  };
}
