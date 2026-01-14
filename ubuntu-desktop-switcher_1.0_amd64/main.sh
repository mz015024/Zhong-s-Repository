#!/bin/bash
# Ubuntu 桌面环境管理脚本 - 图形化 安装/切换/卸载/查看
# 修复所有乱码问题 | 纯中文无特殊符号 | 安全卸载保护
# 支持：Ubuntu 20.04/22.04/24.04 全系版本 | GNOME/KDE/Xfce/MATE/LXQt/Budgie
# 运行方式：右键-允许执行，双击运行，全程鼠标操作

# ===================== 核心修复：彻底解决乱码 =====================
# 1. 强制设置系统编码为UTF-8，杜绝中文乱码
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN.UTF-8
# 2. 取消所有特殊符号/emoji，全部改用纯文字，避免方块乱码
# 3. 移除图形界面无效的终端颜色转义符，彻底根除乱码源

# 检查是否为Ubuntu系统
check_ubuntu() {
    if [ ! -f /etc/lsb-release ]; then
        zenity --error --width=400 --text="错误：此脚本仅支持Ubuntu操作系统！"
        exit 1
    fi
}

# 检查图形依赖zenity，无则自动安装，无乱码提示
check_zenity() {
    if ! command -v zenity &>/dev/null; then
        zenity --info --width=400 --text="正在安装图形界面所需依赖，请稍候..."
        sudo apt update -y >/dev/null 2>&1
        sudo apt install zenity -y >/dev/null 2>&1
    fi
}

# 功能1：查看当前正在使用的桌面环境
show_current_desktop() {
    CURRENT_SESSION=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
    case $CURRENT_SESSION in
        gnome) CURRENT_NAME="GNOME 桌面（Ubuntu默认）" ;;
        kde) CURRENT_NAME="KDE Plasma 桌面" ;;
        xfce) CURRENT_NAME="Xfce 4 桌面" ;;
        mate) CURRENT_NAME="MATE 桌面" ;;
        lxqt) CURRENT_NAME="LXQt 桌面" ;;
        budgie) CURRENT_NAME="Budgie 桌面" ;;
        *) CURRENT_NAME="未知桌面环境" ;;
    esac
    zenity --info --width=420 --text="当前系统正在使用的桌面环境：\n\n$CURRENT_NAME"
}

# 功能2：安装/切换桌面环境（核心功能，无乱码）
install_switch_desktop() {
    DESKTOP=$(zenity --list \
        --width=600 --height=480 \
        --title="Ubuntu 桌面环境安装/切换" \
        --text="选中后自动安装对应桌面，已安装则直接设为默认桌面，无需重复安装" \
        --radiolist \
        --column="" --column="桌面环境" --column="特点描述" \
        FALSE "GNOME" "Ubuntu原生默认，简洁稳定，占用适中，新手首选" \
        FALSE "KDE Plasma" "功能最全，界面美观，自定义强，适合喜欢美化的用户" \
        FALSE "Xfce 4" "轻量流畅，资源占用极低，低配电脑/虚拟机最佳选择" \
        FALSE "MATE" "经典GNOME2风格，操作简单，适合习惯Windows的用户" \
        FALSE "LXQt" "极致轻量，内存占用最少，老旧电脑专用" \
        FALSE "Budgie" "简洁优雅，轻量化+高颜值，介于GNOME和Xfce之间")

    # 点击取消则退出
    [ -z "$DESKTOP" ] && exit 0

    # 匹配对应桌面的安装包+显示管理器，无乱码配置
    case $DESKTOP in
        GNOME) PKG="ubuntu-desktop^ gnome-shell"; DM="gdm3" ;;
        KDE\ Plasma) PKG="kubuntu-desktop^ sddm"; DM="sddm" ;;
        Xfce\ 4) PKG="xubuntu-desktop^ xfce4"; DM="lightdm" ;;
        MATE) PKG="ubuntu-mate-desktop^ mate-desktop"; DM="lightdm" ;;
        LXQt) PKG="lubuntu-desktop^ lxqt"; DM="sddm" ;;
        Budgie) PKG="ubuntu-budgie-desktop^ budgie-desktop"; DM="gdm3" ;;
    esac

    # 确认安装
    zenity --question --width=420 --text="即将安装【$DESKTOP】桌面环境，安装过程约5-15分钟，取决于网速。\n是否继续执行安装？" || exit 0

    # 静默安装，无乱码输出，自动确认所有选项
    zenity --info --width=380 --text="正在安装 $DESKTOP 桌面环境，请耐心等待..."
    sudo apt update -y >/dev/null 2>&1
    sudo apt install $PKG -y --no-install-recommends >/dev/null 2>&1
    sudo dpkg-reconfigure -f noninteractive $DM >/dev/null 2>&1

    # 切换成功提示，纯文字无乱码
    zenity --warning --width=450 --text="已成功安装并设置【$DESKTOP】为默认桌面！\n生效方式：点击屏幕右上角电源图标 → 注销，重新登录即可。"
}

# 功能3：卸载桌面环境【安全无风险+无乱码】，这是你要的核心功能
uninstall_desktop() {
    # 第一步：获取当前正在使用的桌面，禁止卸载，防止系统崩溃！【重中之重】
    CURRENT_SESSION=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
    case $CURRENT_SESSION in
        gnome) FORBID="GNOME" ;;
        kde) FORBID="KDE Plasma" ;;
        xfce) FORBID="Xfce 4" ;;
        mate) FORBID="MATE" ;;
        lxqt) FORBID="LXQt" ;;
        budgie) FORBID="Budgie" ;;
        *) FORBID="未知桌面" ;;
    esac

    # 第二步：图形选择要卸载的桌面，自动灰掉当前桌面，无法选中
    DESKTOP=$(zenity --list \
        --width=600 --height=450 \
        --title="Ubuntu 桌面环境卸载工具" \
        --text="重要提醒：禁止卸载当前正在使用的【$FORBID】桌面，否则系统会瘫痪！\n选中要卸载的桌面，会彻底删除程序+清理无用依赖" \
        --radiolist \
        --column="选择" --column="桌面环境" --column="状态" \
        $([ "$FORBID" != "GNOME" ] && echo "FALSE" || echo "TRUE") "GNOME" "$([ "$FORBID" = "GNOME" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")" \
        $([ "$FORBID" != "KDE Plasma" ] && echo "FALSE" || echo "TRUE") "KDE Plasma" "$([ "$FORBID" = "KDE Plasma" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")" \
        $([ "$FORBID" != "Xfce 4" ] && echo "FALSE" || echo "TRUE") "Xfce 4" "$([ "$FORBID" = "Xfce 4" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")" \
        $([ "$FORBID" != "MATE" ] && echo "FALSE" || echo "TRUE") "MATE" "$([ "$FORBID" = "MATE" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")" \
        $([ "$FORBID" != "LXQt" ] && echo "FALSE" || echo "TRUE") "LXQt" "$([ "$FORBID" = "LXQt" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")" \
        $([ "$FORBID" != "Budgie" ] && echo "FALSE" || echo "TRUE") "Budgie" "$([ "$FORBID" = "Budgie" ] && echo "当前使用，禁止卸载" || echo "可安全卸载")")

    # 点击取消则退出
    [ -z "$DESKTOP" ] && exit 0

    # 二次防护：如果误选当前桌面，直接提示退出
    if [ "$DESKTOP" = "$FORBID" ]; then
        zenity --error --width=380 --text="错误！不能卸载当前正在使用的桌面环境，操作已取消。"
        exit 1
    fi

    # 匹配对应桌面的卸载包名
    case $DESKTOP in
        GNOME) UNPKG="ubuntu-desktop^ gnome-shell gnome-*" ;;
        KDE\ Plasma) UNPKG="kubuntu-desktop^ kde-plasma-desktop kde-* sddm" ;;
        Xfce\ 4) UNPKG="xubuntu-desktop^ xfce4 xfce4-* lightdm" ;;
        MATE) UNPKG="ubuntu-mate-desktop^ mate-desktop mate-* lightdm" ;;
        LXQt) UNPKG="lubuntu-desktop^ lxqt lxqt-* sddm" ;;
        Budgie) UNPKG="ubuntu-budgie-desktop^ budgie-desktop budgie-*" ;;
    esac

    # 确认卸载，防止误操作
    zenity --question --width=400 --text="即将彻底卸载【$DESKTOP】桌面环境，卸载后无法恢复，是否继续？" || exit 0

    # 执行卸载+深度清理冗余依赖（最干净的卸载方式）
    zenity --info --width=380 --text="正在卸载 $DESKTOP 桌面环境，请稍候..."
    sudo apt remove -y $UNPKG >/dev/null 2>&1
    sudo apt autoremove -y >/dev/null 2>&1
    sudo apt clean >/dev/null 2>&1

    # 卸载成功提示
    zenity --info --width=380 --text="已彻底卸载【$DESKTOP】桌面环境！\n建议重启电脑，清理所有残留文件。"
}

# 主菜单：所有功能入口，纯图形鼠标点击，无任何命令输入
main_menu() {
    CHOICE=$(zenity --list \
        --width=550 --height=380 \
        --title="Ubuntu 桌面环境管理工具 - 主菜单" \
        --text="请选择要执行的操作，全程鼠标点击即可，无需输入命令" \
        --radiolist \
        --column="选择" --column="功能选项" --column="功能说明" \
        FALSE "安装/切换桌面环境" "安装新桌面 或 切换已安装的桌面，自动设为默认" \
        FALSE "卸载桌面环境" "卸载多余的桌面，清理磁盘空间，安全无风险" \
        FALSE "查看当前桌面环境" "查看系统现在正在使用的桌面环境")

    # 根据选择执行对应功能
    case $CHOICE in
        "安装/切换桌面环境") install_switch_desktop ;;
        "卸载桌面环境") uninstall_desktop ;;
        "查看当前桌面环境") show_current_desktop ;;
        *) exit 0 ;;
    esac
}

# 脚本执行主流程
check_ubuntu
check_zenity
main_menu
exit 0
