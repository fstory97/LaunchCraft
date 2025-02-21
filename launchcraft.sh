#!/bin/bash

set -e  # Stop on errors

# Default language (English)
LANGUAGE="en"

# Check for language option
while [[ "$1" == "-l" ]]; do
    shift
    case "$1" in
        "ko") LANGUAGE="ko" ;;
        "en") LANGUAGE="en" ;;
        *) echo "Invalid language option. Use '-l en' or '-l ko'."; exit 1 ;;
    esac
    shift
done

# Full usage message (English)
USAGE_MESSAGE="Usage: $0 [-l en|ko] <AppImage file path | URL>
Options:
  -l en   Set language to English (default)
  -l ko   Set language to Korean
Examples:
  $0 /home/user/MyApp.AppImage    (Add an AppImage)
  $0 -l ko /home/user/MyApp.AppImage  (Add an AppImage with Korean messages)
  $0 https://chat.openai.com       (Add a website shortcut)
  $0 -l ko https://chat.openai.com (Add a website shortcut with Korean messages)"

# Multi-language messages
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
fi

echo "$MSG_INPUT"

INPUT="$1"

if [[ -z "$INPUT" ]]; then
    echo "$MSG_ERROR_INPUT"
    echo "$USAGE_MESSAGE"
    exit 1
fi
