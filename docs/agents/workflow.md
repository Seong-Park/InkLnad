# 에이전트 운영 규칙

## 조직과 실행 방식

이 채팅의 /root가 master 총괄 디렉터다. planning-agent, fe-manager와 be-manager는 master에게 보고한다. planning-agent가 자료 조사와 기획 작성을 전담하고 master는 피드백과 승인을 맡는다. map-designer, effect-designer, character-designer는 fe-manager가 직접 생성한다. gameplay-programmer, economy-save-programmer, api-db-programmer, qa-engineer는 be-manager가 배정하고 검토한다. 새 스레드 생성이 가능하면 직접 생성하고, 환경 한도로 불가능하면 아래 역할 재배정 절차를 사용한다. 도구의 task_name은 하이픈 대신 밑줄을 사용한다.

동시 실행 한도는 master 포함 4명이다. 전체 조직을 동시 상주시키지 않는다. master와 두 매니저가 활성화된 때에는 워커 한 명만 실행하고, 매니저끼리 워커 슬롯을 넘긴다. 매니저 한 명이 종료 또는 대기 중이라 활성 슬롯이 비어 있고 master가 명시적으로 허용하면 독립 워커 두 명을 병렬 실행할 수 있다. 공유 파일이나 순차 의존성이 있는 워커는 순서대로 실행한다. 모든 역할 파일은 유지된다. 종료된 에이전트는 향후 활성 여부를 확인하고 followup_task로 재개하거나 같은 역할 파일을 읽는 새 에이전트로 재생성한다. 역할 파일은 실행 가능한 커스텀 agent_type 등록 파일이 아니라 각 에이전트의 작업 지시와 참조 기준이다.

이번 환경에서는 completed 워커가 한도에 남아 매니저와 master의 신규 spawn 모두 thread limit으로 거절되었고 close_agent 도구가 없다. 이 경우 master가 지정한 완료 슬롯을 followup_task로 재사용한다. 지시마다 새 논리 역할, 상위 매니저, 필독 문서, 단일 쓰기 범위를 명시한다. 기존 canonical task 경로는 바뀌지 않으므로 역할명과 런타임 ID를 별도 기록한다. 다른 부문 경로의 슬롯이어도 현재 배정한 논리 매니저에게 보고하며 기존 담당 파일은 수정하지 않는다. 역할 재배정을 새 독립 스레드 생성으로 보고하지 않는다. 상주 스레드 제한을 설정 변경이나 다른 채팅 생성으로 우회하지 않는다.

## 공통 필독

1. C:/workspace/Ink-Land/AGENTS.md
2. C:/workspace/Ink-Land/docs/design/game-direction.md
3. C:/workspace/Ink-Land/docs/agents/workflow.md
4. C:/workspace/Ink-Land/docs/agents/contracts.md
5. 자신의 역할 파일 및 상위 매니저 계획

출발 시 Git 상태를 확인하고 사용자 변경을 보존한다. 현재 생성되는 산출물은 계획 문서뿐이다. Godot 씬이나 스크립트를 수정하기 전에 AGENTS.md의 에디터 동기화 절차를 따른다. 설치 검증 기록은 현재 세션 MCP 연결 증거가 아니다.

## 업무와 피드백 순환

planning-agent는 웹 자료를 조사해 reports/에 기획안을 제출한다. master가 피드백하고 planning-agent가 수정한 뒤 승인된 기준과 부문별 인수 조건을 매니저에게 전달한다. 매니저는 업무를 목표, 필독 파일, 읽기·쓰기 범위, 공동 계약, 산출물, 검증 기준으로 쪼개 워커에게 지시한다. 워커는 담당 파일만 수정하고 매니저에게 보고한다. 매니저는 보고서와 실제 산출물을 읽어 accepted 또는 revision-required로 판정한다. 수정 요청에는 위치, 문제, 요구 변경, 확인 방법을 포함한다. 수정은 기존 워커에 followup_task로 배정한다. 매니저가 승인한 결과를 master가 전체 플레이 흐름과 대조한다.

문제없는 산출물에 형식적인 수정 요청을 만들지 않는다. 계획 검토를 실행 검증처럼 보고하지 않는다. master나 매니저가 워커의 파일을 몰래 수정해 피드백 단계를 생략하지 않는다.

## 충돌과 통합

공통 계약은 master가 소유한다. 기획 기준은 planning-agent가 master 승인 내용만 반영한다. 매니저는 계약 변경 제안을 전달한다. 자신이 소유하지 않은 파일 변경이 필요하면 소유자와 매니저에게 요청한다. 같은 씬, project.godot, 공용 테마, 입력 매핑, 저장 스키마를 동시에 편집하지 않는다. Godot 라이브 에디터를 사용하는 워커는 한 번에 한 명이다. 프런트엔드와 백엔드의 의미는 시각·입력 표현과 게임 상태·규칙의 책임 구분이며 별도 웹 앱을 의미하지 않는다.

## 워커 보고 형식

- 작업 ID와 역할
- 읽은 기준 문서와 버전
- 생성하거나 수정한 파일
- 설계 또는 구현 결정과 근거
- 검증 방법 및 실제 결과
- 알려진 제약과 미확정 항목
- 다른 역할에 요청할 내용
- 매니저 검토 요청

매니저 검토 기록은 부문별 review-log.md에 남긴다. 상태는 assigned, submitted, revision-required, accepted로 관리한다. accepted는 해당 과업의 승인만 의미하며 게임 전체 구현 완료를 의미하지 않는다.

## 범위와 승인

기획 및 역할 문서 생성과 내부 에이전트 업무 배정은 사용자가 승인했다. 게임 구현, 원격 API/DB 설치, 계정 연결, 배포, 커밋·푸시는 이번 과업의 승인이 아니다. API/DB 담당은 현재 필요성과 미래 경계를 문서화하고 서버를 선행 구축하지 않는다.
