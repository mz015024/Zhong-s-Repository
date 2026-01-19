#!/bin/bash
# Manjaro/Ubuntu/Fedora 通用 显示管理器图形化管理工具
# 新增：自动检测+自动安装所有依赖，中文图形化弹窗，全发行版兼容
# 支持：GDM/SDDM/LightDM/LXDM 四大主流显示管理器

# 颜色定义（终端日志用，不影响图形化）
green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

# ===================== 核心新增：自动检测发行版 =====================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        if [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
            PM="apt"
            PM_INSTALL="sudo apt update -y && sudo apt install -y --no-install-recommends"
        elif [[ $DISTRO == "fedora" || $DISTRO == "rhel" || $DISTRO == "centos" ]]; then
            PM="dnf"
            PM_INSTALL="sudo dnf install -y"
        elif [[ $DISTRO == "manjaro" || $DISTRO == "arch" ]]; then
            PM="pacman"
            PM_INSTALL="sudo pacman -S --noconfirm"
        else
            zenity --error --title="错误" --width=400 --text="不支持的系统发行版！\n仅支持：Manjaro/Arch、Ubuntu/Debian、Fedora"
            exit 1
        fi
    else
        zenity --error --title="错误" --width=400 --text="无法识别系统版本！"
        exit 1
    fi
}

# ===================== 核心新增：自动检测+安装所有依赖 =====================
check_and_install_deps() {
    detect_distro
    local deps_ok=1
    # 检测核心依赖：bash
    if ! command -v bash &> /dev/null; then
        zenity --question --title="依赖缺失" --width=400 --text="未检测到bash，是否自动安装？"
        if [ $? -eq 0 ]; then
            $PM_INSTALL bash || { zenity --error --text="bash安装失败！"; exit 1; }
        else
            zenity --error --text="缺少bash，脚本无法运行！"; exit 1;
        fi
    fi
    # 检测核心依赖：zenity（图形化必装）
    if ! command -v zenity &> /dev/null; then
        zenity --question --title="依赖缺失" --width=400 --text="未检测到图形化依赖zenity，是否自动安装？"
        if [ $? -eq 0 ]; then
            $PM_INSTALL zenity || { zenity --error --text="zenity安装失败！"; exit 1; }
        else
            zenity --error --text="缺少zenity，无法显示图形界面！"; exit 1;
        fi
    fi
    # 检测核心依赖：systemctl
    if ! command -v systemctl &> /dev/null; then
        zenity --error --title="错误" --width=400 --text="系统无systemd，不支持本脚本！"
        exit 1
    fi
}

# ===================== 获取当前正在使用的显示管理器 =====================
get_current_dm() {
    current_dm=$(systemctl get-default | grep -oP '^[a-zA-Z]+(?=@)')
    if [ -z "$current_dm" ] || [ "$current_dm" == "" ]; then
        echo "未知显示管理器"
    else
        echo "$current_dm"
    fi
}

# ===================== 显示管理器列表（名称+中文描述） =====================
DM_LIST=("gdm" "sddm" "lightdm" "lxdm")
DM_DESC=("GNOME专属 显示管理器(GDM)" "KDE专属 显示管理器(SDDM)" "轻量级 显示管理器(LightDM)" "LXDE专属 显示管理器(LXDM)")

# ===================== 检查是否ROOT权限 =====================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        zenity --error --title="权限不足" --width=400 --text="⚠️ 必须使用【管理员权限】运行本脚本！\n正确命令：sudo bash $0"
        exit 1
    fi
}

# ===================== 主程序入口 =====================
main() {
    # 第一步：检查ROOT权限
    check_root
    # 第二步：自动检测+安装依赖（核心新增）
    check_and_install_deps
    # 第三步：图形化主菜单循环
    while true; do
        current_dm=$(get_current_dm)
        choice=$(zenity --list \
            --title="✨ 显示管理器 图形化管理工具 ✨" \
            --width=600 --height=400 \
            --ok-label="确定" --cancel-label="退出" \
            --text="\n📌 当前系统：$DISTRO\n📌 当前使用的显示管理器：<b>$current_dm</b>\n\n请选择要执行的操作：" \
            --column="序号" --column="功能说明" \
            1 "📋 查看系统中【已安装】的所有显示管理器" \
            2 "📥 安装 指定的显示管理器（4种可选）" \
            3 "🔄 切换 默认显示管理器（一键生效）" \
            4 "🗑️ 卸载 不使用的显示管理器（安全防误删）" \
            5 "🚪 退出程序")

        # 点击取消/关闭窗口，直接退出
        if [ -z "$choice" ]; then
            zenity --info --title="提示" --width=300 --text="感谢使用！"
            exit 0
        fi

        # 功能分支
        case $choice in
            1) # 查看已安装的DM
                installed_dms=()
                for i in "${!DM_LIST[@]}"; do
                    dm=${DM_LIST[$i]}
                    desc=${DM_DESC[$i]}
                    if command -v $dm &> /dev/null || pacman -Qs $dm &> /dev/null || apt -qq list $dm 2>/dev/null | grep -q installed; then
                        installed_dms+=("$dm - $desc")
                    fi
                done
                if [ ${#installed_dms[@]} -eq 0 ]; then
                    zenity --info --title="提示" --width=350 --text="系统中未安装任何显示管理器！"
                else
                    zenity --list --title="✅ 已安装的显示管理器" --width=600 --height=300 \
                    --column="已安装列表" "${installed_dms[@]}"
                fi
                ;;

            2) # 安装显示管理器
                selected_dm=$(zenity --list --title="📥 选择要安装的显示管理器" --width=600 --height=350 \
                    --text="请选择需要安装的显示管理器，选择后将自动下载安装" \
                    --column="管理器名称" --column="详细描述" "${DM_LIST[@]}" "${DM_DESC[@]}")
                if [ -n "$selected_dm" ]; then
                    if command -v $selected_dm &> /dev/null || pacman -Qs $selected_dm &> /dev/null || apt -qq list $selected_dm 2>/dev/null | grep -q installed; then
                        zenity --info --title="提示" --width=350 --text="$selected_dm 已经安装，无需重复安装！"
                    else
                        zenity --question --title="确认安装" --width=400 --text="是否确认安装【$selected_dm】？"
                        if [ $? -eq 0 ]; then
                            $PM_INSTALL $selected_dm
                            if [ $? -eq 0 ]; then
                                zenity --info --title="成功" --width=350 --text="$selected_dm 安装完成！"
                            else
                                zenity --error --title="失败" --width=350 --text="$selected_dm 安装失败，请检查网络！"
                            fi
                        fi
                    fi
                fi
                ;;

            3) # 切换显示管理器
                installed_dms=()
                dm_names=()
                for i in "${!DM_LIST[@]}"; do
                    dm=${DM_LIST[$i]}
                    desc=${DM_DESC[$i]}
                    if command -v $dm &> /dev/null || pacman -Qs $dm &> /dev/null || apt -qq list $dm 2>/dev/null | grep -q installed; then
                        installed_dms+=("$dm" "$desc")
                        dm_names+=("$dm")
                    fi
                done
                if [ ${#installed_dms[@]} -eq 0 ]; then
                    zenity --error --title="错误" --width=350 --text="请先安装至少一个显示管理器！"
                else
                    selected_dm=$(zenity --list --title="🔄 切换显示管理器" --width=600 --height=350 \
                        --text="选择后将自动禁用旧DM，启用新DM，重启系统后生效！" \
                        --column="管理器名称" --column="详细描述" "${installed_dms[@]}")
                    if [ -n "$selected_dm" ]; then
                        current_dm=$(get_current_dm)
                        if [ "$selected_dm" == "$current_dm" ]; then
                            zenity --info --title="提示" --width=350 --text="$selected_dm 已是当前默认显示管理器！"
                        else
                            zenity --question --title="确认切换" --width=400 --text="是否确认切换为【$selected_dm】？\n⚠️ 切换后需要重启系统生效！"
                            if [ $? -eq 0 ]; then
                                # 禁用当前DM
                                if [ "$current_dm" != "未知显示管理器" ]; then
                                    systemctl disable --now $current_dm.service &> /dev/null
                                fi
                                # 启用新DM
                                systemctl enable --now $selected_dm.service
                                if [ $? -eq 0 ]; then
                                    zenity --info --title="成功" --width=400 --text="已成功切换为 $selected_dm！\n👉 重启系统后即可生效！"
                                else
                                    zenity --error --title="失败" --width=400 --text="$selected_dm 切换失败，请手动执行命令！"
                                fi
                            fi
                        fi
                    fi
                fi
                ;;

            4) # 卸载显示管理器
                installed_dms=()
                dm_names=()
                for i in "${!DM_LIST[@]}"; do
                    dm=${DM_LIST[$i]}
                    desc=${DM_DESC[$i]}
                    if command -v $dm &> /dev/null || pacman -Qs $dm &> /dev/null || apt -qq list $dm 2>/dev/null | grep -q installed; then
                        installed_dms+=("$dm" "$desc")
                        dm_names+=("$dm")
                    fi
                done
                if [ ${#installed_dms[@]} -eq 0 ]; then
                    zenity --error --title="错误" --width=350 --text="无已安装的显示管理器可卸载！"
                else
                    selected_dm=$(zenity --list --title="🗑️ 卸载显示管理器" --width=600 --height=350 \
                        --text="⚠️ 安全提醒：禁止卸载当前正在使用的显示管理器！\n卸载前请先切换到其他DM！" \
                        --column="管理器名称" --column="详细描述" "${installed_dms[@]}")
                    if [ -n "$selected_dm" ]; then
                        current_dm=$(get_current_dm)
                        if [ "$selected_dm" == "$current_dm" ]; then
                            zenity --error --title="禁止操作" --width=400 --text="❌ 无法卸载当前正在使用的【$selected_dm】！\n请先切换到其他显示管理器再卸载！"
                        else
                            zenity --question --title="确认卸载" --width=400 --text="是否确认卸载【$selected_dm】？\n卸载后无法恢复，谨慎操作！"
                            if [ $? -eq 0 ]; then
                                if [ $PM == "pacman" ]; then
                                    sudo pacman -Rns --noconfirm $selected_dm
                                elif [ $PM == "apt" ]; then
                                    sudo apt remove -y $selected_dm
                                elif [ $PM == "dnf" ]; then
                                    sudo dnf remove -y $selected_dm
                                fi
                                if [ $? -eq 0 ]; then
                                    zenity --info --title="成功" --width=350 --text="$selected_dm 卸载完成！"
                                else
                                    zenity --error --title="失败" --width=350 --text="$selected_dm 卸载失败，可能被其他程序占用！"
                                fi
                            fi
                        fi
                    fi
                fi
                ;;

            5) # 退出
                zenity --info --title="再见" --width=300 --text="感谢使用，祝您使用愉快！"
                exit 0
                ;;
        esac
    done
}

# 启动主程序
main
