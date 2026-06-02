#!/bin/bash
#===================前言提示===================#
# 1. 使用登录壁纸以及用户桌面背景切换功能前，请先自己创建一个自定义
#     壁纸或桌面，否则脚本不会生效
# 2. 请以 Root 权限运行此脚本
# 3. 暂时支持 JPG、JPEG、PNG格式图片
# 4. 在FileStation里面右键文件夹属性可以看到路径
# 5. 使用本地图片做登录壁纸时不会设置动态标题，可到主题中设置
# 6. 必应壁纸固定为中国时区(mkt=zh-cn)
#================参数配置区域开始================#
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
#================参数配置区域结束================#

#================可自定义尺寸参数================#
# 登录壁纸目标尺寸
LOGIN_WALLPAPER_SIZE="1920x1200"
# 桌面壁纸缩略图尺寸
THUMBNAIL_SIZE="160x100"
# 用户壁纸尺寸
USER_WALLPAPER_SIZE="1920x1200"
# 用户壁纸缩略图尺寸
USER_THUMB_SIZE="120x120"
# 下载超时时间(秒)
DOWNLOAD_TIMEOUT=30
# 下载重试次数
DOWNLOAD_RETRIES=5
#================函数定义区域================#

# 清理临时文件
cleanup() {
    local exit_code=$?
    rm -f "${tmpfile:-}" "${tmpfile_hd:-}" 2>/dev/null
    exit "$exit_code"
}
trap cleanup EXIT INT TERM HUP

# 设置登录壁纸的通用函数（原子操作，避免裸窗期）
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
    local tmp_dir
    tmp_dir=$(mktemp -d) || return 1

    # 先生成到临时目录，再统一 mv 过去（原子操作）
    for f in "${login_files[@]}"; do
        convert -resize "${LOGIN_WALLPAPER_SIZE}>" "$img" "$tmp_dir/$f" 2>/dev/null
    done

    # 批量移动（比逐个移动更快）
    for f in "${login_files[@]}"; do
        if [ -f "$tmp_dir/$f" ]; then
            mv -f "$tmp_dir/$f" "$target_dir/$f" 2>/dev/null
        fi
    done

    rm -rf "$tmp_dir"

    # 清理旧格式文件（兼容旧版本遗留文件）
    rm -f "$target_dir"/login_background_*.jpg 2>/dev/null

    sed -i '/login_background_customize=/d' /etc/synoinfo.conf 2>/dev/null
    echo 'login_background_customize="yes"' >> /etc/synoinfo.conf
}

# 设置桌面背景
set_desktop_wallpaper() {
    local img="$1"
    local target_dir="/usr/syno/synoman/webman/resources/images"
    local sizes=("1x" "2x")
    local types=("default_login_background" "default_wallpaper")
    local tmp_dir
    tmp_dir=$(mktemp -d) || return 1

    # 统一 resize 后再复制，避免不同分辨率下展示不一致
    convert -resize "${LOGIN_WALLPAPER_SIZE}>" "$img" "$tmp_dir/dsm7_01.jpg" 2>/dev/null
    convert -resize "${THUMBNAIL_SIZE}>" "$img" "$tmp_dir/thumbnail_01.jpg" 2>/dev/null

    for size in "${sizes[@]}"; do
        for type in "${types[@]}"; do
            mkdir -p "$target_dir/$size/$type" 2>/dev/null
            cp -f "$tmp_dir/dsm7_01.jpg" "$target_dir/$size/$type/dsm7_01.jpg" 2>/dev/null
            cp -f "$tmp_dir/thumbnail_01.jpg" "$target_dir/$size/$type/thumbnail_01.jpg" 2>/dev/null
        done
    done

    rm -rf "$tmp_dir"
}

# 获取必应壁纸（中国区）
get_bing_wallpaper() {
    local mkt="${1:-zh-cn}"
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&mkt=$mkt"

    wget -t "$DOWNLOAD_RETRIES" --timeout="$DOWNLOAD_TIMEOUT" --no-check-certificate -qO- "$api_url"
}

# 获取必应壁纸（使用 jq 解析，更健壮）
get_bing_wallpaper_jq() {
    local mkt="${1:-zh-cn}"
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&mkt=$mkt"

    wget -t "$DOWNLOAD_RETRIES" --timeout="$DOWNLOAD_TIMEOUT" --no-check-certificate -qO- "$api_url" 2>/dev/null
}

# 解析copyright生成文件名和描述（增强版）
parse_copyright() {
    local copyright="$1"

    # 防御：空输入
    if [ -z "$copyright" ]; then
        echo "未知壁纸|Unknown"
        return
    fi

    # 去除多余空格，替换中文标点和斜杠（合并 sed 减少管道）
    local cleaned
    cleaned=$(echo "$copyright" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
                                      -e 's/，/,/g' \
                                      -e 's/（/(/g' -e 's/）/)/g' \
                                      -e 's/\//_/g' \
                                      -e 's/[[:space:]]\+/ /g')

    # 多数格式: "中文描述 (© 摄影师/版权信息)"
    # 或 "English description (© Photographer)"
    # 尝试提取括号外的中文内容做中文名，括号内的为英文名

    # 尝试提取括号外内容（中文部分）
    local outside_paren
    outside_paren=$(echo "$cleaned" | sed 's/([^)]*)//g' | sed 's/([^)]*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # 尝试提取括号内内容（英文部分）
    local inside_paren
    inside_paren=$(echo "$cleaned" | grep -o '([^)]*)' | head -1 | sed 's/(//' | sed 's/)//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # 去除括号内的版权符号和摄影师信息，得到纯英文描述
    local english
    if [ -n "$inside_paren" ]; then
        english=$(echo "$inside_paren" | sed 's/©.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/,$//')
    fi

    # 中文部分：取括号外内容并去掉末尾的版权符号片段
    local chinese
    chinese=$(echo "$outside_paren" | sed 's/©.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/,$//')

    # 回退策略
    if [ -z "$chinese" ] && [ -z "$english" ]; then
        # 可能格式是纯英文 copyright 字段
        chinese=$(echo "$cleaned" | sed 's/©.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        english="$chinese"
    fi

    if [ -z "$chinese" ]; then
        chinese="必应壁纸"
    fi
    if [ -z "$english" ]; then
        english="$chinese"
    fi

    # 清理多余空格、逗号
    chinese=$(echo "$chinese" | sed 's/^[,[:space:]]*//' | sed 's/[,[:space:]]*$//')
    english=$(echo "$english" | sed 's/^[,[:space:]]*//' | sed 's/[,[:space:]]*$//')

    echo "$chinese|$english"
}

# 查找图片文件（统一函数，避免重复）
find_image_files() {
    local search_path="$1"
    if [ -z "$search_path" ] || [ ! -d "$search_path" ]; then
        return 1
    fi
    find "$search_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/@eaDir/*" 2>/dev/null | shuf -n1
}

# 检查必要命令
check_dependencies() {
    local missing=0
    local cmds=("wget" "convert" "sed" "grep" "cp" "mkdir" "rm" "mv" "cut" "find" "mktemp")

    # jq 为可选依赖，有则使用更稳健的 JSON 解析
    if command -v jq &>/dev/null; then
        HAS_JQ=true
    else
        HAS_JQ=false
        echo "提示: 未安装 jq，将使用 sed 解析 JSON（建议安装 jq 以获得更稳定的解析）" >&2
    fi

    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "错误: $cmd 命令未找到，请先安装" >&2
            missing=$((missing + 1))
        fi
    done

    if [ "$missing" -gt 0 ]; then
        echo "错误: 缺少 $missing 个必要命令，请安装后重试" >&2
        exit 1
    fi
}

#===============主要脚本区域开始===============#

# 检查依赖
check_dependencies

# 登录壁纸处理
if [ -n "$localWallpaperPath" ] && [ -d "$localWallpaperPath" ]; then
    # 使用本地图片作为登录壁纸
    loginPicPath=$(find_image_files "$localWallpaperPath")

    if [ -n "$loginPicPath" ] && [ -f "$loginPicPath" ]; then
        set_login_wallpaper "$loginPicPath"
        set_desktop_wallpaper "$loginPicPath"
        echo "已使用本地壁纸: $loginPicPath"
    else
        echo "警告: 未找到有效的本地壁纸"
    fi
else
    # 使用必应美图作为登录壁纸
    pic=$(get_bing_wallpaper_jq "zh-cn")

    if [ -z "$pic" ]; then
        echo "错误: 获取必应壁纸失败（网络错误或超时）"
        exit 1
    fi

    # jq 解析（更稳健）vs sed 解析（兼容方案）
    if [ "$HAS_JQ" = true ]; then
        # 使用 jq 解析 JSON
        if ! echo "$pic" | jq -e '.images[0]' &>/dev/null; then
            echo "错误: 必应壁纸 JSON 数据结构异常"
            exit 1
        fi

        link=$(echo "$pic" | jq -r '.images[0].url' 2>/dev/null)
        link="https://www.bing.com${link}"
        UHDLink=$(echo "$link" | sed 's/&.*//')
        date=$(echo "$pic" | jq -r '.images[0].enddate' 2>/dev/null)
        title=$(echo "$pic" | jq -r '.images[0].title' 2>/dev/null)
        copyright=$(echo "$pic" | jq -r '.images[0].copyright' 2>/dev/null)
    else
        # 兼容方案：用 sed 解析（保持向后兼容）
        if ! echo "$pic" | grep -q "enddate"; then
            echo "错误: 获取必应壁纸失败（数据格式异常）"
            exit 1
        fi

        link=$(echo "$pic" | sed 's/.\+"url"[:" ]\+//g' | sed 's/".\+//g' | sed 's/^/https:\/\/www.bing.com/')
        UHDLink=$(echo "${link%%&*}")
        date=$(echo "$pic" | grep -oE '"enddate":"([0-9]{8})"' | cut -d'"' -f4)
        title=$(echo "$pic" | sed 's/.\+"title":"//g' | sed 's/".\+//g')
        copyright=$(echo "$pic" | sed 's/.\+"copyright[:" ]\+//g' | sed 's/".\+//g')
    fi

    # 参数有效性检查
    if [ -z "$link" ] || [ -z "$date" ]; then
        echo "错误: 解析必应壁纸数据失败"
        exit 1
    fi

    # 解析copyright生成文件名组件
    IFS='|' read -r chinese_name english_name <<< "$(parse_copyright "$copyright")"

    # 生成描述文字（用于登录界面显示）
    word="${chinese_name} - ${english_name}"

    tmpfile="/tmp/${date}_bing.jpg"
    wget -t "$DOWNLOAD_RETRIES" --timeout="$DOWNLOAD_TIMEOUT" --no-check-certificate "$link" -qO "$tmpfile"

    if [ -s "$tmpfile" ]; then
        # 设置壁纸
        set_login_wallpaper "$tmpfile"
        set_desktop_wallpaper "$tmpfile"

        # 设置标题和描述
        sed -i '/login_welcome_title=/d' /etc/synoinfo.conf 2>/dev/null
        echo "login_welcome_title=\"$title\"" >> /etc/synoinfo.conf
        sed -i '/login_welcome_msg=/d' /etc/synoinfo.conf 2>/dev/null
        echo "login_welcome_msg=\"$word\"" >> /etc/synoinfo.conf

        echo "已设置必应壁纸: $title"

        # 保存壁纸到指定目录
        if [ -n "$wallpaperSavePath" ]; then
            # 自动创建目录
            mkdir -p "$wallpaperSavePath" 2>/dev/null
            if [ -d "$wallpaperSavePath" ]; then
                # 清理文件名中的特殊字符，防止文件系统问题
                safe_english=$(echo "$english_name" | sed 's/[\/:*?"<>|]//g')
                saveName="${date}@${chinese_name}-${safe_english}.jpg"

                # 下载高清原图
                wget -t "$DOWNLOAD_RETRIES" --timeout="$DOWNLOAD_TIMEOUT" --no-check-certificate "$UHDLink" -qO "$wallpaperSavePath/$saveName"
                if [ -s "$wallpaperSavePath/$saveName" ]; then
                    echo "壁纸已保存至: $wallpaperSavePath/$saveName"
                else
                    rm -f "$wallpaperSavePath/$saveName" 2>/dev/null
                    echo "警告: 高清原图下载失败"
                fi
            else
                echo "警告: 无法创建壁纸保存目录: $wallpaperSavePath"
            fi
        fi
    else
        echo "错误: 下载必应壁纸失败"
        exit 1
    fi
fi

# 用户桌面背景自动切换
if [ -n "$userLocalWallpaperPath" ] && [ -d "$userLocalWallpaperPath" ] && [ -n "$userName" ]; then
    userPicPath=$(find_image_files "$userLocalWallpaperPath")

    if [ -n "$userPicPath" ] && [ -f "$userPicPath" ]; then
        userPrefDir="/usr/syno/etc/preference/$userName"
        mkdir -p "$userPrefDir"

        # 合并冗余 convert 调用：先生成一张，再复制
        convert -resize "${USER_WALLPAPER_SIZE}>" "$userPicPath" "$userPrefDir/wallpaper" 2>/dev/null
        # 相同尺寸直接复制，避免二次 resize
        cp -f "$userPrefDir/wallpaper" "$userPrefDir/1.jpg" 2>/dev/null
        # 缩略图单独 resize
        convert -resize "${USER_THUMB_SIZE}>" "$userPicPath" "$userPrefDir/1thumb.jpg" 2>/dev/null

        echo "已为用户 $userName 设置桌面壁纸: $userPicPath"
    else
        echo "警告: 未找到用户壁纸图片"
    fi
fi

echo "壁纸更新完成"
#================主要脚本区域结束================#
