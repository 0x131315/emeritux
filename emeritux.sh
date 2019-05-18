#!/bin/bash

# EMERITUX.SH

# This Bash script allows you to safely and easily download, install, update the GIT master version
# of Enlightenment 0.23 (aka E23) on Linux Mint Tessa; or helps you perform a clean uninstall
# of E23 GIT.

# To execute the script:

# First time.
# 1. Open Terminal and uncheck "Limit scrollback to" in Edit > Preferences > Scrolling
# 2. Change (cd) to the download folder
# 3. Make this script executable with chmod +x
# 3. Then type ./emeritux.sh

# Subsequent runs.
# Open Terminal and simply type emeritux.sh

# Heads up!
# Enlightenment programs installed from .deb packages or tarballs will inevitably conflict with
# E23 programs compiled from GIT source code——do not mix source code with pre-built binaries!
# Please remove thoroughly any previous installation of EFL/Enlightenment/E-Apps (track down
# and delete any leftover files) before running EMERITUX.SH.

# Once installed, you can update your Enlightenment desktop whenever you want to. However,
# because software gains entropy over time (performance regression, unexpected behavior...),
# I highly recommend doing a complete uninstall and reinstall of E23 every three weeks or so
# for an optimal user experience.

# Note that you need to uninstall all E23 GIT programs *before* upgrading your current system to
# a newer version of Linux Mint.

# EMERITUX.SH is written by similar@orange.fr, feel free to use this script as you see fit.
# Please consider sending me a tip via https://www.paypal.me/PJGuillaumie
# or starring this project to show your support.
# Cheers!

# Repositories and gists: https://github.com/batden
# Eyecandy for your Enlightenment desktop: https://extra.enlightenment.org/

# LOCAL VARIABLES
# ---------------

BLD="\e[1m"    # Bold text.
ITA="\e[3m"    # Italic text.
BDR="\e[1;31m" # Bold red text.
BDG="\e[1;32m" # Bold green text.
BDY="\e[1;33m" # Bold yellow text.
OFF="\e[0m"    # Turn off ANSI colors and formatting.

PREFIX=/usr/local
DLDIR=$(xdg-user-dir DOWNLOAD)
DOCDIR=$(xdg-user-dir DOCUMENTS)
ICNV=libiconv-1.15
MVER=0.50.0
E23=$DOCDIR/sources/enlightenment23
SCRFLR=$HOME/emeritux
CONFG="./configure --prefix=$PREFIX"
SNIN="sudo ninja -C build install"
RELEASE=$(lsb_release -sc)
DISTRIBUTOR=$(lsb_release -i | cut -f2)

# Build dependencies, recommended and script-related packages.
DEPS="aspell automake build-essential ccache check cmake cowsay \
doxygen faenza-icon-theme git imagemagick libasound2-dev \
libavahi-client-dev libblkid-dev libbluetooth-dev libbullet-dev \
libcogl-gles2-dev libexif-dev libfontconfig1-dev libfreetype6-dev \
libfribidi-dev libgeoclue-2-dev libgif-dev libcurl4-gnutls-dev \
libgnutls28-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libharfbuzz-dev libibus-1.0-dev libiconv-hook-dev libinput-dev \
libjpeg-dev libblkid-dev libluajit-5.1-dev liblz4-dev libmount-dev \
libopenjp2-7-dev libpam0g-dev libpoppler-cpp-dev libpoppler-dev \
libpoppler-private-dev libproxy-dev libpulse-dev libraw-dev \
librsvg2-dev libscim-dev libsndfile1-dev libspectre-dev libssl-dev \
libsystemd-dev libtiff5-dev libtool libudev-dev libudisks2-dev \
libunibreak-dev libunwind-dev libuv1-dev libvlc-dev libwebp-dev \
libxcb-keysyms1-dev libxcursor-dev libxine2-dev libxinerama-dev \
libxkbcommon-x11-dev libxkbfile-dev libxrandr-dev libxss-dev \
libxtst-dev linux-tools-common manpages-dev lolcat \
python3-setuptools python3-wheel texlive-base valgrind \
wmctrl xserver-xephyr xwayland"

# Programs from GIT repositories (latest source code).
CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
CLONE23="git clone https://git.enlightenment.org/core/enlightenment.git"
PROG_MN="efl enlightenment terminology"

# FUNCTIONS
# ---------

beep_attention() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
}

beep_question() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
}

beep_exit() {
  paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
}

beep_ok() {
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

sel_menu() {
  if [ $INPUT -lt 1 ]; then
    echo
    printf "1. $BDG%s $OFF%s\n\n" " Install Enlightenment 23 from git master"
    printf "2. $BDG%s $OFF%s\n\n" " Update and rebuild Enlightenment 23" # Best UX (recommended).
    printf "3. $BDY%s $OFF%s\n\n" " Update and rebuild E23 with Wayland support"
    printf "4. $BDR%s $OFF%s\n\n" " Uninstall all E23 git programs"

    sleep 1 && printf "$ITA%s $OFF%s\n\n" "Or press Ctrl+C to quit."
    read INPUT
  fi
}

bin_deps() {
  sudo apt update && sudo apt full-upgrade --yes

  # Backup list of currently installed packages (with a few exceptions).
  if [ ! -f $DOCDIR/installed_pkgs.txt ]; then
    apt-cache dumpavail >/tmp/apt-avail
    sudo dpkg --merge-avail /tmp/apt-avail
    rm /tmp/apt-avail
    dpkg --get-selections >$DOCDIR/installed_pkgs.txt
    sed -i '/linux-generic*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-headers*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-image*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-modules*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-image*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-signed*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-tools*/d' $DOCDIR/installed_pkgs.txt
  fi

  # Backup list of currently installed repositories.
  if [ ! -f $DOCDIR/installed_repos.txt ]; then
    grep -Erh ^deb /etc/apt/sources.list* >$DOCDIR/installed_repos.txt
  fi

  sudo apt install --yes $DEPS
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .DEB PACKAGES."
    printf "$BDR%s %s\n" "OR DPKG DATABASE IS LOCKED."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi
}

ls_dir() {
  COUNT=$(ls -d */ | wc -l)
  if [ $COUNT == 3 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
  elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s %s\n" "WARNING: ONLY $COUNT OF 3 PROGRAMS HAVE BEEN DOWNLOADED!"
    printf "\n$BDY%s $OFF%s\n\n" "WAIT 10 SECONDS OR HIT CTRL+C TO QUIT."
    sleep 10
  fi
}

mng_err() {
  printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
  beep_exit
  exit 1
}

chk_path() {
  if ! echo $PATH | grep -q $HOME/.local/bin; then
    echo -e '    export PATH=$HOME/.local/bin:$PATH' >>$HOME/.bash_aliases
    source $HOME/.bash_aliases
  fi
}

intl_lnk() {
  if [ $(uname -m) == x86_64 ]; then
    sudo ln -sf /usr/lib/x86_64-linux-gnu/preloadable_libintl.so /usr/lib/libgnuintl.so.8
    sudo ln -sf /usr/lib/x86_64-linux-gnu/preloadable_libintl.so /usr/lib/libintl.so
    sudo ldconfig
  elif [ $(uname -m) == i686 ]; then
    sudo ln -sf /usr/lib/i386-linux-gnu/preloadable_libintl.so /usr/lib/libintl.so.8
    sudo ln -sf /usr/lib/i386-linux-gnu/preloadable_libintl.so /usr/lib/libintl.so
    sudo ldconfig
  else
    printf "\n$BDR%s $OFF%s\n\n" "UNSUPPORTED ARCHITECTURE."
    beep_exit
    exit 1
  fi
}

elap_start() {
  START=$(date +%s)
}

elap_stop() {
  DELTA=$(($(date +%s) - $START))
  printf "\n%s" "Compilation time: "
  printf ""%dh:%dm:%ds"\n\n" $(($DELTA / 3600)) $(($DELTA % 3600 / 60)) $(($DELTA % 60))
}

build_optim() {
  which meson &>/dev/null || pip3 install --user meson==$MVER
  if [ "$?" -ne 0 ]; then
    printf "\n$BDR%s %s\n" "PIP INSTALL ERROR!"
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    chk_path
  fi

  beep_attention
  intl_lnk

  for I in $PROG_MN; do
    cd $E23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    case $I in
    efl)
      meson . build/
      meson configure -Dharfbuzz=true -Dbindings=luajit,cxx -Devas-loaders-disabler= \
        -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    enlightenment)
      meson . build/
      meson configure -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    *)
      meson . build/
      meson configure -Dbuildtype=release build/
      ninja -C build/ || true
      ;;
    esac

    beep_attention
    $SNIN || true
    sudo ldconfig
  done
}

rebuild_optim() {
  for I in $PROG_MN; do
    elap_start

    cd $E23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
    efl)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dharfbuzz=true -Dbindings=luajit,cxx -Devas-loaders-disabler= \
        -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    enlightenment)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    *)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dbuildtype=release build/
      ninja -C build/ || true
      ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

rebuild_wld() {
  for I in $PROG_MN; do
    elap_start

    cd $E23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
    efl)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dharfbuzz=true -Dbindings=luajit,cxx -Devas-loaders-disabler= \
        -Ddrm=true -Dwl=true -Dopengl=es-egl -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    enlightenment)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dwayland=true -Dbuildtype=release build/
      ninja -C build/ || mng_err
      ;;
    *)
      sudo chown $USER:$USER build/.ninja*
      meson configure -Dbuildtype=release build/
      ninja -C build/ || true
      ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

do_tests() {
  if [ -x /usr/bin/wmctrl ]; then
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi
  fi

  printf "\n\n$BLD%s $OFF%s\n" "SCANNING SYSTEM AND GIT REPOSITORIES..."
  sleep 1

  if systemd-detect-virt -q --container; then
    printf "\n$BDR%s %s\n" "EMERITUX.SH IS NOT INTENDED FOR USE INSIDE CONTAINERS."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi

  if [ $RELEASE == tessa ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Linux Mint ${RELEASE^}... OK"
    sleep 1
  else
    printf "\n$BDR%s $OFF%s\n\n" "UNSUPPORTED OPERATING SYSTEM [ $(lsb_release -d | cut -f2) ]."
    beep_exit
    exit 1
  fi

  if [ "$(pidof enlightenment)" ]; then
    printf "\n$BDR%s $OFF%s\n\n" "PLEASE LOG IN TO ${DISTRIBUTOR^^} TO EXECUTE THIS SCRIPT."
    beep_exit
    exit 1
  fi

  # Users of VirtualBox: Comment out the following lines if you get unexpected network errors.
  git ls-remote https://git.enlightenment.org/core/efl.git HEAD &>/dev/null
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER."
    printf "$BDR%s $OFF%s\n\n" "OR CHECK YOUR INTERNET CONNECTION."
    beep_exit
    exit 1
  fi

  if [ ! -d $SCRFLR ]; then
    printf "\n$BDR%s $OFF%s\n\n" "EMERITUX GIT FOLDER NOT FOUND!"
    beep_exit
    exit 1
  fi

  if [ ! -d $DOCDIR/sources/ ]; then
    mkdir -p $DOCDIR/sources/
  fi

  if [ ! -d $HOME/.local/bin/ ]; then
    mkdir -p $HOME/.local/bin/
  fi
}

do_bsh_alias() {
  if [ ! -f $HOME/.bash_aliases ]; then
    touch $HOME/.bash_aliases

    cat >$HOME/.bash_aliases <<EOF

    # GLOBAL VARIABLES
    # ----------------

    # Compiler and linker flags.
    export CC="ccache gcc"
    export CXX="ccache g++"
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    export CPPFLAGS=-I/usr/local/include
    export LDFLAGS=-L/usr/local/lib
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

    # This script adds the ~/.local/bin/ directory to your PATH environment variable if required.
EOF

    source $HOME/.bash_aliases
  fi
}

get_preq() {
  cd $DLDIR
  printf "\n\n$BLD%s $OFF%s\n\n" "Installing prerequisites..."
  wget -c https://ftp.gnu.org/pub/gnu/libiconv/$ICNV.tar.gz
  tar xzvf $ICNV.tar.gz -C $DOCDIR/sources/
  cd $DOCDIR/sources/$ICNV
  $CONFG
  make
  sudo make install
  sudo ldconfig
  rm -rf $DLDIR/$ICNV.tar.gz
  echo
}

get_meson() {
  if [ ! -d $HOME/.local/lib/python3.6/site-packages/mesonbuild/ ]; then
    sudo apt install --yes ninja-build python3-pip && pip3 install --user meson==$MVER
    if [ "$?" == 0 ]; then
      if ! echo $PATH | grep -q $HOME/.local/bin; then
        echo -e '    export PATH=$HOME/.local/bin:$PATH' >>$HOME/.bash_aliases
        source $HOME/.bash_aliases
      else
        true
      fi
    fi
  fi
}

install_now() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* INSTALLING ENLIGHTENMENT DESKTOP *"
  do_bsh_alias
  bin_deps

  if [ ! -f /usr/local/bin/iconv ]; then
    get_preq
  fi

  get_meson

  cd $HOME
  mkdir -p $E23
  cd $E23

  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching git code..."
  $CLONEFL
  echo
  $CLONETY
  echo
  $CLONE23
  echo

  ls_dir

  build_optim

  printf "\n%s\n\n" "Almost done..."

  mkdir -p $HOME/.elementary/themes/

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  gio set $SCRFLR metadata::custom-icon \
    file:///usr/share/icons/Mint-Y-Pink/places/48/folder.png

  gio set $DOCDIR/sources/ metadata::custom-icon \
    file:///usr/share/icons/Mint-Y-Pink/places/48/folder.png

  gio set $DOCDIR/sources/$ICNV metadata::custom-icon \
    file:///usr/share/icons/Mint-Y-Pink/places/48/folder.png

  sudo updatedb
  beep_ok

  printf "\n\n$BDY%s %s" "Enlightenment first time wizard tips:"
  printf "\n$BDY%s %s" "Update checking——you can disable this feature because it serves no useful purpose."
  printf "\n$BDY%s $OFF%s\n\n\n" "Network management support——do NOT install Connman!"
  # Enlightenment adds three shortcut icons (namely home.desktop, root.desktop and tmp.desktop)
  # to your Mint Desktop, you can safely delete them.

  echo
  cowsay "No Reboot Required... That's All Folks!" | lolcat -a
  echo

  cp -f $DLDIR/emeritux.sh $HOME/.local/bin/
}

update_go() {
  clear
  if [ ! -d $E23 ]; then
    printf "\n$BDR%s %s\n" "NOTHING TO UPDATE!"
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDG%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP *"
  fi

  cp -f $SCRFLR/emeritux.sh $HOME/.local/bin/
  chmod +x $HOME/.local/bin/emeritux.sh
  sleep 1

  printf "\n$BLD%s $OFF%s\n\n" "Satisfying dependencies under Linux Mint ${RELEASE^}..."
  bin_deps

  rebuild_optim

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok
  echo
  cowsay -f www "That's All Folks!"
  echo
}

wld_go() {
  clear
  if [ ! -d $E23 ]; then
    printf "\n$BDR%s %s\n" "NOTHING TO UPDATE!"
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP *"
  fi

  cp -f $SCRFLR/emeritux.sh $HOME/.local/bin/
  chmod +x $HOME/.local/bin/emeritux.sh
  sleep 1

  printf "\n$BLD%s $OFF%s\n\n" "Satisfying dependencies under Linux Mint ${RELEASE^}..."
  bin_deps

  rebuild_wld

  cd /usr/share/ && sudo rm -rf xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  if [ "$XDG_SESSION_TYPE" == "x11" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo
    cowsay -f www "Now log out of your existing session and press Ctrl+Alt+F2 to switch to tty2, \
        then enter your credentials and type: enlightenment_start" | lolcat -a
    echo
    # When you're done, type exit
    # Pressing Ctrl+Alt+F7 will bring you back to the login screen.
  else
    echo
    cowsay -f www "That's it. Now type: enlightenment_start"
    echo
  fi
}

remov_eprog_mn() {
  for I in $PROG_MN; do
    sudo ninja -C build/ uninstall
    rm -rf build/ &>/dev/null
  done
}

remov_preq() {
  if [ -d $DOCDIR/sources/$ICNV ]; then
    echo
    beep_question
    # Questions: Enter either y or n, or press Enter to accept the default values.
    read -t 12 -p "Remove libiconv installed from tarball? [Y/n] " answer
    case $answer in
    [yY])
      echo
      cd $DOCDIR/sources/$ICNV
      sudo make uninstall
      make maintainer-clean
      cd .. && rm -rf $DOCDIR/sources/$ICNV
      echo
      ;;
    [nN])
      printf "\n%s\n\n" "(do not remove libiconv... OK)"
      ;;
    *)
      echo
      cd $DOCDIR/sources/$ICNV
      sudo make uninstall
      make maintainer-clean
      cd .. && rm -rf $DOCDIR/sources/$ICNV
      echo
      ;;
    esac
  fi
}

remov_meson() {
  if [ -d $HOME/.local/lib/python3.6/site-packages/mesonbuild/ ]; then
    echo
    beep_question
    read -t 12 -p "Remove locally installed Meson? [y/N] " answer
    case $answer in
    [yY])
      echo
      pip3 uninstall meson
      echo
      ;;
    [nN])
      printf "\n%s\n\n" "(do not remove Meson... OK)"
      ;;
    *)
      printf "\n%s\n\n" "(do not remove Meson... OK)"
      ;;
    esac
  fi
}

# Think twice before proceeding with the removal of these packages,
# please review them carefully. If in doubt, take a screenshot
# first for future reference or keep the currently installed
# set of development packages.
remov_bin_deps() {
  if [ ! -d $HOME/.local/lib/python3.6/site-packages/mesonbuild/ ]; then
    echo
    beep_question
    read -t 12 -p "Remove binary dependencies (development packages)? [y/N] " answer
    case $answer in
    [yY])
      echo
      sudo apt autoremove $DEPS
      echo
      ;;
    [nN])
      printf "\n%s\n\n" "(keep the currently installed set of dev packages... OK)"
      ;;
    *)
      printf "\n%s\n\n" "(keep the currently installed set of dev packages... OK)"
      ;;
    esac
  fi
}

uninstall_e23() {
  clear
  printf "\n\n$BDR%s %s\n\n" "* UNINSTALLING ENLIGHTENMENT DESKTOP *"

  for I in $PROG_MN; do
    cd $E23/$I && remov_eprog_mn
  done

  cd $HOME
  rm -rf $E23
  rm -rf $SCRFLR
  rm -rf .e/
  rm -rf .elementary/
  rm -rf .cache/efreet/
  rm -rf .cache/evas_gl_common_caches//
  rm -rf .config/terminology/

  cd /usr/local/
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf efl*
  sudo rm -rf eio*
  sudo rm -rf eldbus*
  sudo rm -rf elementary*
  sudo rm -rf eo*
  sudo rm -rf evas*

  cd /usr/local/bin/
  sudo rm -rf efl*
  sudo rm -rf elua*
  sudo rm -rf eolian*
  sudo rm -rf emotion*
  sudo rm -rf evas*

  cd /usr/local/etc/
  sudo rm -rf enlightenment/

  cd /usr/local/include/
  sudo rm -rf *-1
  sudo rm -rf enlightenment/

  cd /usr/local/lib/
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf x86*
  sudo rm -rf i386*
  sudo rm -rf libecore*
  sudo rm -rf libector*
  sudo rm -rf libedje*
  sudo rm -rf libeet*
  sudo rm -rf libeeze*
  sudo rm -rf libefl*
  sudo rm -rf libefreet*
  sudo rm -rf libeina*
  sudo rm -rf libeio*
  sudo rm -rf libeldbus*
  sudo rm -rf libelementary*
  sudo rm -rf libelocation*
  sudo rm -rf libelput*
  sudo rm -rf libelua*
  sudo rm -rf libembryo*
  sudo rm -rf libemile*
  sudo rm -rf libemotion*
  sudo rm -rf libeo*
  sudo rm -rf libeolian*
  sudo rm -rf libephysics*
  sudo rm -rf libethumb*
  sudo rm -rf libevas*

  cd /usr/local/lib/pkgconfig/ &>/dev/null
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eet*
  sudo rm -rf efl*
  sudo rm -rf eina*
  sudo rm -rf eio*
  sudo rm -rf elementary*
  sudo rm -rf elput*
  sudo rm -rf elua*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf evas*

  cd /usr/local/lib/cmake/ &>/dev/null
  sudo rm -rf Ecore*
  sudo rm -rf Edje*
  sudo rm -rf Eet*
  sudo rm -rf Eeze*
  sudo rm -rf Efl*
  sudo rm -rf Efreet*
  sudo rm -rf Eina*
  sudo rm -rf Eio*
  sudo rm -rf Eldbus*
  sudo rm -rf Elementary*
  sudo rm -rf Elua*
  sudo rm -rf Emile*
  sudo rm -rf Emotion*
  sudo rm -rf Eo*
  sudo rm -rf Ethumb*
  sudo rm -rf Evas*

  cd /usr/local/share/
  sudo rm -rf dbus*
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf elua*
  sudo rm -rf embryo*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf terminology*
  sudo rm -rf wayland-sessions*

  cd /usr/local/share/applications/
  sudo sed -i '/enlightenment_filemanager/d' mimeinfo.cache

  cd /usr/local/share/icons/
  sudo rm -rf Enlightenment-X/
  sudo rm -rf elementary*
  sudo rm -rf terminology*

  cd /usr/share/
  sudo rm -rf xsessions/enlightenment.desktop &>/dev/null
  cd /usr/share/dbus-1/services/
  sudo rm -rf org.enlightenment.Ethumb.service

  cd $HOME

  find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I; do
    echo "$I" | xargs sudo rm -rf $(grep -E 'efl|enlightenment|terminology')
  done

  if [ -d $HOME/.ccache/ ]; then
    echo
    beep_question
    read -t 12 -p "Remove the hidden ccache folder (compiler cache)? [y/N] " answer
    case $answer in
    [yY])
      rm -rf $HOME/.ccache/
      ;;
    [nN])
      printf "\n%s\n\n" "(do not delete the ccache folder... OK)"
      ;;
    *)
      printf "\n%s\n\n" "(do not delete the ccache folder... OK)"
      ;;
    esac
  fi

  if [ -f $HOME/.bash_aliases ]; then
    echo
    beep_question
    read -t 12 -p "Remove the hidden bash_aliases file? [Y/n] " answer
    case $answer in
    [yY])
      rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
      ;;
    [nN])
      printf "\n%s\n\n" "(do not delete bash_aliases... OK)"
      ;;
    *)
      rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
      ;;
    esac
  fi

  remov_preq
  remov_meson
  remov_bin_deps

  mv $DOCDIR/installed_pkgs.txt $DOCDIR/inst_pkgs_bak.txt
  mv $DOCDIR/installed_repos.txt $DOCDIR/inst_repos_bak.txt

  sudo rm -rf /usr/lib/libgnuintl.so.8
  sudo rm -rf /usr/lib/libintl.so
  sudo ldconfig
  sudo updatedb
  echo
  # Candidates for deletion——run:
  # locate emeritux.sh
}

main() {
  trap '{ printf "\n$BDR%s $OFF%s\n\n" "KEYBOARD INTERRUPT."; exit 130; }' INT

  do_tests

  INPUT=0
  printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"
  sel_menu

  if [ $INPUT == 1 ]; then
    install_now
  elif [ $INPUT == 2 ]; then
    update_go
  elif [ $INPUT == 3 ]; then
    wld_go
  elif [ $INPUT == 4 ]; then
    uninstall_e23
  else
    beep_exit
    exit 1
  fi
}

main
