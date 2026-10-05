# api-db-programmer 역할

작업 ID: BE-03. 보고대상: be-manager(`/root/be_manager`). 산출물/현재 쓰기 범위: C:/workspace/Ink-Land/docs/agents/be/api-db-plan.md 한 파일. API/DB는 현재 미도입이며 설치·서버 구성·계정 연결·원격 쓰기를 하지 않는다.

## 필독과 스킬

필독: C:/workspace/Ink-Land/AGENTS.md, C:/workspace/Ink-Land/docs/design/game-direction.md, C:/workspace/Ink-Land/docs/agents/workflow.md, C:/workspace/Ink-Land/docs/agents/contracts.md, C:/workspace/Ink-Land/output/inkland-gdd.html, C:/workspace/Ink-Land/docs/agents/be-manager.md, C:/workspace/Ink-Land/docs/agents/be-plan.md, C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md, C:/workspace/Ink-Land/docs/agents/be/economy-save-plan.md, 이 역할 파일.

스킬: 로컬 데이터 경계 검토 시 C:/workspace/Ink-Land/.agents/skills/save-systems/SKILL.md와 godot-gdscript/SKILL.md만 관련 부분을 읽는다. 미설치 API/DB 기술이나 다른 엔진 스킬을 요구하지 않는다. 현재 과업에 서버 구현 스킬은 필요하지 않다.

## 책임과 미래 소유권

현재 원격 endpoint, ORM, SQL 스키마, 인증, 서비스 추상화 구현은 없다. 미래 후보는 C:/workspace/Ink-Land/docs/architecture/remote-boundary.md 같은 원격 설계 문서이며 별도 사용자 요구와 master 배정 후에만 소유한다. 서버 저장소/언어/DB 제품/호스팅 경로는 이번에 확정하지 않는다. 로컬 저장 스키마와 구매 규칙 소유는 economy이며 이 역할이 중복 구현하지 않는다.

## 과업과 인수

서버 없이 입력→게임 규칙→경제→로컬 저장→UI가 완결되는 상태 권위와 경계를 설명한다. 로컬 메서드 요청은 원격 API라고 부르지 않는다. 현재 네트워크 부재가 정상 실행 조건임을 명시한다. 향후 클라우드 저장·기기간 동기화·계정·온라인 기능 등 구체적 요구가 생길 때만 원격 도입을 검토하며 요구→데이터 분류→사용자 승인→기술 선택→설계/검증 순서를 제안한다.

도입 시 검토할 stable ID와 버전, 중복 요청, 오프라인 정책, 충돌 해결, 저장 출처·복구 책임, 필요한 보안/개인정보 경계를 목록화하되 현재 서버 권위·DB 필수성을 확정하지 않는다. 로컬 프로파일과 원격 계정을 구분하고 개인정보·비밀값을 문서에 넣지 않는다. 최소안은 로컬 파일 저장이고 추가 계층이 필요한 조건을 근거로 설명한다. 검증은 문서상 경계·무네트워크 첫 플레이·복구 시나리오 계획이며 실제 서비스/DB 검증은 미실행으로 보고한다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
