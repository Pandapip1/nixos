{ pkgs, ... }:

{
  # Configure installed packages
  environment.systemPackages = with pkgs; [
    chromium
  ];
  environment.gnome.excludePackages = with pkgs; [
    epiphany
  ];

  # Configure Chromium
  environment.etc."chromium/policies/managed/gnome_x11.json" = {
    text = builtins.toJSON {
      "ShowHomeButton" = false;
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
      "AutofillCreditCardEnabled" = false;
      "AutofillAddressEnabled" = false;
      "ImportAutofillFormData" = false;
      "ImportBookmarks" = false;
      "ImportHistory" = false;
      "ImportSavedPasswords" = false;
      "ImportSearchEngine" = false;
      "ImportHomepage" = false;
      "BrowserAddPersonEnabled" = false;
      "KerberosEnabled" = true;
      "BlockThirdPartyCookies" = true;
      "BookmarkBarEnabled" = true;
      "BrowserGuestModeEnabled" = false;
      "BrowserSignin" = false;
      "CredentialProviderPromoEnabled" = false;
      "DefaultBrowserSettingEnabled" = false; # Configured in NixOS
      "DesktopSharingHubEnabled" = false;
      "MetricsReportingEnabled" = false;
      "HistoryClustersVisible" = true;
      "InstantTetheringAllowed" = true;
      "NearbyShareAllowed" = false;
      "ParcelTrackingEnabled" = false;
      "PaymentMethodQueryEnabled" = false;
      "PdfAnnotationsEnabled" = true;
      "PostQuantumKeyAgreementEnabled" = true;
      "PromotionalTabsEnabled" = false;
      "PrivacyScreenEnabled" = false;
      "QuickAnswersEnabled" = false;
      "SafeBrowsingSurveysEnabled" = false;
      "ManagedAccountsSigninRestriction" = "primary_account_strict";
      "BrowsingDataLifetime" = [
        {
          "data_types" = [
            "browsing_history"
            "download_history"
            "password_signin"
            "autofill"
          ];
          "time_to_live_in_hours" = 24 * 7;
        }
      ];
      "HttpsOnlyMode" = "force_enabled";
      "HttpAllowlist" = [
        "gstatic.com"
      ];
      "BuiltInDnsClientEnabled" = false;
      "DnsOverHttpsMode" = "off";
      "ExtensionInstallForcelist" = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
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
  #home-manager = {
  #  sharedModules = [
  #    {
  #      
  #    }
  #  ];
  #};
  systemd.services.forceChromiumFlags = let 
    forceEnableFlags = builtins.toJSON [
      "customize-chrome-side-panel@1"
      "scrollable-tabstrip@1"
      "tab-groups-save@1"
    ];
  in {
    enable = true;
    description = "Forces Chromium to use certain flags";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ jq ];
    script = ''
      for userdir in /home/*; do
        user=$(basename "$userdir")
        local_state="/home/$user/.config/chromium/Local State"
        mkdir -p $(dirname "$local_state")
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
