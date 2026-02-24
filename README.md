# OpenClaw Obsidian Sub-Agent

## 설치 방법

```bash
# 1. 클론
git clone https://github.com/VoidLight00/openclaw-obsidian-subagent.git
cd openclaw-obsidian-subagent

# 2. 실행 권한
chmod +x obsidian-agent.sh

# 3. .env 파일 생성
cp .env.example .env
# .env 파일을 열어 OBSIDIAN_PATH를 자신의 볼트 경로로 수정
```

## 사용 방법

### 명령어 실행

```bash
# 노트 작성
./obsidian-agent.sh run create "AI/새로운 노트"

# 노트 읽기
./obsidian-agent.sh run read "노트이름"

# 데일리 노트
./obsidian-agent.sh run daily

# 검색
./obsidian-agent.sh run search "키워드"

# 할 일 목록
./obsidian-agent.sh run tasks todo
```

## 명령어 목록

### Notes (노트 관리)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `create [이름]` | 새 노트 작성 | `create "AI/프로젝트"` |
| `read [이름]` | 노트 읽기 | `read "프로젝트"` |
| `append [이름] [내용]` | 노트에 추가 | `append "프로젝트" "- 새로운 할 일"` |
| `prepend [이름] [내용]` | 노트 앞에 추가 | `prepend "프로젝트" "## 요약"` |
| `move [from] [to]` | 노트 이동 | `move " old" "new"` |
| `delete [이름]` | 노트 삭제 (trash) | `delete "노트"` |

### Daily (데일리 노트)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `daily` | 오늘의 데일리 노트 | `daily` |
| `daily:append [내용]` | 데일리에 추가 | `daily:append "- [ ] 회의"` |

### Search (검색)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `search [쿼리]` | 검색 | `search "Claude"` |
| `search:context [쿼리] [개수]` | 검색+본문 | `search:context "TODO" 10` |

### Tasks (할 일)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `tasks todo` | 안 한 할 일 | `tasks todo` |
| `tasks done` | 완료된 할 일 | `tasks done` |
| `tasks daily` | 오늘 할 일 | `tasks daily` |

### Tags (태그)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `tags` | 태그 목록 | `tags` |
| `tag [태그명]` | 해당 태그 파일 | `tag project` |

### Info (정보)
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `vault` | 볼트 정보 | `vault` |
| `files [확장자]` | 파일 목록 | `files md` |
| `templates` | 템플릿 목록 | `templates` |

## OpenClaw Cron 연동

HEARTBEAT.md 또는 cron에 추가:

```bash
# 매일 아침 9시 데일리 노트 확인
0 9 * * * /path/to/obsidian-agent.sh run daily >> /tmp/obsidian.log 2>&1

# 매일 밤 10시 할 일 확인
0 22 * * * /path/to/obsidian-agent.sh run tasks todo >> /tmp/obsidian.log 2>&1
```

## 환경 변수

`.env` 파일:

```bash
OBSIDIAN_PATH=/Users/voidlight/Documents/암흑물질
OBSIDIAN_VAULT=암흑물질
```

## 필요 사항

- macOS 또는 Linux
- Obsidian 볼트
- bash

## 라이선스

MIT
