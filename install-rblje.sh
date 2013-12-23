#! /bin/bash  -e

# This script installs RBL-JE.

function usage { 
    echo 
    echo $0
    echo Purpose: Install RBL-JE
    echo Usage:
    echo "    $0 -r RBLJE_ROOT -s RBLJE_SDK -l RBLJE_LICENSE"
    echo Where: 
    echo "    RBLJE_ROOT = directory in which to install RBL-JE"
    echo "    RBLJE_SDK = RLP sdk archive (tar.gz file)"
    echo "    RBLJE_LICENSE = RLP license file (optional)"
    echo e.g. $0 -r /opt/rblje-2.1.0 -s rbl-distribution-2.1.0.zip -l rlp-license.xml
    echo
}

rflag=false
sflag=false
lflag=false

options=':r:s:l:h'
while getopts $options option
do
    case $option in
        h  ) usage; exit;;
        l  ) lflag=true; RBLJE_LICENSE=$OPTARG;;
        r  ) rflag=true; RBLJE_ROOT=$OPTARG;;
        s  ) sflag=true; RBLJE_SDK=$OPTARG;;
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
    echo "The -r and -s flags are required" >&2
    usage
    exit 3
fi

if [ ! -e $RBLJE_SDK ]; then
    echo 
    echo The RLP SDK, $RBLJE_SDK, does not exist.
    usage
    exit 5
fi

if [ "$RBLJE_LICENSE" ]; then
    if [ ! -e $RBLJE_LICENSE ]; then
        echo 
        echo The license file, $RBLJE_LICENSE, does not exist.
        usage
        exit 6
    fi
fi

if [ -e $RBLJE_ROOT ]; then
    echo 
    echo $RBLJE_ROOT already exists. This script will not instal RLP into an existing directory.
    usage
    exit 4
else
    mkdir $RBLJE_ROOT
fi

echo Installing sdk
unzip -d $RBLJE_ROOT $RBLJE_SDK

LICENSE_DIR=`find $RBLJE_ROOT -name licenses`
if [ "$RBLJE_LICENSE" ]; then
    echo Installing license
    cp -p $RBLJE_LICENSE $LICENSE_DIR
else
    echo "INFO: A license file was not specified.  You will need to install one here before you can use RBL-JE:"
    echo "INFO:  $LICENSE_DIR"
fi
