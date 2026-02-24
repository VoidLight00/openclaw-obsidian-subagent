# OpenClaw Obsidian CLI Sub-Agent

OpenClaw에서 Obsidian 볼트를 백그라운드에서 관리하는 서브에이전트

## 주요 기능

- 새 노트 작성/읽기/수정
- 데일리 노트 자동 관리
- 볼트 내 검색
- 할 일 목록 조회
- 태그 관리

## 빠른 시작

```bash
# 1. 클론
git clone https://github.com/VoidLight00/openclaw-obsidian-subagent.git
cd openclaw-obsidian-subagent

# 2. 실행 권한
chmod +x obsidian-agent.sh

# 3. 백그라운드 시작
./obsidian-agent.sh start

# 4. 테스트
./obsidian-agent.sh run daily
```

## 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| create | 새 노트 작성 | `./obsidian-agent.sh run create "제목"` |
| read | 노트 읽기 | `./obsidian-agent.sh run read note-name` |
| append | 노트에 추가 | `./obsidian-agent.sh run append note-name "내용"` |
| daily | 오늘의 노트 | `./obsidian-agent.sh run daily` |
| search | 검색 | `./obsidian-agent.sh run search "키워드"` |
| tasks | 할 일 목록 | `./obsidian-agent.sh run tasks` |
| tags | 태그 목록 | `./obsidian-agent.sh run tags` |

## 환경 변수

`.env` 파일 생성:

```bash
OBSIDIAN_PATH=/Users/voidlight/Documents/암흑물질
OBSIDIAN_VAULT=암흑물질
```

## OpenClaw 연동

### 방법 1: Cron Jobs

OpenClaw HEARTBEAT.md에 추가:

```bash
# 매일 아침 9시 데일리 노트 확인
0 9 * * * /path/to/obsidian-agent.sh run daily >> /tmp/obsidian-cron.log 2>&1

# 매일 밤 10시 할 일 확인
0 22 * * * /path/to/obsidian-agent.sh run tasks >> /tmp/obsidian-cron.log 2>&1
```

### 방법 2: 서브에이전트

```bash
# OpenClaw에서
/spawn obsidian-agent task="오늘 할 일 작성"
```

## 설치 요구사항

- macOS / Linux
- Obsidian 볼트
- bash

## 라이선스

MIT
