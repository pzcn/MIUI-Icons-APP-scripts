
install() {
    echo "- 正在导出$theme_name..."
    tar -xf "$TEMP_DIR/icons.tar.xz" -C "$TEMP_DIR/" >&2
    mv $TEMP_DIR/icons $TEMP_DIR/icons.zip
    cd $TEMP_DIR
    tar -xf  $TEMP_DIR/$var_theme.tar.xz -C "$TEMP_DIR/"
    mkdir -p ./res/drawable-xxhdpi
    mv  icons/* ./res/drawable-xxhdpi 2>/dev/null
    rm -rf icons
    zip -r icons.zip ./layer_animating_icons >/dev/null
    zip -r icons.zip ./res >/dev/null
    rm -rf res
    rm -rf layer_animating_icons
    cd ..
    [ $addon == 1 ] && addon
    mkdir $TEMP_DIR/mtztmp
    tar -xf "$TEMP_DIR/mtz.tar.xz" -C "$TEMP_DIR/mtztmp" >&2
    cp -rf $TEMP_DIR/icons.zip $TEMP_DIR/mtztmp/icons
    sed -i "s/themename/$theme_name/g" $TEMP_DIR/mtztmp/description.xml
    cd $TEMP_DIR/mtztmp
    time=$(date '+%Y%m%d%H%M')
    zip -r mtz.zip * >/dev/null
    mv mtz.zip $mtzdir/${theme_name}完美图标补全-$time.mtz
    rm -rf $TEMP_DIR/*
    echo "- mtz主题包已导出到 $mtzdir/${theme_name}完美图标补全-$time.mtz。"
    echo "- 需要设计师账号或主题破解才能导入并使用。"
    exit 0
    }

getfiles() {
file=$TEMP_DIR/$var_theme.tar.xz
if [ -f "theme_files/${var_theme}.tar.xz" ]; then
source theme_files/${var_theme}.ini
old_ver=$theme_version
curl -skLJo "$TEMP_DIR/${var_theme}.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.ini?version=latest"
source $TEMP_DIR/${var_theme}.ini
new_ver=$theme_version
if [ $new_ver -ne $old_ver ] ;then 
echo "- ${theme_name}有新版本，即将开始下载..."
downloader
else
echo "- ${theme_name}没有更新，无需下载..."
cp -rf theme_files/${var_theme}.ini $TEMP_DIR/${var_theme}.ini
cp -rf theme_files/${var_theme}.tar.xz $TEMP_DIR/${var_theme}.tar.xz
fi
else downloader
fi
}

downloader() {
curl -skLJo "$TEMP_DIR/${var_theme}.ini" "https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.ini?version=latest"
    mkdir theme_files 2>/dev/null
    source $TEMP_DIR/${var_theme}.ini
    cp -rf $TEMP_DIR/${var_theme}.ini theme_files/${var_theme}.ini
    URL=https://miuiicons-generic.pkg.coding.net/icons/files/${var_theme}.tar.xz?version=latest
    echo "- 需要下载$theme_name资源... "
    [ $file_size ] || { echo "× 抱歉，在线资源临时维护中，请切换其他主题或稍后再试。" && rm -rf $TEMP_DIR/* 2>/dev/null&& exit 1; }
    echo "- 本次需下载 $(printf '%.1f' `echo "scale=1;$file_size/1048576"|bc`) MB"
    curl -skLJo "$file" "$URL"
    #进度条待添加
    md5_loacl=`md5sum $file|cut -d ' ' -f1`
    if [[ "$md5" != "$md5_loacl" ]]; then
        echo '下载完成，但文件MD5与预期的不一致' 1>&2
    fi
    cp $file theme_files/${var_theme}.tar.xz
}



addon(){
    addon_path=/sdcard/Documents/MIUI完美图标自定义
    if [ -d "$addon_path" ];then
    echo "- 检测到自定义图标，正在导入..."
    mkdir -p $TEMP_DIR/res/drawable-xxhdpi/
    mkdir -p $TEMP_DIR/layer_animating_icons
    cp -rf $addon_path/动态图标/* $TEMP_DIR/layer_animating_icons/ >/dev/null
    cp -rf $addon_path/静态图标/* $TEMP_DIR/res/drawable-xxhdpi/ >/dev/null
    cd $TEMP_DIR
    zip -r icons.zip res >/dev/null
    zip -r icons.zip layer_animating_icons >/dev/null
    cd ..
    fi
}
  exec 3>&2
  exec 2>/dev/null
  [ "`curl -I -s --connect-timeout 1 https://miuiiconseng-generic.pkg.coding.net/iconseng/engtest/test?version=latest -w %{http_code} | tail -n1`" == "200" ] ||{  echo "× 未检测到网络连接，取消安装 ... "&& rm -rf $TEMP_DIR/* >/dev/null && exit 1; }
  source theme_files/theme_config
  source theme_files/mtzdir_config
  source theme_files/addon_config
  var_theme=icons
  getfiles
  var_theme=mtz
  getfiles
  var_theme=$sel_theme
  getfiles
  install
  rm -rf $TEMP_DIR/*
  echo "---------------------------------------------"
  exit 0