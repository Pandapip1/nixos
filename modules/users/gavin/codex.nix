{
  home-manager.sharedModules = [
(
{ pkgs, ... }:

{
  home.packages = [
    pkgs.codex
  ];

  home.file.".codex/config.toml".text = ''
    model = "qwen3-5-9b-q4-k-m"
    model_provider = "llamacpp"

    [model_providers.llamacpp]
    name = "llama.cpp"
    base_url = "http://[::1]:8480/v1"
    wire_api = "responses"
    requires_openai_auth = false

    [projects."/"]
    trust_level = "trusted"
  '';
}
)
  ];
}
