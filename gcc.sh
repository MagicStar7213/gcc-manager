#!/bin/bash
#############################################################################
####################### GCC Toolchain Manager Script ########################
#############################################################################

CERR='\033[1;31m\033[1m'
CWARN='\033[1;33m\033[1m'
CNOTE='\033[1;36m\033[1m'
CN='\033[0m'

BOLD='\033[1m'
ITAL='\033[3m'
UNDER='\033[4m'

die() {
   echo -e '%s\n' "$1" >&2
   exit 1
}

while :; do
   case $1 in
      -h | --help | -\?)
         help
         exit;;
      -i | --install)
         toolinstall
         exit;;
      -u | --uninstall)
         tooluninstall
         exit;;
      -v | --version)
         echo "1.0.0-a1"
         exit;;
      --)
         shift
         break;;
      -?*)
         echo -e "${CWARN}WARN${CN}: Unknown option (ignored)";;
      *)
         break;;
   esac
   shift
done

help() {
   echo -e "${BOLD}GCC Toolchain Manager Script${CN}"
   echo
   echo 'Script syntax: gcc.sh [-h|--help; -i|--install; -u|--uninstall; -v|--version] [version] [--prefix=prefix, --configure="options", --gcc]'
   echo
   echo "Options:"
   echo
   echo "   -h|--help) Gives the current display"
   echo
   echo "   -i|--install) Installs the toolchain"
   echo
   echo "   -u|--uninstall) Uninstalls the toolchain"
   echo
   echo "   -v|--version) Displays script version"
   echo
   echo
   echo -e "${BOLD}Author: MagicStar7213${CN}"
}

toolinstall() {
   GCC=0
   VERB=0
   conf=
   version=12.2.0
   binver=2.39
   linux=6.0.9
   libc=2.36
   while :; do
      case $@ in
         -v|--verbose)
            VERB=1;;
         --configure=?*)
            conf=${1#*=};;
         --configure=)
            echo -e "${CERR}ERROR${CN}: '--configure' requires a non-empty argument"
            exit 1;;
         --gcc)
            GCC=1;;
         --)
            shift
            break;;
         -?*)
            echo -e "${CWARN}WARN${CN}: Unknown option (ignored)";;
         *)
            break
      esac
      shift
   done

   echo -e "${BOLD}GCC Toolchain Manager Script${CN}"
   echo
   if [GCC = 1]; then
      echo -e "| ${CNOTE}Downloading GCC...${CN} |"
      wget -nv https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.gz
      echo -e "| ${CNOTE}Downloaded GCC successfully${CN} |"
      echo -e "| ${CNOTE}Extracting GCC...${CN} |"
      tar xzf gcc-$version.tar.gz
      echo -e "| ${CNOTE}Extracted GCC successfully${CN} |"
      cd gcc-$version
      echo -e "| ${CNOTE}Configuring GCC...${CN} |"
      ./configure $conf || die "| ${CERR}Configuring GCC failed${CN} |"
      echo -e "| ${CNOTE}Configured GCC successfully${CN} |"
      echo -e "| ${CNOTE}Building GCC... ${CN}(this will take some time) |"
      make -j$(nproc)
      echo -e "| ${CNOTE}Built GCC successfully ${CN}|"
      echo -e "| ${CNOTE}Installing GCC...${CN} |"
      make install
      echo -e "| ${CNOTE}Installed GCC${CN} |"
      echo -e "${BOLD}GCC is installed${CN}"
      exit
   else
      start1=$SECONDS
      echo -e "| ${CNOTE}Downloading GCC Toolchain...${CN} |"
      wget https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.gz
      wget https://ftp.gnu.org/gnu/binutils/binutils-$bin/binutils-$bin.tar.gz
      wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-$linux.tar.xz
      wget https://ftp.gnu.org/gnu/glibc/glibc-$libc/glibc-$libc.tar.gz
      echo -e "| ${CNOTE}Downloaded GCC Toolchain successfully${CN} |"
      echo -e "| ${CNOTE}Extracting GCC Toolchain...${CN} |"
      for f in *.tar*; do tar xf $f; done
      echo -e "| ${CNOTE}Extracted GCC Toolchain successfully${CN} |"
      echo -e "|  ${CN}(this will take some time) |"
      start=$SECONDS
      mkdir build-binutils
      cd build-binutils
      echo -e "${CNOTE}binutils${CN}: Configuring..."
      ../binutils-$bin/configure $conf --disable-multilib || die "${CNOTE}binutils${CN}: \033[1;31mConfiguring failed${CN}"
      echo -e "${CNOTE}binutils${CN}: Configuring done"
      echo -e "${CNOTE}binutils${CN}: Building..."
      make -j4 || die "${CNOTE}binutils${CN}: \033[0;31mBuilding failed${CN}"
      echo -e "${CNOTE}binutils${CN}: Building done"
      echo -e "${CNOTE}binutils${CN}: Installing..."
      make install || die "${CNOTE}binutils${CN}: \033[0;31mInstalling failed${CN}"
      echo -e "${CNOTE}binutils${CN}: Installing done"
      cd ..
      duration=$(( SECONDS - start ))
      echo -e "${CNOTE}binutils${CN}: Done in ${duration}s"
      start=$SECONDS
      cd linux-$linux
      echo -e "${CNOTE}linux-headers${CN}: Configuring..."
      make menuconfig || die "${CNOTE}linux-headers${CN}: \033[0;31mConfiguring failed"
      echo -e "${CNOTE}linux-headers${CN}: Configuring done"
      echo -e "${CNOTE}linux-headers${CN}: Building and installing..."
      make headers_install || die "${CNOTE}linux-headers${CN}: \033[0;31mBuilding failed"
      echo -e "${CNOTE}linux-headers${CN}: Building and installing done"
      cd ..
      duration=$(( SECONDS - start))
      echo -e "${CNOTE}linux-headers${CN}: Done in $duration"
      echo -e "${CNOTE}gcc${CN}: Starting..."
      start=$SECONDS
      mkdir -p build-gcc
      cd build-gcc
      echo -e "${CNOTE}gcc:${CN} Configuring..."
      ../gcc-$version/configure --enable-languages=c,c++ --disable-multilib || die "${CNOTE}gcc:${CN} \033[0;31mConfiguring failed"
      echo -e "${CNOTE}gcc${CN}: Configuring done"
      echo -e "${CNOTE}gcc${CN}: Building..."
      if [ $(nproc) -le 4 ]; then
         make all-gcc || die "${CNOTE}gcc:${CN} \033[0;31mBuilding failed${CN}"
      else
         if [ $(nproc) -le 6 ]; then
            make all-gcc -j2 || die "${CNOTE}gcc:${CN} \033[0;31mBuilding failed${CN}"
         elif [ $(nproc) -le 10 ]; then
            make all-gcc -j4 || die "${CNOTE}gcc:${CN} \033[0;31mBuilding failed${CN}"
         else
            make all-gcc -j$(($(nproc) / 2)) || die "${CNOTE}gcc:${CN} \033[0;31mBuilding failed${CN}"
         fi
      fi
      echo -e "${CNOTE}gcc${CN}: Building done"
      echo -e "${CNOTE}gcc${CN}: Installing..."
      make install-gcc || die "${CNOTE}gcc:${CN} \033[0;31mInstalling failed${CN}"
      echo -e "${CNOTE}gcc${CN}: Installing done"
      duration=$(( SECONDS - start))
      echo -e "${CNOTE}gcc${CN}: Done in $duration"
   fi
}