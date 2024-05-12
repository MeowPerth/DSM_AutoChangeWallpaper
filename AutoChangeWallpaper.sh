#===================前言提示===================#
# 1. 使用登录壁纸以及用户桌面背景切换功能前，请先自己创建一个自定义
#     壁纸或桌面，否则脚本不会生效
# 2. 请以 Root 权限运行此脚本
# 3. 暂时支持 JPG、JPEG、PNG格式图片
# 4. 在FileStation里面右键文件夹属性可以看到路径
# 5. 使用本地图片做登录壁纸时不会设置动态标题，可到主题中设置
#===============参数配置区域开始===============#
#---用户桌面背景自动切换功能(删除两项注释即可启用)---#
#需要使用的图片路径，及用户名
#userLocalWallpaperPath="/volume1/photo/"
#userName="admin"
#----------------------------------------------------#
#---登录界面壁纸自动更新功能---#
#本地壁纸库路径(删除注释即可启用,启用后壁纸收集功能将禁用)
#localWallpaperPath="/volume2/photo/yande.re"
#每日壁纸保存文件夹路径(删除注释即可启用)
wallpaperSavePath="/volume1/photo/BingWallpaper"
#===============参数配置区域结束===============#
#===============主要脚本区域开始===============#
if (echo $localWallpaperPath|grep -q '/') then
#使用本地图片登录壁纸
loginPicPath=$(find "$localWallpaperPath" -ipath "$localWallpaperPath"/@eaDir -prune -type f -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" | shuf -n1)
#| sed 's/[[:space:]]/\\ /g' | sed 's/\*/\\*/g'
rm -rf /usr/syno/etc/login_background*.jpg
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/login_background_hd.jpg &>/dev/null
#以下内容适用于7.*版本
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.Foto.AppInstance_login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.SDS.App.FileStation3.Instance_login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.SDS.DownloadStation.Application_login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.SDS.SheetStation.Application_login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.SDS.VideoStation.AppInstance_login_background.jpg &>/dev/null
convert -resize "1920x1200>" "$loginPicPath" /usr/syno/etc/SYNO.SDS.Virtualization.Application_login_background.jpg &>/dev/null
sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
echo "login_background_customize=\"yes\"">>/etc/synoinfo.conf
else
#使用必应美图做登录壁纸
pic=$(wget -t 5 --no-check-certificate -qO- "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&mkt=zh-cn")
echo $pic|grep -q enddate||exit
link=$(echo https://www.bing.com$(echo $pic|sed 's/.\+"url"[:" ]\+//g'|sed 's/".\+//g'))
UHDLink=$(echo ${link%%&*})
date=$(echo $pic|sed 's/.\+enddate[": ]\+//g'|grep -Eo 2[0-9]{7}|head -1)
tmpfile=/tmp/$date"_bing.jpg"
wget -t 5 --no-check-certificate  $link -qO $tmpfile
#Copy文件到指定目录
[ -s $tmpfile ]||exit
rm -rf /usr/syno/etc/login_background*.jpg
cp -f $tmpfile /usr/syno/etc/login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/login_background_hd.jpg &>/dev/null
#以下内容适用于7.*版本
cp -f $tmpfile /usr/syno/etc/SYNO.Foto.AppInstance_login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/SYNO.SDS.App.FileStation3.Instance_login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/SYNO.SDS.DownloadStation.Application_login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/SYNO.SDS.SheetStation.Application_login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/SYNO.SDS.VideoStation.AppInstance_login_background.jpg &>/dev/null
cp -f $tmpfile /usr/syno/etc/SYNO.SDS.Virtualization.Application_login_background.jpg &>/dev/null

#替换用户桌面背景
cp -f $tmpfile /usr/syno/synoman/webman/resources/images/1x/default_login_background/dsm7_01.jpg &>/dev/null
convert -resize "160x100>" "$tmpfile" /usr/syno/synoman/webman/resources/images/1x/default_login_background/thumbnail_01.jpg &>/dev/null
cp -f $tmpfile /usr/syno/synoman/webman/resources/images/2x/default_login_background/dsm7_01.jpg &>/dev/null
convert -resize "160x100>" "$tmpfile" /usr/syno/synoman/webman/resources/images/2x/default_login_background/thumbnail_01.jpg &>/dev/null
cp -f $tmpfile /usr/syno/synoman/webman/resources/images/1x/default_wallpaper/dsm7_01.jpg &>/dev/null
convert -resize "160x100>" "$tmpfile" /usr/syno/synoman/webman/resources/images/1x/default_wallpaper/thumbnail_01.jpg &>/dev/null
cp -f $tmpfile /usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg &>/dev/null
convert -resize "160x100>" "$tmpfile" /usr/syno/synoman/webman/resources/images/2x/default_wallpaper/thumbnail_01.jpg &>/dev/null



#获取设置标题及描述内容
title=$(echo $pic|sed 's/.\+"title":"//g'|sed 's/".\+//g')
copyright=$(echo $pic|sed 's/.\+"copyright[:" ]\+//g'|sed 's/".\+//g')
cninfo=$(echo $copyright|sed 's/，/"/g'|sed 's/,/"/g'|sed 's/(/"/g'|sed 's/ //g'|sed 's/\//_/g'|sed 's/)//g')
word=$(echo $cninfo|cut -d'"' -f1)" - "$(echo $cninfo|cut -d'"' -f2)
#保存设置信息
sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
echo "login_background_customize=\"yes\"">>/etc/synoinfo.conf
sed -i s/login_welcome_title=.*//g /etc/synoinfo.conf
echo "login_welcome_title=\"$title\"">>/etc/synoinfo.conf
sed -i s/login_welcome_msg=.*//g /etc/synoinfo.conf
echo "login_welcome_msg=\"$word\"">>/etc/synoinfo.conf
#判定并保存图片到指定目录
if (echo $wallpaperSavePath|grep -q '/') then
pathname=$wallpaperSavePath/$date"@"$(echo $cninfo|cut -d'"' -f1)"-"$(echo $cninfo|cut -d'"' -f2)".jpg"
wget -t 5 --no-check-certificate  $UHDLink -qO $pathname
fi

#删除临时缓存图片
rm -rf /tmp/*_bing.jpg
fi
#用户桌面背景自动切换部分
if (echo $userLocalWallpaperPath|grep -q '/')&&(echo $userName|grep -q '[[:print:]]') then
picpath=$(find "$userLocalWallpaperPath" -ipath "$userLocalWallpaperPath"/@eaDir -prune -type f -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" | shuf -n1)
#| sed 's/[[:space:]]/\\ /g' | sed 's/\*/\\*/g'
convert -resize "1920x1200>" "$picpath" "/usr/syno/etc/preference/""$userName""/wallpaper"
convert -resize "1920x1200>" "$picpath" "/usr/syno/etc/preference/""$userName""/1.jpg"
convert -resize "120x120>" "$picpath" "/usr/syno/etc/preference/""$userName""/1thumb.jpg"
fi
#================主要脚本区域结束================#
