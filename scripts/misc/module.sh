module_files() { 
mkdir -p $TEMP_DIR/META-INF/com/google/android
echo "#MAGISK" >> $TEMP_DIR/META-INF/com/google/android/updater-script
cat > $TEMP_DIR/META-INF/com/google/android/update-binary << 'EOF'
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk

install_module
exit 0
EOF

cat > $TEMP_DIR/customize.sh << 'EOF'
#!/sbin/sh
SKIPUNZIP=1

ui_print "---------------------------------------------"
ui_print "  MIUI完美图标补全计划"
ui_print "  MIUI-Adapted-Icons-Complement-Project"
ui_print "---------------------------------------------"

var_version="`getprop ro.build.version.release`"
var_miui_version="`getprop ro.miui.ui.version.code`"

if [ $var_version -lt 10 ]; then 
  abort "- 您的 Android 版本不符合要求，即将退出安装。"
elif [ $var_version -lt 13 ] ;then
  mediapath=system/media/theme
else
  mediapath=system/product/media/theme
fi
if [ $var_miui_version -lt 11 ]; then 
  abort "- 您的 MIUI 版本不符合要求，即将退出安装。"
fi
mkdir -p $MODPATH/$mediapath/default/
mktouch $MODPATH/$mediapath/miui_mod_icons/.replace
unzip -oj "$ZIPFILE" icons -d $MODPATH/$mediapath/default >&2
mv $TMPDIR/module.prop $MODPATH/module.prop

echo ""
echo "- 安装成功，请重启设备"
echo "---------------------------------------------"
EOF

echo "id=MIUIiconsplus
name=MIUI ${string_projectname}
author=@PedroZ
description=${string_moduledescription_1}${theme_name}${string_moduledescription_2}
version=$(TZ=$(getprop persist.sys.timezone) date '+%Y%m%d%H%M')
theme=$theme_name
themeid=$var_theme" >> $TEMP_DIR/module.prop
}
save() {
    time=$(TZ=$(getprop persist.sys.timezone) date '+%m%d%H%M')
    modulefilepath=${moduledir}/${theme_name}${string_projectname}-$time.zip
    mv $TEMP_DIR/moduletmp/module.zip ${modulefilepath}
}
disable_dynamicicon() {
test=`head -n 1 ${START_DIR}/theme_files/denylist`
if [ "$test" = "all" ] ; then
  echo "- 禁用所有动态图标..."
  rm -rf $TEMP_DIR/layer_animating_icons
elif [ "$test" = "" ] ; then
  :
else
  echo "- 禁用下列app的动态图标："
  list=`cat ${START_DIR}/theme_files/denylist`
  for p in $list
  do
    [ -d "$TEMP_DIR/layer_animating_icons/$p" ] && rm -rf  $TEMP_DIR/layer_animating_icons/$p && echo "  ""$p"
  done
fi
}

install() {
    echo "${string_exporting}$theme_name..."
    cd ${START_DIR}/theme_files/miui
    zip -r $TEMP_DIR/icons.zip * -x './res/drawable-xxhdpi/.git/*' >/dev/null
    cd $TEMP_DIR
    toybox tar -xf  $TEMP_DIR/$var_theme.tar.xz -C "$TEMP_DIR/"
    mkdir -p $TEMP_DIR/res/drawable-xxhdpi
    mv  $TEMP_DIR/icons/* $TEMP_DIR/res/drawable-xxhdpi 2>/dev/null
    rm -rf $TEMP_DIR/icons
    [ -f ${START_DIR}/theme_files/denylist ] && disable_dynamicicon
    zip -r icons.zip ./layer_animating_icons >/dev/null
    zip -r icons.zip ./res >/dev/null
    rm -rf $TEMP_DIR/res
    rm -rf $TEMP_DIR/layer_animating_icons
    [ $addon == 1 ] && addon
    mkdir $TEMP_DIR/moduletmp
    cp -rf $TEMP_DIR/icons.zip $TEMP_DIR/moduletmp/icons
    cd $TEMP_DIR/moduletmp
    module_files
    zip -r module.zip * >/dev/null
    if [ "$1" == kernelsu ]; then 
      if [ -f "$TOOLKIT/mount" ]; then
        rm $TOOLKIT/mount
      fi
      if [ -f "$TOOLKIT/losetup" ]; then
        rm $TOOLKIT/losetup
      fi
        echo 安装KernelSU模块
      if [ -f "/data/adb/ksud" ]; then
        /data/adb/ksud module install $TEMP_DIR/moduletmp/module.zip
      fi
    elif [ "$1" == magisk ]; then
      type magisk >/dev/null 2>&1 || { echo "-  无法安装模块，模块已导出，请手动安装。"; save; }
      magisk --install-module $TEMP_DIR/moduletmp/module.zip
    else
      save
    fi
    }

getfiles() {
file=$TEMP_DIR/$var_theme.tar.xz
if [ -f "${START_DIR}/theme_files/${var_theme}.tar.xz" ]; then
source ${START_DIR}/theme_files/${var_theme}.ini
old_ver=$theme_version
curl -skLJo "$TEMP_DIR/${var_theme}.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.ini?version=latest"
source $TEMP_DIR/${var_theme}.ini
new_ver=$theme_version
if [ $new_ver -ne $old_ver ] ;then 
echo "${string_newverdown_1}${theme_name}${string_newverdown_2}"
download
else
echo "${string_vernoneedtodown_1}${theme_name}${string_vernoneedtodown_2}"
cp -rf theme_files/${var_theme}.ini $TEMP_DIR/${var_theme}.ini
cp -rf theme_files/${var_theme}.tar.xz $TEMP_DIR/${var_theme}.tar.xz
fi
else download
fi
}

download() {
curl -skLJo "$TEMP_DIR/${var_theme}.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.ini?version=latest"
    mkdir theme_files 2>/dev/null
    source $TEMP_DIR/${var_theme}.ini
    cp -rf $TEMP_DIR/${var_theme}.ini theme_files/${var_theme}.ini
    if [ $file_size -gt 5242880 ] ;then
    downloadUrl=${link_miui}/${var_theme}.tar.xz
    downloader "$downloadUrl" $md5
    [ $var_theme == iconsrepo ] || cp $downloader_result theme_files/${var_theme}.tar.xz
    mv $downloader_result $TEMP_DIR/$var_theme.tar.xz
    else
echo "${string_needtodownloadname_1}${theme_name}${string_needtodownloadname_2}"
  [ $file_size ] || { echo ${string_cannotdownload} && rm -rf $TEMP_DIR/* 2>/dev/null&& exit 1; }
  echo "${string_needtodownloadsize_1}$(printf '%.1f' `echo "scale=1;$file_size/1048576"|bc`)${string_needtodownloadsize_2}"
      curl -skLJo "$TEMP_DIR/${var_theme}.tar.xz" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.tar.xz?version=latest"
      [ $var_theme == iconsrepo ] || cp "$TEMP_DIR/${var_theme}.tar.xz" "theme_files/${var_theme}.tar.xz"
    md5_loacl=`md5sum $TEMP_DIR/${var_theme}.tar.xz|cut -d ' ' -f1`
    if [[ "$md5" = "$md5_loacl" ]]; then
      echo $string_downloadsuccess
    else
      echo ${string_downloaderror}
    rm -rf $TEMP_DIR/* >/dev/null
    exit 1
    fi
    fi
}



addon(){
    addon_path=$SDCARD_PATH/Documents/${string_addonfolder}
    if [ -d "$addon_path" ];then
    echo "${string_importaddonicons}"
    mkdir -p $TEMP_DIR/res/drawable-xxhdpi/
    mkdir -p $TEMP_DIR/layer_animating_icons
    cp -rf $addon_path/${string_animatingicons}/* $TEMP_DIR/layer_animating_icons/ >/dev/null
    cp -rf $addon_path/${string_staticicons}/* $TEMP_DIR/res/drawable-xxhdpi/ >/dev/null
    cd $TEMP_DIR
    zip -r icons.zip res >/dev/null
    zip -r icons.zip layer_animating_icons >/dev/null
    cd ..
    fi
}
  exec 3>&2
  exec 2>/dev/null
  curl -skLJo "$TEMP_DIR/link.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/link.ini?version=latest"
  source $TEMP_DIR/link.ini
  http_code="`curl -I -s --connect-timeout 1 ${link_check} -w %{http_code} | tail -n1`" 
  if [ "$http_code" != null ];then
    if [[ ! $httpcode == *$http_code* ]]; then
    {  echo "${string_nonetworkdetected}" && rm -rf $TEMP_DIR/* >/dev/null && exit 1; }
  fi
else
  {  echo "${string_nonetworkdetected}" && rm -rf $TEMP_DIR/* >/dev/null && exit 1; }
fi

  source theme_files/theme_config
  source theme_files/moduledir_config
  source theme_files/addon_config
  source $START_DIR/online-scripts/misc/downloader.sh
  [ -d "$moduledir" ] || {  echo ${string_dirnotexist} && rm -rf $TEMP_DIR/* >/dev/null && exit 1; }
  var_theme=iconsrepo
  if [[ -d theme_files/miui/res/drawable-xxhdpi/.git ]]; then
    source theme_files/${var_theme}.ini
    old_ver=$theme_version
    curl -skLJo "$TEMP_DIR/${var_theme}.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.ini?version=latest"
    source $TEMP_DIR/${var_theme}.ini
    new_ver=$theme_version
    if [ $new_ver -ne $old_ver ] ;then 
    echo "${string_newverdown_1}${theme_name}${string_newverdown_2}"
    echo "${string_gitpull}"
        cd theme_files/miui/res/drawable-xxhdpi
        export LD_LIBRARY_PATH=${START_DIR}/script/toolkit/so: $LD_LIBRARY_PATH
        git pull --rebase >/dev/null
        cp -rf $TEMP_DIR/${var_theme}.ini ${START_DIR}/theme_files/${var_theme}.ini
    cd ../../../..
    else
    echo "${string_vernoneedtodown_1}${theme_name}${string_vernoneedtodown_2}"
    fi
    echo "$var_theme=$theme_version" >> $TEMP_DIR/module.prop
  else
    getfiles
        echo "${string_extracting}${theme_name}..."
    toybox tar -xf "$TEMP_DIR/iconsrepo.tar.xz" -C "$TEMP_DIR/" >&2
    mv $TEMP_DIR/icons $TEMP_DIR/icons.zip
    unzip $TEMP_DIR/icons.zip -d theme_files/miui >/dev/null
    rm -rf $TEMP_DIR/icons.zip
    rm -rf $TEMP_DIR/iconsrepo.tar.xz
  fi
  var_theme=$sel_theme
  getfiles
  install $1
  rm -rf $TEMP_DIR/*
  echo "---------------------------------------------"
  exit 0
