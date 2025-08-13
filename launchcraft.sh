#!/bin/bash

set -e  # 오류 발생 시 스크립트 종료

# 시스템 언어 확인 (가장 먼저 실행하여 모든 메시지에 적용)
if [[ "$(locale | grep LANG= | cut -d= -f2)" == ko_* ]]; then
    LANGUAGE="ko"
else
    LANGUAGE="en"
fi

# 필요한 패키지 체크 및 설치
check_and_install_packages() {
    # Flatpak 샌드박스 환경 감지
    if [ -f /etc/os-release ]; then
        if grep -q "org.freedesktop.platform" /etc/os-release || [ -n "$FLATPAK_ID" ]; then
            if [[ "$LANGUAGE" == "ko" ]]; then
                echo "================================================================================"
                echo "❌ 이 스크립트는 현재 터미널(Flatpak)에서 실행할 수 없습니다."
                echo
                echo "이유: 현재 터미널은 외부와 격리된 '샌드박스' 환경입니다."
                echo "      이곳에서는 시스템에 필요한 프로그램을 설치할 수 없습니다."
                echo
                echo "해결책: "
                echo "  1. 현재 터미널 창을 닫아주세요."
                echo "  2. 바탕화면이나 애플리케이션 메뉴에서 '터미널' 또는 '콘솔'을 새로 열어주세요."
                echo "  3. 새로 연 터미널에서 이 스크립트를 다시 실행해주세요."
                echo "================================================================================"
            else
                echo "================================================================================"
                echo "❌ This script cannot be run from the current terminal (Flatpak)."
                echo
                echo "Reason: This is a 'sandbox' environment, isolated from your main system."
                echo "        Installing required system packages is not possible here."
                echo
                echo "Solution:"
                echo "  1. Please close this terminal window."
                echo "  2. Open a new 'Terminal' or 'Console' from your desktop or applications menu."
                echo "  3. In the new terminal, run this script again."
                echo "================================================================================"
            fi
            exit 1
        fi
    fi

    local missing_commands=()
    # wget 또는 curl 중 하나는 있어야 함
    if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
        missing_commands+=("wget/curl")
    fi
    # 기타 필요한 명령어 체크
    if ! command -v gtk-update-icon-cache &>/dev/null; then
        missing_commands+=("gtk-update-icon-cache")
    fi
    if ! command -v update-desktop-database &>/dev/null; then
        missing_commands+=("update-desktop-database")
    fi
    if ! command -v xprop &>/dev/null; then
        missing_commands+=("xprop")
    fi
    if ! command -v xdg-user-dir &>/dev/null; then
        missing_commands+=("xdg-user-dir")
    fi

    # 누락된 명령어가 없으면 함수 종료
    if [ ${#missing_commands[@]} -eq 0 ]; then
        return 0
    fi

    local packages_to_install=()
    local pm=""
    # /etc/os-release를 통해 배포판 확인
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|mint|linuxmint)
                pm="apt"
                ;;
            fedora|centos|rhel)
                pm="dnf"
                ;;
            arch|manjaro)
                pm="pacman"
                ;;
            opensuse*|sles)
                pm="zypper"
                ;;
        esac
    fi

    # OS 확인 실패 시, 명령어로 다시 확인 (Fallback)
    if [ -z "$pm" ]; then
        if type apt &>/dev/null; then pm="apt";
        elif type dnf &>/dev/null; then pm="dnf";
        elif type pacman &>/dev/null; then pm="pacman";
        elif type zypper &>/dev/null; then pm="zypper";
        fi
    fi

    if [ -n "$pm" ]; then
        # 패키지 관리자에 따라 필요한 패키지 목록 생성
        for cmd in "${missing_commands[@]}"; do
            case "$pm:$cmd" in
                "apt:wget/curl") packages_to_install+=("wget") ;;
                "apt:gtk-update-icon-cache") packages_to_install+=("libgtk-3-bin") ;;
                "apt:update-desktop-database") packages_to_install+=("desktop-file-utils") ;;
                "apt:xprop") packages_to_install+=("x11-utils") ;;
                "apt:xdg-user-dir") packages_to_install+=("xdg-user-dirs") ;;

                "dnf:wget/curl") packages_to_install+=("wget") ;;
                "dnf:gtk-update-icon-cache") packages_to_install+=("gtk3") ;;
                "dnf:update-desktop-database") packages_to_install+=("desktop-file-utils") ;;
                "dnf:xprop") packages_to_install+=("xorg-x11-utils") ;;
                "dnf:xdg-user-dir") packages_to_install+=("xdg-user-dirs") ;;

                "pacman:wget/curl") packages_to_install+=("wget") ;;
                "pacman:gtk-update-icon-cache") packages_to_install+=("gtk3") ;;
                "pacman:update-desktop-database") packages_to_install+=("desktop-file-utils") ;;
                "pacman:xprop") packages_to_install+=("xorg-xprop") ;;
                "pacman:xdg-user-dir") packages_to_install+=("xdg-user-dirs") ;;

                "zypper:wget/curl") packages_to_install+=("wget") ;;
                "zypper:gtk-update-icon-cache") packages_to_install+=("gtk3-tools") ;;
                "zypper:update-desktop-database") packages_to_install+=("desktop-file-utils") ;;
                "zypper:xprop") packages_to_install+=("xorg-xprop") ;;
                "zypper:xdg-user-dir") packages_to_install+=("xdg-user-dirs") ;;
            esac
        done
        
        # 중복된 패키지 제거
        packages_to_install=($(printf "%s\n" "${packages_to_install[@]}" | sort -u))

        if [ ${#packages_to_install[@]} -ne 0 ]; then
            if [[ "$LANGUAGE" == "ko" ]]; then echo "⚠️ 필요한 패키지를 설치합니다..."; else echo "⚠️ Installing required packages..."; fi
            case "$pm" in
                "apt") sudo apt update && sudo apt install -y "${packages_to_install[@]}" ;;
                "dnf") sudo dnf install -y "${packages_to_install[@]}" ;;
                "pacman") sudo pacman -S --noconfirm "${packages_to_install[@]}" ;;
                "zypper") sudo zypper install -y "${packages_to_install[@]}" ;;
            esac
        fi
    else
        # 패키지 관리자를 찾을 수 없는 경우
        if [[ "$LANGUAGE" == "ko" ]]; then
            INSTALL_ERROR="❌ 패키지 관리자를 찾을 수 없습니다. 수동으로 다음 패키지/명령어를 설치해주세요:"
        else
            INSTALL_ERROR="❌ Package manager not found. Please install these packages/commands manually:"
        fi
        echo "$INSTALL_ERROR"
        printf '%s\n' "${missing_commands[@]}"
        exit 1
    fi
}

# 언어 옵션 및 AppImage/URL 입력을 위한 변수 초기화
INPUT=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l)
            shift
            if [[ -n "$1" ]]; then
                case "$1" in
                    "ko") LANGUAGE="ko" ;;
                    "en") LANGUAGE="en" ;;
                    *) echo "Invalid language option. Use '-l en' or '-l ko'."; exit 1 ;;
                esac
                shift
            else
                echo "Error: Missing language argument for -l option."
                exit 1
            fi
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            fi
            shift
            ;;
    esac
done

# 언어 설정이 완료된 후 패키지 체크 실행
check_and_install_packages

# 다국어 메시지 설정
if [[ "$LANGUAGE" == "ko" ]]; then
    MSG_INPUT="🔍 입력값 분석 중..."
    MSG_ERROR_INPUT="❌ 오류: AppImage 파일 경로 또는 웹사이트 URL을 입력하세요."
    MSG_WHERE_TO_ADD="📌 어디에 등록하시겠습니까?"
    MSG_OPTION_1="1) 작업 표시줄 (Dock)"
    MSG_OPTION_2="2) 바탕화면 (Desktop)"
    MSG_OPTION_3="3) 둘 다"
    MSG_SELECT="선택 (1, 2, 또는 3): "
    MSG_INVALID_OPTION="❌ 오류: 올바른 선택이 아닙니다."
    MSG_PROCESSING="✅ 처리 중..."
    MSG_SUCCESS="🎉 성공적으로 등록되었습니다!"
    MSG_CLICK_WINDOW="🖱️ 앱이 실행되면 십자 모양(+) 커서로 해당 앱 창을 클릭해주세요..."
    MSG_WM_CLASS="❗ WM_CLASS를 자동으로 감지하지 못했습니다. 앱이 실행되면 창을 선택해주세요."
else
    MSG_INPUT="🔍 Analyzing input..."
    MSG_ERROR_INPUT="❌ Error: Please provide an AppImage file path or a website URL."
    MSG_WHERE_TO_ADD="📌 Where do you want to add this?"
    MSG_OPTION_1="1) Taskbar (Dock)"
    MSG_OPTION_2="2) Desktop"
    MSG_OPTION_3="3) Both"
    MSG_SELECT="Select (1, 2, or 3): "
    MSG_INVALID_OPTION="❌ Error: Invalid selection."
    MSG_PROCESSING="✅ Processing..."
    MSG_SUCCESS="🎉 Successfully added!"
    MSG_CLICK_WINDOW="🖱️ When the app launches, click its window with the crosshair (+) cursor..."
    MSG_WM_CLASS="❗ Could not detect WM_CLASS automatically. Please select the window when the app launches."
fi

echo "$MSG_INPUT"

if [[ -z "$INPUT" ]]; then
    echo "$MSG_ERROR_INPUT"
    exit 1
fi

# 설치 위치 선택
echo "$MSG_WHERE_TO_ADD"
echo "$MSG_OPTION_1"
echo "$MSG_OPTION_2"
echo "$MSG_OPTION_3"
read -p "$MSG_SELECT" TARGET

if [[ "$TARGET" == "1" ]]; then
    ADD_TO_DOCK=true
    ADD_TO_DESKTOP=false
elif [[ "$TARGET" == "2" ]]; then
    ADD_TO_DOCK=false
    ADD_TO_DESKTOP=true
elif [[ "$TARGET" == "3" ]]; then
    ADD_TO_DOCK=true
    ADD_TO_DESKTOP=true
else
    echo "$MSG_INVALID_OPTION"
    exit 1
fi

echo "$MSG_PROCESSING"

# AppImage 처리
if [[ "$INPUT" == *.AppImage ]]; then
    APPIMAGE_PATH="$(realpath "$INPUT")"
    if [[ ! -f "$APPIMAGE_PATH" ]]; then
        echo "❌ Error: File not found - $APPIMAGE_PATH"
        exit 1
    fi

    APP_NAME=$(basename "$APPIMAGE_PATH" | sed 's/.AppImage//g')
    APP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons"
    ICON_DEST="$ICON_DIR/$APP_NAME.png"

    # 사용자 데스크톱 디렉토리 확인 (XDG 표준 사용)
    if [[ "$ADD_TO_DESKTOP" == true ]]; then
        if command -v xdg-user-dir &>/dev/null; then
            DESKTOP_DIR=$(xdg-user-dir DESKTOP)
        else
            DESKTOP_DIR="$HOME/Desktop"
        fi
    else
        DESKTOP_DIR=""
    fi

    # 바로가기 및 아이콘을 저장할 디렉토리 생성 (없는 경우)
    mkdir -p "$APP_DIR"
    if [[ -n "$DESKTOP_DIR" ]]; then
        mkdir -p "$DESKTOP_DIR"
    fi
    mkdir -p "$ICON_DIR"

    # 기존 파일들 삭제
    rm -f "$APP_DIR/$APP_NAME.desktop"
    rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
    rm -f "$ICON_DIR/$APP_NAME.png"

    chmod +x "$APPIMAGE_PATH"

    # WM_CLASS 감지 (타임아웃, GPU 비활성화, 충돌 방지, 대화형)
    echo "$MSG_CLICK_WINDOW"
    
    # set -e를 잠시 비활성화하여 AppImage 충돌이 스크립트를 중단시키지 않도록 함
    set +e
    # AppImage를 GPU 비활성화 및 충돌 방지 옵션과 함께 백그라운드에서 실행
    "$APPIMAGE_PATH" --no-sandbox --disable-gpu &
    APP_PID=$!
    # set -e를 다시 활성화
    set -e
    
    # 앱이 실행되고 창을 띄울 시간을 줌
    sleep 5

    # AppImage 프로세스가 여전히 실행 중인지 확인
    if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
        # 프로세스가 죽었으면, 충돌 메시지를 보여주고 기본값으로 진행
        if [[ "$LANGUAGE" == "ko" ]]; then
            echo "❗ AppImage 프로세스가 충돌했거나 시작하지 못했습니다. GPU 관련 문제일 수 있습니다. 기본값으로 계속합니다."
        else
            echo "❗ AppImage process crashed or failed to start. This might be a GPU issue. Continuing with default values."
        fi
        WM_CLASS="$APP_NAME"
    else
        # 프로세스가 살아있으면, 대화형으로 WM_CLASS를 얻으려고 시도 (15초 타임아웃)
        WM_CLASS_OUTPUT=$(timeout 15 xprop WM_CLASS 2>/dev/null || true)
        
        # AppImage 프로세스 종료
        kill "$APP_PID" >/dev/null 2>&1 || true

        # WM_CLASS 추출
        if [[ $WM_CLASS_OUTPUT == *"WM_CLASS"* ]]; then
            WM_CLASS=$(echo "$WM_CLASS_OUTPUT" | awk -F '"' '{print $4}')
        else
            # 감지 실패 시 (타임아웃 포함) 기본값 사용
            if [[ "$LANGUAGE" == "ko" ]]; then
                echo "❗ 창 선택 시간이 초과되었거나 감지에 실패했습니다. 기본값으로 계속합니다."
            else
                echo "❗ Window selection timed out or failed. Continuing with default values."
            fi
            WM_CLASS="$APP_NAME"
        fi
    fi

    # 아이콘 파일 복사 (타임아웃 및 충돌 방지 로직 추가)
    if [[ -f "$APPIMAGE_PATH" ]]; then
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        # set -e를 잠시 비활성화하여 아이콘 추출 중 충돌이 발생해도 스크립트가 중단되지 않도록 함
        set +e
        # 10초 타임아웃 추가
        timeout 10 "$APPIMAGE_PATH" --appimage-extract >/dev/null 2>&1
        EXTRACT_STATUS=$?
        set -e

        if [ $EXTRACT_STATUS -eq 0 ]; then
            # 추출 성공 시 아이콘 검색 및 복사
            ICON_PATH=$(find "$TEMP_DIR/squashfs-root" -type f \( -name "*.png" -o -name "*.svg" \) -print -quit 2>/dev/null)
            if [[ -n "$ICON_PATH" ]]; then
                cp "$ICON_PATH" "$ICON_DEST"
            fi
        elif [ $EXTRACT_STATUS -eq 124 ]; then # 124는 timeout의 종료 코드
            # 타임아웃 발생 시 사용자에게 알림
            if [[ "$LANGUAGE" == "ko" ]]; then
                echo "❗ 아이콘 추출 시간이 초과되었습니다. 기본 아이콘으로 계속합니다."
            else
                echo "❗ Icon extraction timed out. Continuing with a default icon."
            fi
        else
            # 그 외 다른 오류로 추출 실패 시 사용자에게 알림
            if [[ "$LANGUAGE" == "ko" ]]; then
                echo "❗ 아이콘 추출에 실패했습니다. 기본 아이콘으로 계속합니다."
            else
                echo "❗ Icon extraction failed. Continuing with a default icon."
            fi
        fi
        
        # 임시 디렉토리 정리
        cd - >/dev/null
        rm -rf "$TEMP_DIR"
    fi

    # 아이콘이 없는 경우 기본 아이콘 사용
    if [[ ! -f "$ICON_DEST" ]]; then
        ICON_DEST="application-x-executable"
    fi

# URL 처리
elif [[ "$INPUT" == http* ]]; then
    URL="$INPUT"
    APP_NAME=$(echo "$URL" | awk -F[/:] '{print $4}' | sed 's/www.//g' | cut -d. -f1)
    APP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons"
    ICON_DEST="$ICON_DIR/$APP_NAME.png"

    # 사용자 데스크톱 디렉토리 확인 (XDG 표준 사용)
    if [[ "$ADD_TO_DESKTOP" == true ]]; then
        if command -v xdg-user-dir &>/dev/null; then
            DESKTOP_DIR=$(xdg-user-dir DESKTOP)
        else
            DESKTOP_DIR="$HOME/Desktop"
        fi
    else
        DESKTOP_DIR=""
    fi

    # 바로가기 및 아이콘을 저장할 디렉토리 생성 (없는 경우)
    mkdir -p "$APP_DIR"
    if [[ -n "$DESKTOP_DIR" ]]; then
        mkdir -p "$DESKTOP_DIR"
    fi
    mkdir -p "$ICON_DIR"

    # 기존 파일들 삭제
    rm -f "$APP_DIR/$APP_NAME.desktop"
    rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
    rm -f "$ICON_DIR/$APP_NAME.png"

    if command -v google-chrome &>/dev/null; then
        BROWSER="google-chrome"
    elif command -v chromium-browser &>/dev/null; then
        BROWSER="chromium-browser"
    elif command -v microsoft-edge &>/dev/null; then
        BROWSER="microsoft-edge"
    elif command -v firefox &>/dev/null; then
        BROWSER="firefox"
    else
        echo "❌ Error: A web browser is required."
        exit 1
    fi

    # 파비콘 다운로드
    if command -v curl &>/dev/null; then
        curl -s -L "https://www.google.com/s2/favicons?sz=256&domain=$URL" -o "$ICON_DEST"
    elif command -v wget &>/dev/null; then
        wget -q "https://www.google.com/s2/favicons?sz=256&domain=$URL" -O "$ICON_DEST"
    fi

    # 파비콘 다운로드 실패 시 기본 아이콘 사용
    if [[ ! -s "$ICON_DEST" ]]; then
        ICON_DEST="web-browser"
    fi
else
    echo "❌ Error: Invalid input format."
    exit 1
fi

# 데스크톱 파일 생성
if [[ "$ADD_TO_DOCK" == true ]]; then
    DESKTOP_FILE_DOCK="$APP_DIR/$APP_NAME.desktop"
fi
if [[ "$ADD_TO_DESKTOP" == true && -n "$DESKTOP_DIR" ]]; then
    DESKTOP_FILE_DESKTOP="$DESKTOP_DIR/$APP_NAME.desktop"
fi

for DEST in "$DESKTOP_FILE_DOCK" "$DESKTOP_FILE_DESKTOP"; do
    if [[ -n "$DEST" ]]; then
        # URL인 경우와 AppImage인 경우 구분
        if [[ "$INPUT" == http* ]]; then
            cat > "$DEST" <<EOL
[Desktop Entry]
Name=$APP_NAME
Exec=$BROWSER --new-window "$URL"
Icon=$ICON_DEST
Terminal=false
Type=Application
Categories=Network;X-Internet;
StartupWMClass=$APP_NAME
EOL
        else
            cat > "$DEST" <<EOL
[Desktop Entry]
Name=$APP_NAME
Exec="$APPIMAGE_PATH" --no-sandbox --disable-gpu
Icon=$ICON_DEST
Terminal=false
Type=Application
Categories=Utility;Application;
StartupWMClass=${WM_CLASS:-"$APP_NAME"}
EOL
        fi

        chmod +x "$DEST"
    fi
done

update-desktop-database "$APP_DIR"
gtk-update-icon-cache

if [[ "$ADD_TO_DOCK" == true ]] && command -v gsettings &>/dev/null; then
    FAVS=$(gsettings get org.gnome.shell favorite-apps)
    if [[ $FAVS != *"$APP_NAME.desktop"* ]]; then
        NEW_FAVS=$(echo "$FAVS" | sed "s/]$/, '$APP_NAME.desktop']/")
        gsettings set org.gnome.shell favorite-apps "$NEW_FAVS"
    fi
fi

echo "$MSG_SUCCESS"
