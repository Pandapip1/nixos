{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

let
  extensionInstallForcelist = [
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
in
{
  # Configure installed packages
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
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
      "ExtensionInstallForcelist" = extensionInstallForcelist;
    };
    mode = "0444";
  };
  systemd.services.forceChromiumFlags = {
    enable = true;
    description = "Forces Ungoogled Chromium to use certain flags";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ jq ];
    script = ''
      for userdir in /home/*; do
        user=$(basename "$userdir")
        local_state="/home/$user/.config/chromium/Local State"
        if [ -f /home/$user/.config/chromium/Local\ State ]; then
          echo -E "$(jq '.browser.enabled_labs_experiments |= (["extension-mime-request-handling@2"] + . | unique)' "$local_state")" > "$local_state"
        else
          echo -E '{"browser": {"enabled_labs_experiments": ["extension-mime-request-handling@2"]}}' > "$local_state"
        fi
      done
    '';
    serviceConfig.Restart="on-failure";
  };
  systemd.services.installChromeExtensions = {
    enable = true;
    description = "Automatically fetch Chrome extensions";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ curl unzip jq ];
    script = builtins.concatStringsSep "\n" ([ "rm -rf /usr/share/chromium/extensions" "mkdir -p /usr/share/chromium/extensions" ] ++ (map (ext: ''
      mkdir -p /usr/share/chromium/extensions/${ext}
      curl -L -o "/usr/share/chromium/extensions/${ext}.crx" "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=121.0.6167.184&acceptformat=crx2,crx3&x=id%3D${ext}%26uc"
      unzip /usr/share/chromium/extensions/${ext}.crx -d /usr/share/chromium/extensions/${ext}
      echo -E '{"external_crx": "/usr/share/chromium/extensions/${ext}.crx", "external_version": "$(jq -r ".version" ${ext}/manifest.json)"}' > "/usr/share/chromium/extensions/${ext}.json"
      rm -rf /usr/share/chromium/extensions/${ext}
    '') extensionInstallForcelist));
    serviceConfig.Restart="on-failure";
  };
}
