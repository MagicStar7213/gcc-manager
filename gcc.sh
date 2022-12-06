#!/bin/bash
#############################################################################
####################### GCC Toolchain Manager Script ########################
#############################################################################

CERR='\033[0;31m'
CWARN='\033[1;33m\033[1m'
CNOTE='\033[1;36m\033[1m'
CPURP='\033[0;35m\033[1m'
CN='\033[0m'

BOLD='\033[1m'
ITAL='\033[3m'
UNDER='\033[4m'

GCC=
VERB=0

die() {
   echo -e '%s\n' "$1" >&2
   exit 1
}

help() {
   echo -e "${BOLD}GCC Toolchain Manager Script${CN}"
   echo
   echo 'Usage: gcc.sh [--gcc] [-h|--help; -i|--install; -u|--uninstall; -v|--version] [version]'
   echo
   echo "Options:"
   echo
   echo "   --gcc) Only installs compiler"
   echo
   echo "   -h|--help) Gives the current display"
   echo
   echo "   -i|--install) Installs the toolchain"
   echo
   echo "   -u|--uninstall) Uninstalls the toolchain"
   echo
   echo "   -V|--version) Displays script version"
   echo
   echo "   -v|--verbose) Enables all output"
   echo
   echo
   echo -e "${BOLD}Author: MagicStar7213${CN}"
}

toolinstall() {
   version=12.2.0
   bin=2.39
   linux=6.0.9
   libc=2.36
   PREFIX=/usr/local

   echo -e "${BOLD}GCC Toolchain Manager Script${CN}"
   echo
   if [ $GCC -eq 1 ]; then
      echo -e "| ${CNOTE}Downloading GCC...${CN} |"
      wget -nv https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.gz || die "${CERR}Downloading failed${CN}"
      echo -e "| ${CNOTE}Downloaded GCC successfully${CN} |"
      echo -e "| ${CNOTE}Extracting GCC...${CN} |"
      tar xzf gcc-$version.tar.gz
      echo -e "| ${CNOTE}Extracted GCC successfully${CN} |"
      cd gcc-$version
      echo -e "| ${CNOTE}Configuring GCC...${CN} |"
      ./configure $conf || die "${CERR}Configuring GCC failed${CN}"
      echo -e "| ${CNOTE}Configured GCC successfully${CN} |"
      echo -e "| ${CNOTE}Building GCC... ${CN} |"
      make -j$(nproc) || die "${CERR}Building failed"
      echo -e "| ${CNOTE}Built GCC successfully ${CN}|"
      echo -e "| ${CNOTE}Installing GCC...${CN} |"
      make install || die "${CERR}Installing failed${CN}"
      echo -e "| ${CNOTE}Installed GCC${CN} |"
      echo -e "${BOLD}GCC is installed${CN}"
      exit
   else
      start1=$SECONDS
      echo -e "| ${CNOTE}Downloading GCC Toolchain...${CN} |"
      wget -nv https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.gz
      wget -nv https://ftp.gnu.org/gnu/binutils/binutils-$bin/binutils-$bin.tar.gz
      wget -nv https://www.kernel.org/pub/linux/kernel/v6.x/linux-$linux.tar.xz
      wget -nv https://ftp.gnu.org/gnu/glibc/glibc-$libc/glibc-$libc.tar.gz
      echo -e "| ${CNOTE}Downloaded GCC Toolchain successfully${CN} |"
      echo -e "| ${CNOTE}Extracting GCC Toolchain...${CN} |"
      for f in *.tar*; do tar xf $f; done
      echo -e "| ${CNOTE}Extracted GCC Toolchain successfully${CN} |"
      echo -e "|  ${CNOTE}Buiding GCC Toolchain...${CN} |"
      start=$SECONDS
      mkdir -p build-binutils
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
      echo -e "${CPURP}linux-headers${CN}: Configuring..."
      make menuconfig || die "${CPURP}linux-headers${CN}: \033[0;31mConfiguring failed"
      echo -e "${CPURP}linux-headers${CN}: Configuring done"
      echo -e "${CPURP}linux-headers${CN}: Building and installing..."
      make ARCH=$MACHTYPE INSTALL_HDR_PATH=$PREFIX headers_install || die "${CPURP}linux-headers${CN}: \033[0;31mBuilding failed"
      echo -e "${CPURP}linux-headers${CN}: Building and installing done"
      cd ..
      duration=$(( SECONDS - start))
      echo -e "${CPURP}linux-headers${CN}: Done in ${duration}s"
      echo -e "${CG}gcc${CN}: Starting..."
      start=$SECONDS
      mkdir -p build-gcc
      cd build-gcc
      echo -e "${CG}gcc:${CN} Configuring..."
      ../gcc-$version/configure --enable-languages=c,c++ --disable-multilib || die "${CNOTE}gcc:${CN} \033[0;31mConfiguring failed"
      echo -e "${CG}gcc${CN}: Configuring done"
      echo -e "${CG}gcc${CN}: Building compiler..."
      if [ $(nproc) -le 4 ]; then
         make all-gcc || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
      else
         if [ $(nproc) -le 6 ]; then
            make all-gcc -j2 || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
         elif [ $(nproc) -le 10 ]; then
            make all-gcc -j4 || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
         else
            make all-gcc -j$(($(nproc) / 2)) || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
         fi
      fi
      echo -e "${CG}gcc${CN}: Building done"
      echo -e "${CG}gcc${CN}: Installing compiler..."
      make install-gcc || die "${CG}gcc${CN}: ${CERR}Installing failed${CN}"
      echo -e "${CG}gcc${CN}: Installing done"
      duration=$(( SECONDS - start ))
      echo -e "${CG}gcc${CN}: Done in ${duration}s"
      echo -e "${CERR}${BOLD}glibc${CN}: Starting..."
      start=$SECONDS
      mkdir -p build-glibc
      cd build-glibc
      echo -e "${CERR}${BOLD}glibc${CN}: Configuring..."
      ../glibc-2.36/configure --disable-multilib libc_cv_forced_unwind=yes
      echo -e "${CERR}${BOLD}glibc${CN}: Building and installing headers..."
      make install-bootstrap-headers=yes install-headers || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building and installing failed"
      echo -e "${CERR}${BOLD}glibc${CN}: Installing done"
      echo -e "${CERR}${BOLD}glibc${CN}: Building startup files..."
      if [ $(nproc) -le 4 ]; then
         make csu/subdir_lib || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed${CN}"
      else
         if [ $(nproc) -le 6 ]; then
            make csu/subdir_lib -j2 || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed${CN}"
         elif [ $(nproc) -le 10 ]; then
            make csu/subdir_lib -j4 || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed${CN}"
         else
            make csu/subdir_lib -j$(($(nproc) / 2)) || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
         fi
      fi
      echo -e "${CERR}${BOLD}glibc${CN}: Building startup files done"
      echo -e "${CERR}${BOLD}glibc${CN}: Installing startup files..."
      install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/lib || die "${CERROR}${BOLD}glibc${CN}: ${CERROR}Installing failed"
      echo -e "${CERR}${BOLD}glibc${CN}: Installing done"
      echo -e "${CERR}${BOLD}glibc${CN}: Building extra files..."
      gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/lib/libc.so || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
      touch $PREFIX/include/gnu/stubs.h || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
      echo -e "${CERR}${BOLD}glibc${CN}: Building extra files done"
      cd ..
      duration=$(( SECONDS - start ))
      echo -e "${CERR}${BOLD}glibc${CN}: Done in ${duration}s"
      echo -e "${CG}gcc${CN}: Libraries"
      start=$SECONDS
      cd build-gcc
      echo -e "${CG}gcc${CN}: Building libraries..."
      if [ $(nproc) -le 4 ]; then
         make all-target-libgcc || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
      else
         if [ $(nproc) -le 6 ]; then
            make all-target-libgcc -j2 || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
         elif [ $(nproc) -le 10 ]; then
            make all-target-libgcc -j4 || die "${CG}gcc${CN}: ${CERR}Building failed${CN}"
         else
            make all-target-libgcc -j$(($(nproc) / 2)) || die "${CG}gcc${CN}: ${CERR}Building failed"
         fi
      fi
      echo -e "${CG}gcc${CN}: Building libraries done"
      echo -e "${CG}gcc${CN}: Installing libraries.."
      make install-target-libgcc || die "${CG}gcc${CN}: ${CERR}Installing failed"
      echo -e "${CG}gcc${CN}: Installing done"
      duration=$(( SECONDS - start ))
      echo -e "${CG}gcc${CN}: Done in ${duration}s"
      cd ..
      echo -e "${CERR}${BOLD}glibc${CN}: Standard C Library"
      start=$SECONDS
      cd build-glibc
      echo -e "${CERR}${BOLD}glibc${CN}: Building C Library..."
      if [ $(nproc) -le 4 ]; then
         make || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
      else
         if [ $(nproc) -le 6 ]; then
            make -j2 || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
         elif [ $(nproc) -le 10 ]; then
            make -j4 || die "${CERR}${BOLD}glibc${CN}: ${CERR}Building failed"
         else
            make -j$(($(nproc) / 2)) || die "${CERR}${BOLD}glibc${CN}: ${CERROR}Building failed"
         fi
      fi
      echo -e "${CERR}${BOLD}glibc${CN}: Building C Library done"
      echo -e "${CERR}${BOLD}glibc${CN}: Installing C Library..."
      make install || die "${CERR}${BOLD}glibc${CN}: Installing failed"
      echo -e "${CERR}${BOLD}glibc${CN}: Installing C Library done"
      duration=$(( SECONDS - start ))
      echo -e "${CERR}${BOLD}glibc${CN}: Done in ${duration}s"
      cd ..
      duration1=$(( SECONDS - start1 ))
      echo -e "${BOLD}Done in ${duration1}s${CN}"
      echo -e "${BOLD} Complete GCC Toolchain installed${CN}"
   fi
}

while :; do
   case "$1" in
      --gcc)
         GCC=1;;
      -h | --help | -\?)
         help
         exit;;
      -i | --install)
         toolinstall
         exit;;
      -u | --uninstall)
         tooluninstall
         exit;;
      -v | --verbose)
         VERB=1;;
      -V | --version)
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
