# Inkland 에이전트 조직

master는 현재 채팅의 주 에이전트이며 총괄 디렉터다. 아래 역할은 사용자 요청으로 생성하는 하위 에이전트다. master는 기획안을 검토·피드백·승인하며 planning-agent가 자료 조사와 기획 작성을 담당한다. 역할 파일에 각자의 필독 문서, 쓰기 범위, 보고 대상과 인수 조건을 기록한다.

```text
master
├── planning-agent  자료 조사와 기획 전담
├── fe-manager  UIUX와 시각 표현 디렉터
│   ├── map-designer        맵과 복원 전후 환경
│   ├── effect-designer     잉크와 무기 및 맵 효과
│   └── character-designer  기사와 NPC 및 몬스터
└── be-manager  게임 규칙과 API 및 DB 디렉터
    ├── gameplay-programmer     입력과 전투 및 탐험 상태
    ├── economy-save-programmer 잉크 경제와 구매 및 복원 저장
    ├── api-db-programmer       데이터 경계와 향후 API 및 DB
    └── qa-engineer             규칙과 통합 검증
```

## 공통 기획 기준

- [최신 기획 결정](../design/game-direction.md)
- [부문 간 계약](contracts.md)
- [배정과 보고 및 피드백 규칙](workflow.md)
- [실제 역할과 실행 슬롯 배정 기록](runtime-roles.json)
- [기존 GDD v0.1](../../output/inkland-gdd.html)
- [수채화 메뉴 목업](../../output/inkland-main-menu.png)

기존 GDD와 충돌하는 항목은 최신 기획 결정을 따른다. 직접 선 그리기와 기사 주변 제한은 확정이고 공격 반경의 수치와 잉크 비용은 후속 기획 항목이다.

## 역할별 참조와 계획

| 역할 | 역할 파일 | 산출 계획 또는 검토 |
|---|---|---|
| master | [master.md](master.md) | [master-review.md](master-review.md) |
| planning-agent | [planning-agent.md](planning-agent.md) | reports/ 자료 조사·기획 보고서 |
| fe-manager | [fe-manager.md](fe-manager.md) | [fe-plan.md](fe-plan.md), [FE 검토](fe/review-log.md) |
| map-designer | [map-designer.md](map-designer.md) | [map-plan.md](fe/map-plan.md) |
| effect-designer | [effect-designer.md](effect-designer.md) | [effect-plan.md](fe/effect-plan.md) |
| character-designer | [character-designer.md](character-designer.md) | [character-plan.md](fe/character-plan.md) |
| be-manager | [be-manager.md](be-manager.md) | [be-plan.md](be-plan.md), [BE 검토](be/review-log.md) |
| gameplay-programmer | [gameplay-programmer.md](gameplay-programmer.md) | [gameplay-plan.md](be/gameplay-plan.md) |
| economy-save-programmer | [economy-save-programmer.md](economy-save-programmer.md) | [economy-save-plan.md](be/economy-save-plan.md) |
| api-db-programmer | [api-db-programmer.md](api-db-programmer.md) | [api-db-plan.md](be/api-db-plan.md) |
| qa-engineer | [qa-engineer.md](qa-engineer.md) | [qa-plan.md](be/qa-plan.md) |

## 실행 조건

동시 실행은 master를 포함해 4명까지다. 전체 조직을 상주시켜 두지 않고 필요한 워커를 매니저가 배정한다. 이번 환경에서는 완료된 워커도 스레드 한도에 남아 BE 신규 생성이 거절되었다. 따라서 완료 슬롯을 재사용하며 역할 문서와 상위 매니저·쓰기 범위를 새로 지정한다. 논리 역할은 11개지만 독립 스레드 10개가 상주하는 구조는 아니다. 후속 업무도 해당 역할 문서를 읽고 시작한다. 이 구성은 현재 채팅의 내부 서브에이전트 구조이며 별도의 사용자 채팅이나 항상 실행되는 서비스가 아니다.

## 다음 작업에서 사용하는 방법

사용자가 기획 검토 또는 구현할 목표를 master에게 전달한다. 기획은 planning-agent가 조사·작성하고 master가 피드백·승인한다. master는 승인안을 해당 부문 매니저에게 지시하고 매니저는 소유 파일이 겹치지 않는 과업으로 나눈다. 워커는 문서를 읽고 수행·보고하며 매니저가 검토한다. 재작업 후 승인된 결과만 master가 전체 흐름에 통합한다. 현재 조직 구성의 실제 생성 및 검토 결과는 master-review.md에 기록한다.

## 기존 계획 검토 결과

FE 세 역할과 BE 네 역할의 계획은 모두 매니저 검토 accepted다. 캐릭터, 전투, 경제·저장 계획은 각각 한 차례 수정 후 재검토했다. master는 부문 간 카메라 책임, 직접 그리기와 잔흔, 구매와 복원 및 저장 흐름을 대조했다. 이 결과는 기획·계획의 문서 검토이며 게임 실행 테스트 결과가 아니다.
