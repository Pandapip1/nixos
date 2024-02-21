{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Configure installed packages
  environment.systemPackages = with pkgs; [
    chromium
  ];
  environment.gnome.excludePackages = with pkgs; with pkgs.gnome; [
    epiphany
  ];

  # Configure Chromium
  environment.etc."chromium/policies/managed/gnome_x11.json" = {
    text = builtins.toJSON {
      "ShowHomeButton" = true;
      "DefaultSearchProviderEnabled" = true;
      "DefaultSearchProviderName" = "DuckDuckGo";
      "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}&ie={inputEncoding}";
      "DefaultSearchProviderSuggestURL" = "https://ac.duckduckgo.com/ac/?q={searchTerms}";
      "BlockExternalExtensions" = false;
      "PasswordManagerEnabled" = false;
      "HighEfficiencyModeEnabled" = true;
      "BatterySaverModeAvailability" = 1;
      "PrivacySandboxPromptEnabled" = false;
      "UserAgentReduction" = true;
      "HttpsUpgradesEnabled" = true;
      "HttpsOnlyMode" = "force_enabled";
      "HttpAllowlist" = [
        "gstatic.com"
      ];
      "BuiltInDnsClientEnabled" = false;
      "DnsOverHttpsMode" = "off";
      "ExtensionInstallForcelist" = [
        "ddkjiahejlhfcafbddmgiahcphecmpfh"
        "oboonakemofpalcgghocfoadofidjkkk"
        "nfcdcdoegfnidkeldipgmhbabmndlhbf"
        "mpbjkejclgfgadiemmefgebjfooflfhl"
        "icallnadddjmdinamnolclfjanhfoafe"
        "pfldomphmndnmmhhlbekfbafifkkpnbc"
        "nakplnnackehceedgkgkokbgbmfghain"
        "mhfjchmiaocbleapojmgnmjfcmanihio"
        "enamippconapkdmgfgjchkhakpfinmaj"
        "omkfmpieigblcllmkgbflkikinpkodlk"
        "gebbhagfogifgggkldgodflihgfeippi"
        "mnjggcdmjocbbbhaepdhchncahnbgone"
        "khncfooichmfjbepaaaebmommgaepoid"
      ];
    };
    mode = "0444";
  };

  # Force certain Chromium flags
  systemd.services.forceChromiumFlags = let 
    forceEnableFlags = builtins.toJSON [
      "customize-chrome-side-panel@1"
      "scrollable-tabstrip@1"
      "tab-groups-save@1"
    ];
  in {
    enable = true;
    description = "Forces Ungoogled Chromium to use certain flags";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ jq ];
    script = ''
      for userdir in /home/*; do
        user=$(basename "$userdir")
        local_state="/home/$user/.config/chromium/Local State"
        if [ -f /home/$user/.config/chromium/Local\ State ]; then
          echo -E "$(jq '.browser.enabled_labs_experiments |= (${forceEnableFlags} + . | unique)' "$local_state")" > "$local_state"
        else
          echo -E '{"browser": {"enabled_labs_experiments": ${forceEnableFlags}}}' > "$local_state"
        fi
      done
    '';
    serviceConfig.Restart="on-failure";
  };
}
