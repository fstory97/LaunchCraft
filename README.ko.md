# LaunchCraft

LaunchCraft는 리눅스 데스크톱 환경에서 AppImage 파일과 웹사이트 바로가기를 위한 애플리케이션 아이콘(AppIcon)을 관리하는 유틸리티 도구입니다.

## 주요 기능

- AppImage 애플리케이션을 위한 데스크톱 엔트리(.desktop 파일) 생성
- 커스텀 아이콘이 포함된 웹사이트 바로가기 생성
- 간단한 쉘 스크립트 기반 솔루션
- 다국어 지원 (영어/한국어)

## 사용 방법

1. 스크립트 실행 권한 부여:
```bash
chmod +x launchcraft.sh
```

2. AppImage 파일이나 URL과 함께 스크립트 실행:
```bash
# AppImage 파일 등록
./launchcraft.sh /path/to/your/application.AppImage

# 웹사이트 바로가기 생성
./launchcraft.sh https://example.com

# 한국어로 실행
./launchcraft.sh -l ko /path/to/your/application.AppImage
```

3. 대화형 프롬프트를 통해 다음 설정:
   - 설치 위치 선택 (작업 표시줄/바탕화면/모두)
   - 커스텀 아이콘 설정 (필요한 경우)

## 개발 예정 기능

- 드래그 앤 드롭을 지원하는 GUI 인터페이스
- 파일 선택을 위한 다이얼로그
- 향상된 아이콘 관리 기능

## 시스템 요구사항

- 데비안 기반 리눅스 배포판 (우분투, 조린 OS 등)
- 그놈(GNOME) 기반 데스크톱 환경
- Bash 쉘
- GTK 기반 데스크톱 환경 지원
- 테스트 환경:
  - Zorin OS (GNOME)

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 기여하기

프로젝트 기여를 환영합니다! Pull Request를 자유롭게 제출해 주세요.
