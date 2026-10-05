# Godot 격리 실행환경 검증

작성: 2026.10.03 17:23 KST. 검증 대상: 기존 프로젝트의 headless import. 게임 구현 완료 판정이 아니다.

## 조건과 실패

Godot4.7.2 console, C:/workspace/Ink-Land/godot, Windows 제한 샌드박스. 기존 실행은 Windows 루트 인증서 저장소 읽기와 실제 사용자 editor_settings 저장 접근에서 오류를 냈다. exit0만으로 통과로 처리하지 않았다.

## 시도와 해결

검증 helper tmp/prototype-baseline.py가 자식 프로세스의 APPDATA/LOCALAPPDATA를 tmp/prototype-verification 내부로 분리했다. 사용자 실제 설정 경로에 쓰지 않는다. 이 상태의 일반 샌드박스 실행은 editor_settings 오류는 없어졌으나 루트 인증서 오류가 남아 검증 helper exit1이었다.

동일 helper를 require_escalated 자동 승인 검토를 거쳐 실행했다. Godot import exit0, stdout/stderr의 ERROR/SCRIPT ERROR 목록0, helper exit0이었다. 검증 범위는 기존 프로젝트 import이며 실제 게임씬·전투·UI·저장 테스트가 아니다.

## 증거

- tmp/prototype-verification/baseline-import.stdout.log
- tmp/prototype-verification/baseline-import.stderr.log
- tmp/prototype-verification/baseline-import.json
- tmp/prototype-baseline.py

Godot AI localhost8001 session을 다시 조회해 project_path=C:/workspace/Ink-Land/godot, current_scene 빈값, no_scene을 확인했다. 새 게임 코드/씬/프로젝트 설정은 수정하지 않았다. 작업 위치 승인 질문은 아직 답변 없음. 승인되지 않은 master 브랜치 구현을 시작하지 않는다.
