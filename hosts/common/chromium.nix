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
}
