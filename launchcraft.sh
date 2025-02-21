#!/bin/bash

set -e  # 오류 발생 시 스크립트 종료

# 필요한 패키지 체크 및 설치
check_and_install_packages() {
    local missing_packages=()
    
    # wget 또는 curl 체크
    if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
        missing_packages+=("wget")
    fi
    
    # gtk-update-icon-cache 체크
    if ! command -v gtk-update-icon-cache &>/dev/null; then
        missing_packages+=("gtk-update-icon-cache")
    fi
    
    # update-desktop-database 체크
    if ! command -v update-desktop-database &>/dev/null; then
        missing_packages+=("desktop-file-utils")
    fi
    
    # xprop 체크
    if ! command -v xprop &>/dev/null; then
        missing_packages+=("xprop")
    fi
    
    # 누락된 패키지가 있으면 설치
    if [ ${#missing_packages[@]} -ne 0 ]; then
        if [[ "$LANGUAGE" == "ko" ]]; then
            echo "⚠️ 필요한 패키지를 설치합니다..."
            INSTALL_ERROR="❌ 패키지 관리자를 찾을 수 없습니다. 수동으로 다음 패키지를 설치해주세요:"
        else
            echo "⚠️ Installing required packages..."
            INSTALL_ERROR="❌ Package manager not found. Please install these packages manually:"
        fi

        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "${missing_packages[@]}"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${missing_packages[@]}"
        else
            echo "$INSTALL_ERROR"
            printf '%s\n' "${missing_packages[@]}"
            exit 1
        fi
    fi
}

# 스크립트 시작 시 패키지 체크
check_and_install_packages

# 시스템 언어 확인 (기본값)
if [[ "$(locale | grep LANG= | cut -d= -f2)" == ko_* ]]; then
    DEFAULT_LANGUAGE="ko"
else
    DEFAULT_LANGUAGE="en"
fi

# 언어 기본값 설정
LANGUAGE="$DEFAULT_LANGUAGE"

# 전체 사용법 메시지
FULL_USAGE_KO="사용법: $0 [-l en|ko] <AppImage 파일 경로 | URL>
옵션:
  -l en   영어로 표시 (기본값)
  -l ko   한국어로 표시
예시:
  $0 /home/user/MyApp.AppImage    (AppImage 등록)
  $0 -l ko /home/user/MyApp.AppImage  (한국어로 AppImage 등록)
  $0 https://chat.openai.com      (웹사이트 바로가기 등록)
  $0 -l ko https://chat.openai.com (한국어로 웹사이트 바로가기 등록)"

FULL_USAGE_EN="Usage: $0 [-l en|ko] <AppImage file path | URL>
Options:
  -l en   Set language to English (default)
  -l ko   Set language to Korean
Examples:
  $0 /home/user/MyApp.AppImage    (Add an AppImage)
  $0 -l ko /home/user/MyApp.AppImage  (Add an AppImage with Korean messages)
  $0 https://chat.openai.com      (Add a website shortcut)
  $0 -l ko https://chat.openai.com (Add a website shortcut with Korean messages)"

# 언어 옵션 확인 (-l 옵션이 있으면 해당 언어로 강제 설정)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l)
            shift
            case "$1" in
                "ko") LANGUAGE="ko" ;;
                "en") LANGUAGE="en" ;;
                *) echo "Invalid language option. Use '-l en' or '-l ko'."; exit 1 ;;
            esac
            shift
            ;;
        *)
            INPUT="$1"
            shift
            ;;
    esac
done

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
    FULL_USAGE="$FULL_USAGE_KO"
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
    FULL_USAGE="$FULL_USAGE_EN"
fi

echo "$MSG_INPUT"

if [[ -z "$INPUT" ]]; then
    echo "$MSG_ERROR_INPUT"
    echo "$FULL_USAGE"
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
    DESKTOP_DIR="$HOME/Desktop"
    ICON_DIR="$HOME/.local/share/icons"
    ICON_DEST="$ICON_DIR/$APP_NAME.png"

    # 기존 파일들 삭제
    rm -f "$APP_DIR/$APP_NAME.desktop"
    rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
    rm -f "$ICON_DIR/$APP_NAME.png"

    chmod +x "$APPIMAGE_PATH"

    # 아이콘 디렉토리 생성 (없는 경우)
    mkdir -p "$ICON_DIR"

    # WM_CLASS 자동 감지 시도
    echo "$MSG_CLICK_WINDOW"
    "$APPIMAGE_PATH" &  
    sleep 3
    WM_CLASS=$(xprop WM_CLASS | awk -F '"' '{print $2}' | head -n 1)
    pkill -f "$APPIMAGE_PATH"

    if [[ -z "$WM_CLASS" || "$WM_CLASS" == "xprop:"* ]]; then
        echo "$MSG_WM_CLASS"
        WM_CLASS="$APP_NAME"
    fi

    # 아이콘 파일 복사
    if [[ -f "$APPIMAGE_PATH" ]]; then
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        "$APPIMAGE_PATH" --appimage-extract >/dev/null 2>&1
        ICON_PATH=$(find "$TEMP_DIR/squashfs-root" -type f -name "*.png" | head -n 1)
        if [[ -n "$ICON_PATH" ]]; then
            cp "$ICON_PATH" "$ICON_DEST"
        fi
        rm -rf "$TEMP_DIR"
        cd - >/dev/null
    fi

    # 아이콘이 없는 경우 기본 아이콘 사용
    if [[ ! -f "$ICON_DEST" ]]; then
        ICON_DEST="application-x-executable"
    fi

# **2️⃣ URL 처리**
elif [[ "$INPUT" == http* ]]; then
    URL="$INPUT"
    APP_NAME=$(echo "$URL" | awk -F[/:] '{print $4}' | sed 's/www.//g')
    APP_DIR="$HOME/.local/share/applications"
    DESKTOP_DIR="$HOME/Desktop"
    ICON_DIR="$HOME/.local/share/icons"
    ICON_DEST="$ICON_DIR/$APP_NAME.png"

    # 기존 파일들 삭제
    rm -f "$APP_DIR/$APP_NAME.desktop"
    rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
    rm -f "$ICON_DIR/$APP_NAME.png"

    # 아이콘 디렉토리 생성 (없는 경우)
    mkdir -p "$ICON_DIR"

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

    # 파비콘 다운로드 시도 (여러 소스에서 시도)
    if command -v wget &>/dev/null; then
        # 1. HTML에서 고해상도 아이콘 링크 찾기 (더 좋은 품질의 아이콘을 먼저 시도)
        if ! wget -q "$URL" -O- | grep -i '<link.*rel=["'"'"'].*icon.*["'"'"']' > "$ICON_DEST.html" 2>/dev/null; then
            echo "⚠️ 웹사이트 접근에 실패했습니다. 기본 아이콘을 사용합니다."
            ICON_DEST="web-browser"
        else
            ICON_URL=$(grep -i "apple-touch-icon" "$ICON_DEST.html" | head -n 1 | sed -n 's/.*href=["'"'"']\([^"'"'"']*\).*/\1/p')
            if [[ -z "$ICON_URL" ]]; then
                ICON_URL=$(grep -i "icon" "$ICON_DEST.html" | head -n 1 | sed -n 's/.*href=["'"'"']\([^"'"'"']*\).*/\1/p')
            fi
            
            # 상대 URL을 절대 URL로 변환
            if [[ "$ICON_URL" == /* ]]; then
                ICON_URL="https://${URL#*://}$ICON_URL"
            elif [[ "$ICON_URL" != http* ]]; then
                ICON_URL="https://${URL#*://}/$ICON_URL"
            fi
            
            # 발견된 아이콘 다운로드 시도
            if [[ -n "$ICON_URL" ]]; then
                if ! wget -q "$ICON_URL" -O "$ICON_DEST.found" 2>/dev/null; then
                    echo "⚠️ 고해상도 아이콘 다운로드에 실패했습니다. 다른 방법을 시도합니다."
                fi
            fi

            # 2. 웹사이트 root의 favicon.ico 시도
            if ! wget -q "https://${URL#*://}/favicon.ico" -O "$ICON_DEST.ico" 2>/dev/null; then
                echo "⚠️ favicon.ico 다운로드에 실패했습니다. 다른 방법을 시도합니다."
            fi
            
            # 가장 큰 파일 선택
            for f in "$ICON_DEST.ico" "$ICON_DEST.found"; do
                if [[ -f "$f" && ( ! -f "$ICON_DEST" || $(stat -f%z "$f") -gt $(stat -f%z "$ICON_DEST") ) ]]; then
                    mv "$f" "$ICON_DEST"
                else
                    rm -f "$f" 2>/dev/null
                fi
            done
            
            # 3. 모든 시도 실패시 Google favicon 서비스 사용
            if [[ ! -s "$ICON_DEST" ]]; then
                if ! wget -q "https://www.google.com/s2/favicons?sz=256&domain=$URL" -O "$ICON_DEST" 2>/dev/null; then
                    echo "⚠️ Google favicon 서비스 접근에 실패했습니다. 기본 아이콘을 사용합니다."
                    ICON_DEST="web-browser"
                fi
            fi
            
            # 임시 파일 정리
            rm -f "$ICON_DEST.html" 2>/dev/null
        fi
    elif command -v curl &>/dev/null; then
        # 1. HTML에서 고해상도 아이콘 링크 찾기
        if ! curl -s "$URL" | grep -i '<link.*rel=["'"'"'].*icon.*["'"'"']' > "$ICON_DEST.html" 2>/dev/null; then
            echo "⚠️ 웹사이트 접근에 실패했습니다. 기본 아이콘을 사용합니다."
            ICON_DEST="web-browser"
        else
            ICON_URL=$(grep -i "apple-touch-icon" "$ICON_DEST.html" | head -n 1 | sed -n 's/.*href=["'"'"']\([^"'"'"']*\).*/\1/p')
            if [[ -z "$ICON_URL" ]]; then
                ICON_URL=$(grep -i "icon" "$ICON_DEST.html" | head -n 1 | sed -n 's/.*href=["'"'"']\([^"'"'"']*\).*/\1/p')
            fi
            
            # 상대 URL을 절대 URL로 변환
            if [[ "$ICON_URL" == /* ]]; then
                ICON_URL="https://${URL#*://}$ICON_URL"
            elif [[ "$ICON_URL" != http* ]]; then
                ICON_URL="https://${URL#*://}/$ICON_URL"
            fi
            
            # 발견된 아이콘 다운로드 시도
            if [[ -n "$ICON_URL" ]]; then
                if ! curl -s "$ICON_URL" -o "$ICON_DEST.found" 2>/dev/null; then
                    echo "⚠️ 고해상도 아이콘 다운로드에 실패했습니다. 다른 방법을 시도합니다."
                fi
            fi

            # 2. 웹사이트 root의 favicon.ico 시도
            if ! curl -s "https://${URL#*://}/favicon.ico" -o "$ICON_DEST.ico" 2>/dev/null; then
                echo "⚠️ favicon.ico 다운로드에 실패했습니다. 다른 방법을 시도합니다."
            fi
            
            # 가장 큰 파일 선택
            for f in "$ICON_DEST.ico" "$ICON_DEST.found"; do
                if [[ -f "$f" && ( ! -f "$ICON_DEST" || $(stat -f%z "$f") -gt $(stat -f%z "$ICON_DEST") ) ]]; then
                    mv "$f" "$ICON_DEST"
                else
                    rm -f "$f" 2>/dev/null
                fi
            done
            
            # 3. 모든 시도 실패시 Google favicon 서비스 사용
            if [[ ! -s "$ICON_DEST" ]]; then
                if ! curl -s "https://www.google.com/s2/favicons?sz=256&domain=$URL" -o "$ICON_DEST" 2>/dev/null; then
                    echo "⚠️ Google favicon 서비스 접근에 실패했습니다. 기본 아이콘을 사용합니다."
                    ICON_DEST="web-browser"
                fi
            fi
            
            # 임시 파일 정리
            rm -f "$ICON_DEST.html" 2>/dev/null
        fi
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
if [[ "$ADD_TO_DESKTOP" == true ]]; then
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
Exec="$APPIMAGE_PATH"
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
