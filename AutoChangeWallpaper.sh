#!/bin/bash
#===================前言提示===================#
# 1. 使用登录壁纸以及用户桌面背景切换功能前，请先自己创建一个自定义
#     壁纸或桌面，否则脚本不会生效
# 2. 请以 Root 权限运行此脚本
# 3. 暂时支持 JPG、JPEG、PNG格式图片
# 4. 在FileStation里面右键文件夹属性可以看到路径
# 5. 使用本地图片做登录壁纸时不会设置动态标题，可到主题中设置
# 6. 必应壁纸固定为中国时区(mkt=zh-cn)
#===============参数配置区域开始===============#
#---用户桌面背景自动切换功能(取消注释即可启用)---#
#需要使用的图片路径，及用户名
#userLocalWallpaperPath="/volume1/photo"
#userName=""
#----------------------------------------------------#
#---登录界面壁纸自动更新功能---#
#本地壁纸库路径(取消注释即可启用，优先级高于必应壁纸)
#localWallpaperPath="/volume2/photo"
#每日壁纸保存文件夹路径(取消注释即可启用)
wallpaperSavePath="/volume2/photo/BingWallpaper"
#===============参数配置区域结束===============#

#===============函数定义区域================#
# 设置登录壁纸的通用函数
set_login_wallpaper() {
    local img="$1"
    local target_dir="/usr/syno/etc"
    local login_files=(
        "login_background.jpg"
        "login_background_hd.jpg"
        "SYNO.Foto.AppInstance_login_background.jpg"
        "SYNO.SDS.App.FileStation3.Instance_login_background.jpg"
        "SYNO.SDS.DownloadStation.Application_login_background.jpg"
        "SYNO.SDS.SheetStation.Application_login_background.jpg"
        "SYNO.SDS.VideoStation.AppInstance_login_background.jpg"
        "SYNO.SDS.Virtualization.Application_login_background.jpg"
    )
    
    rm -rf "$target_dir"/login_background*.jpg
    for f in "${login_files[@]}"; do
        convert -resize "1920x1200>" "$img" "$target_dir/$f" 2>/dev/null
    done
    
    sed -i '/login_background_customize=/d' /etc/synoinfo.conf
    echo 'login_background_customize="yes"' >> /etc/synoinfo.conf
}

# 设置桌面背景
set_desktop_wallpaper() {
    local img="$1"
    local target_dir="/usr/syno/synoman/webman/resources/images"
    local sizes=("1x" "2x")
    local types=("default_login_background" "default_wallpaper")
    
    for size in "${sizes[@]}"; do
        for type in "${types[@]}"; do
            cp -f "$img" "$target_dir/$size/$type/dsm7_01.jpg" 2>/dev/null
            convert -resize "160x100>" "$img" "$target_dir/$size/$type/thumbnail_01.jpg" 2>/dev/null
        done
    done
}

# 获取必应壁纸（中国区）
get_bing_wallpaper() {
    local mkt="${1:-zh-cn}"
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&mkt=$mkt"
    
    wget -t 5 --no-check-certificate -qO- "$api_url"
}

# 解析copyright生成文件名和描述
parse_copyright() {
    local copyright="$1"
    # 去除空格，替换中文标点和斜杠
    local cleaned=$(echo "$copyright" | sed 's/ //g' | sed 's/，/,/g' | sed 's/（/ (/g' | sed 's/）/)/g' | sed 's/\//_/g')
    
    # 提取中文部分（通常是第一个逗号前的内容）
    local chinese=$(echo "$cleaned" | cut -d',' -f1)
    # 提取英文部分（通常是括号内或逗号后的内容）
    local english=$(echo "$cleaned" | sed 's/^[^,]*[, ]*//' | sed 's/(.*)//' | sed 's/)$//')
    
    # 如果没有英文部分，使用中文作为文件名
    if [ -z "$english" ]; then
        english="$chinese"
    fi
    
    echo "$chinese|$english"
}

#===============主要脚本区域开始===============#

# 检查必要命令
for cmd in wget convert sed grep; do
    if ! command -v $cmd &>/dev/null; then
        echo "错误: $cmd 命令未找到，请先安装 ImageMagick 和 wget"
        exit 1
    fi
done

# 登录壁纸处理
if [ -n "$localWallpaperPath" ] && [ -d "$localWallpaperPath" ]; then
    # 使用本地图片作为登录壁纸
    loginPicPath=$(find "$localWallpaperPath" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/@eaDir/*" | shuf -n1)
    
    if [ -n "$loginPicPath" ] && [ -f "$loginPicPath" ]; then
        set_login_wallpaper "$loginPicPath"
        set_desktop_wallpaper "$loginPicPath"
        echo "已使用本地壁纸: $loginPicPath"
    else
        echo "警告: 未找到有效的本地壁纸"
    fi
else
    # 使用必应美图作为登录壁纸
    pic=$(get_bing_wallpaper "zh-cn")
    
    if ! echo "$pic" | grep -q "enddate"; then
        echo "错误: 获取必应壁纸失败"
        exit 1
    fi
    
    # 解析数据
    link=$(echo "$pic" | sed 's/.\+"url"[:" ]\+//g' | sed 's/".\+//g' | sed 's/^/https:\/\/www.bing.com/')
    UHDLink=$(echo "${link%%&*}")
    date=$(echo "$pic" | grep -oE '"enddate":"([0-9]{8})"' | cut -d'"' -f4)
    title=$(echo "$pic" | sed 's/.\+"title":"//g' | sed 's/".\+//g')
    copyright=$(echo "$pic" | sed 's/.\+"copyright[:" ]\+//g' | sed 's/".\+//g')
    
    # 解析copyright生成文件名组件
    IFS='|' read -r chinese_name english_name <<< "$(parse_copyright "$copyright")"
    
    # 生成描述文字（用于登录界面显示）
    word="${chinese_name} - ${english_name}"
    
    tmpfile="/tmp/${date}_bing.jpg"
    wget -t 5 --no-check-certificate "$link" -qO "$tmpfile"
    
    if [ -s "$tmpfile" ]; then
        # 设置壁纸
        set_login_wallpaper "$tmpfile"
        set_desktop_wallpaper "$tmpfile"
        
        # 设置标题和描述
        sed -i '/login_welcome_title=/d' /etc/synoinfo.conf
        echo "login_welcome_title=\"$title\"" >> /etc/synoinfo.conf
        sed -i '/login_welcome_msg=/d' /etc/synoinfo.conf
        echo "login_welcome_msg=\"$word\"" >> /etc/synoinfo.conf
        
        echo "已设置必应壁纸: $title"
        
        # 保存壁纸到指定目录（保持原命名格式：日期@景点地方-国家地区.jpg）
        if [ -n "$wallpaperSavePath" ] && [ -d "$wallpaperSavePath" ]; then
            saveName="${date}@${chinese_name}-${english_name}.jpg"
            # 下载高清原图
            wget -t 5 --no-check-certificate "$UHDLink" -qO "$wallpaperSavePath/$saveName"
            echo "壁纸已保存至: $wallpaperSavePath/$saveName"
        fi
        
        rm -f "$tmpfile"
    else
        echo "错误: 下载必应壁纸失败"
        exit 1
    fi
fi

# 用户桌面背景自动切换
if [ -n "$userLocalWallpaperPath" ] && [ -d "$userLocalWallpaperPath" ] && [ -n "$userName" ]; then
    userPicPath=$(find "$userLocalWallpaperPath" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/@eaDir/*" | shuf -n1)
    
    if [ -n "$userPicPath" ] && [ -f "$userPicPath" ]; then
        userPrefDir="/usr/syno/etc/preference/$userName"
        mkdir -p "$userPrefDir"
        
        convert -resize "1920x1200>" "$userPicPath" "$userPrefDir/wallpaper" 2>/dev/null
        convert -resize "1920x1200>" "$userPicPath" "$userPrefDir/1.jpg" 2>/dev/null
        convert -resize "120x120>" "$userPicPath" "$userPrefDir/1thumb.jpg" 2>/dev/null
        
        echo "已为用户 $userName 设置桌面壁纸: $userPicPath"
    else
        echo "警告: 未找到用户壁纸图片"
    fi
fi

echo "壁纸更新完成"
#================主要脚本区域结束================#
