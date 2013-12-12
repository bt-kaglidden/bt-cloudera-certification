#! /bin/bash  -e

# This script installs RLP.
# Run this as root if you are installing RLP into a directory owned by root.

function usage { 
    echo 
    echo $0
    echo Purpose: Install RLP
    echo Usage:
    echo "    $0 -r BT_ROOT -s RLP_SDK -l RLP_LICENSE -e RLP_EXPANSION_PACK"
    echo Where: 
    echo "    BT_ROOT = directory in which to install RLP"
    echo "    RLP_SDK = RLP sdk archive (tar.gz file)"
    echo "    RLP_LICENSE = RLP license file (optional)"
    echo "    RLP_EXPANSION_PACK = RLP Language Expansion Pack (optional)"
    echo e.g. $0 -r /opt/rlp_7.10 -s rlp-7.10.0-sdk-amd64-glibc25-gcc41.tar.gz -l rlp-license.xml -e rlp-7.10.0-langpack-unix.tar.gz
    echo
}

rflag=false
sflag=false
lflag=false
eflag=false

options=':r:s:l:e:h'
while getopts $options option
do
    case $option in
        r  ) rflag=true; BT_ROOT=$OPTARG;;
        s  ) sflag=true; RLP_SDK=$OPTARG;;
        l  ) lflag=true; RLP_LICENSE=$OPTARG;;
        e  ) eflag=true; RLP_EXPANSION=$OPTARG;;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplimented option: -$OPTARG" >&2; exit 1;;
    esac
done

shift $(($OPTIND - 1))

if [ "$OPTIND" -eq "1" ]; then
    echo 
    echo Required arguments missing.
    usage
    exit 2
fi

if ! $rflag || ! $sflag; then
    echo 
    echo "-r and -s are required" >&2
    usage
    exit 3
fi

if [ -e $BT_ROOT ]; then
    echo 
    echo $BT_ROOT already exists. This script will not instal RLP into an existing directory.
    usage
    exit 4
else
    mkdir $BT_ROOT
fi

if [ ! -e $RLP_SDK ]; then
    echo 
    echo The RLP SDK, $RLP_SDK, does not exist.
    usage
    exit 5
else
    echo Installing sdk
    tar -C $BT_ROOT -xzf $RLP_SDK
fi


if [ "$RLP_LICENSE" ]; then
    if [ ! -e $RLP_LICENSE ]; then
        echo 
        echo The RLP license file, $RLP_LICENSE, does not exist.
        usage
        exit 6
    else
	echo Installing license
	cp -p $RLP_LICENSE $BT_ROOT/rlp/rlp/licenses
    fi
else
    echo "INFO: An RLP license was not specified.  You will need to install one here before you can use RLP:"
    echo "INFO:  $BT_ROOT/rlp/rlp/licenses"
fi

if [ "$RLP_EXPANSION" ]; then
    if [ ! -e $RLP_EXPANSION ]; then
        echo 
        echo The RLP language expansion pack, $RLP_EXPANSION, does not exist.
        usage
        exit 7
    else
	echo Installing expansion pack
        tar -C $BT_ROOT -xzf $RLP_EXPANSION
    fi
fi
