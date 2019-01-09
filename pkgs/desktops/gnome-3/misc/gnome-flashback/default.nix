{ stdenv
, autoreconfHook
, bash
, fetchurl
, fetchpatch
, gettext
, glib
, gnome-bluetooth
, gnome-desktop
, gnome-flashback # for mkSessionForWm
, gnome-panel
, gnome-session
, gnome3
, gsettings-desktop-schemas
, gtk
, ibus
, intltool
, libcanberra-gtk3
, libpulseaudio
, libxkbfile
, libxml2
, pkgconfig
, polkit
, substituteAll
, upower
, wrapGAppsHook
, xkeyboard_config }:

let
  pname = "gnome-flashback";
  version = "3.28.0";
  requiredComponents = wmName: "RequiredComponents=${wmName};gnome-flashback-init;gnome-flashback;gnome-panel;org.gnome.SettingsDaemon.A11ySettings;org.gnome.SettingsDaemon.Clipboard;org.gnome.SettingsDaemon.Color;org.gnome.SettingsDaemon.Datetime;org.gnome.SettingsDaemon.Housekeeping;org.gnome.SettingsDaemon.Keyboard;org.gnome.SettingsDaemon.MediaKeys;org.gnome.SettingsDaemon.Mouse;org.gnome.SettingsDaemon.Power;org.gnome.SettingsDaemon.PrintNotifications;org.gnome.SettingsDaemon.Rfkill;org.gnome.SettingsDaemon.ScreensaverProxy;org.gnome.SettingsDaemon.Sharing;org.gnome.SettingsDaemon.Smartcard;org.gnome.SettingsDaemon.Sound;org.gnome.SettingsDaemon.Wacom;org.gnome.SettingsDaemon.XSettings;";
in stdenv.mkDerivation rec {
  name = "${pname}-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${name}.tar.xz";
    sha256 = "1ra8bfwgwqw47zx2h1q999g7l4dnqh7sv02if3zk8pkw3sm769hg";
  };

  patches =[
    # https://github.com/NixOS/nixpkgs/issues/36468
    # https://gitlab.gnome.org/GNOME/gnome-flashback/issues/3
    (fetchpatch {
      url = https://gitlab.gnome.org/GNOME/gnome-flashback/commit/eabd34f64adc43b8783920bd7a2177ce21f83fbc.patch;
      sha256 = "116c5zy8cp7d06mrsn943q7vj166086jzrfzfqg7yli14pmf9w1a";
    })
  ];

  postInstall = ''
    # Check that our expected RequiredComponents match the stock session files, but then don't install them.
    # They can be installed using mkSessionForWm.
    grep '${requiredComponents "metacity"}' $out/share/gnome-session/sessions/gnome-flashback-metacity.session || (echo "RequiredComponents have changed, please update gnome-flashback/default.nix."; false)

    rm -r $out/share/gnome-session
    rm -r $out/share/xsessions
    rm -r $out/libexec
  '';

  nativeBuildInputs = [
    autoreconfHook
    gettext
    libxml2
    pkgconfig
    wrapGAppsHook
  ];

  buildInputs = [
    glib
    gnome-bluetooth
    gnome-desktop
    gsettings-desktop-schemas
    gtk
    ibus
    libcanberra-gtk3
    libpulseaudio
    libxkbfile
    polkit
    upower
    xkeyboard_config
  ];

  doCheck = true;

  enableParallelBuilding = true;

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
      attrPath = "gnome3.${pname}";
    };

    mkSessionForWm = { wmName, wmLabel, wmCommand }: stdenv.mkDerivation {
      name = "gnome-flashback-${wmName}";

      buildCommand = ''
        mkdir -p $out/libexec
        cat << EOF > $out/libexec/gnome-flashback-${wmName}
        #!${bash}/bin/sh

        if [ -z \$XDG_CURRENT_DESKTOP ]; then
          export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"
        fi

        export XDG_DATA_DIRS=$out/share:${gnome-flashback}/share:${gnome-panel}/share:\$XDG_DATA_DIRS

        exec ${gnome-session}/bin/gnome-session --session=gnome-flashback-${wmName} "\$@"
        EOF
        chmod +x $out/libexec/gnome-flashback-${wmName}

        mkdir -p $out/share/gnome-session/sessions
        cat << 'EOF' > $out/share/gnome-session/sessions/gnome-flashback-${wmName}.session
        [GNOME Session]
        Name=GNOME Flashback (${wmLabel})
        ${requiredComponents wmName}
        EOF

        mkdir -p $out/share/applications
        cat << 'EOF' > $out/share/applications/${wmName}.desktop
        [Desktop Entry]
        Type=Application
        Encoding=UTF-8
        Name=${wmLabel}
        Exec=${wmCommand}
        NoDisplay=true
        X-GNOME-WMName=${wmLabel}
        X-GNOME-Autostart-Phase=WindowManager
        X-GNOME-Provides=windowmanager
        X-GNOME-Autostart-Notify=false
        EOF

        mkdir -p $out/share/xsessions
        cat << EOF > $out/share/xsessions/gnome-flashback-${wmName}.desktop
        [Desktop Entry]
        Name=GNOME Flashback (${wmLabel})
        Comment=This session logs you into GNOME Flashback with ${wmLabel}
        Exec=$out/libexec/gnome-flashback-${wmName}
        TryExec=${wmCommand}
        Type=Application
        DesktopNames=GNOME-Flashback;GNOME;
        EOF
      '';
    };
  };

  meta = with stdenv.lib; {
    description = "GNOME 2.x-like session for GNOME 3";
    homepage = https://wiki.gnome.org/Projects/GnomeFlashback;
    license = licenses.gpl2;
    maintainers = gnome3.maintainers;
    platforms = platforms.linux;
  };
}
