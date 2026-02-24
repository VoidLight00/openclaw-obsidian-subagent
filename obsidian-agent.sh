#!/bin/bash

# OpenClaw Obsidian CLI Sub-Agent
# Obsidian Shell Commands 플러그인 기반

OBSIDIAN_PATH="${OBSIDIAN_PATH:-/Users/voidlight/Documents/암흑물질}"
LOG_FILE="/tmp/obsidian-agent.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Obsidian CLI 실행
run_obsidian() {
    local cmd="$1"
    shift
    local args="$@"
    
    log "실행: obsidian $cmd $args"
    
    case "$cmd" in
        # === NOTES ===
        "create")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                echo "이미 존재: $name"
            else
                # 폴더가 없으면 생성
                local dir=$(dirname "$filepath")
                mkdir -p "$dir" 2>/dev/null
                echo "---" > "$filepath"
                echo "date: $(date '+%Y-%m-%d')" >> "$filepath"
                echo "tags: []" >> "$filepath"
                echo "---" >> "$filepath"
                echo "" >> "$filepath"
                echo "# $name" >> "$filepath"
                log "생성됨: $filepath"
                echo "생성 완료: $name"
            fi
            ;;
        "create:content")
            # 이름과 내용을 같이 전달
            local first="$args"
            local name="${first%%::*}"
            local content="${args#*::}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            local dir=$(dirname "$filepath")
            mkdir -p "$dir" 2>/dev/null
            echo "$content" > "$filepath"
            log "생성됨: $filepath (내용 포함)"
            echo "생성 완료: $name"
            ;;
        "read"|"open")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                cat "$filepath"
            else
                echo "파일을 찾을 수 없습니다: $name"
            fi
            ;;
        "append")
            local parts=($args)
            local name="${parts[0]}"
            local content="${parts[@]:1}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                echo "" >> "$filepath"
                echo "$content" >> "$filepath"
                log "추가됨: $name"
                echo "추가 완료"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "prepend")
            local parts=($args)
            local name="${parts[0]}"
            local content="${parts[@]:1}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                local tmp="/tmp/obsidian_prepend_$$.md"
                echo "$content" > "$tmp"
                echo "" >> "$tmp"
                cat "$filepath" >> "$tmp"
                mv "$tmp" "$filepath"
                log "앞에 추가됨: $name"
                echo "추가 완료"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "move"|"rename")
            local parts=($args)
            local from="$OBSIDIAN_PATH/${parts[0]}.md"
            local to="$OBSIDIAN_PATH/${parts[1]}.md"
            if [ -f "$from" ]; then
                mv "$from" "$to"
                log "이동됨: $from -> $to"
                echo "이동 완료"
            else
                echo "파일 없음: ${parts[0]}"
            fi
            ;;
        "delete")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                mkdir -p "$OBSIDIAN_PATH/.trash"
                mv "$filepath" "$OBSIDIAN_PATH/.trash/"
                log "삭제됨 (trash): $name"
                echo "삭제 완료 (trash로 이동)"
            else
                echo "파일 없음: $name"
            fi
            ;;
        # === DAILY NOTE ===
        "daily")
            local filename="$(date '+%Y-%m-%d').md"
            local filepath="$OBSIDIAN_PATH/$filename"
            if [ ! -f "$filepath" ]; then
                echo "---" > "$filepath"
                echo "date: $(date '+%Y-%m-%d')" >> "$filepath"
                echo "tags: [daily]" >> "$filepath"
                echo "---" >> "$filepath"
                echo "" >> "$filepath"
                echo "# $(date '+%Y-%m-%d') Daily Note" >> "$filepath"
                echo "" >> "$filepath"
                echo "## Morning" >> "$filepath"
                echo "" >> "$filepath"
                echo "## Tasks" >> "$filepath"
                echo "" >> "$filepath"
                echo "## Notes" >> "$filepath"
            fi
            cat "$filepath"
            ;;
        "daily:append")
            local content="$args"
            local filename="$(date '+%Y-%m-%d').md"
            local filepath="$OBSIDIAN_PATH/$filename"
            if [ -f "$filepath" ]; then
                echo "" >> "$filepath"
                echo "$content" >> "$filepath"
                echo "데일리에 추가됨"
            else
                echo "데일리 노트가 없습니다. 'daily' 명령어로 먼저 만드세요."
            fi
            ;;
        # === SEARCH ===
        "search")
            local query="$args"
            grep -r "$query" "$OBSIDIAN_PATH" --include="*.md" -l 2>/dev/null | head -10
            ;;
        "search:context")
            local parts=($args)
            local query="${parts[0]}"
            local limit="${parts[1]:-10}"
            grep -r "$query" "$OBSIDIAN_PATH" --include="*.md" -B2 -A2 2>/dev/null | head -$((limit * 5))
            ;;
        # === TASKS ===
        "tasks")
            local subcmd="$args"
            case "$subcmd" in
                "todo")
                    grep -r "\- \[ \]" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | head -20
                    ;;
                "done")
                    grep -r "\- \[x\]" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | head -20
                    ;;
                "daily")
                    local today=$(date '+%Y-%m-%d')
                    grep -r "\- \[ \]" "$OBSIDIAN_PATH/${today}.md" --include="*.md" 2>/dev/null
                    ;;
                *)
                    echo "tasks [todo|done|daily]"
                    ;;
            esac
            ;;
        # === TAGS ===
        "tags")
            local subcmd="$args"
            case "$subcmd" in
                "counts"|"list")
                    grep -rh "^tags:" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | \
                    sed 's/tags: //g' | tr -d '[]' | tr ',' '\n' | \
                    sed 's/ //g' | sort | uniq -c | sort -rn | head -20
                    ;;
                *)
                    grep -rh "#" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | \
                    grep -o '#[a-zA-Z0-9_-]*' | sort | uniq -c | sort -rn | head -20
                    ;;
            esac
            ;;
        "tag")
            local name="$args"
            grep -r " #$name " "$OBSIDIAN_PATH" --include="*.md" -l 2>/dev/null | head -10
            ;;
        # === PLUGINS (Obsidian Shell Commands) ===
        "commands")
            # Obsidian Shell Commands 플러그인 명령어 목록
            # 실제 Obsidian에서 확인 필요
            cat << 'EOF'
=== Obsidian Shell Commands ===

기본 명령어 (bash로 구현):
- create, read, append, prepend
- daily, daily:append
- search, search:context
- tasks todo/done/daily
- tags, tag
- vault, files

플러그인 명령어 (Obsidian Shell Commands 설치 필요):
- dataview:dataview-force-refresh-views
- obsidian-tasks-plugin:toggle-done
- quickadd:runQuickAdd
- periodic-notes:open-weekly-note
- templater-obsidian:create-new-note-from-template

참고: obsidian commands filter="플러그인명"으로 확인
EOF
            ;;
        "commands:filter")
            # 특정 플러그인의 명령어만 필터링
            local plugin="$args"
            echo "=== $plugin 명령어 목록 ==="
            echo ""
            echo "Obsidian Shell Commands 플러그인이 설치되어 있으면"
            echo "실제 명령어 ID를 확인할 수 있습니다."
            echo ""
            echo "예시 명령어 (설치 필요):"
            case "$plugin" in
                "dataview"|"dataviewjs")
                    echo "- dataview:dataview-force-refresh-views"
                    echo "- dataview:dataview-rebuild-current-view"
                    ;;
                "tasks"|"obsidian-tasks-plugin")
                    echo "- obsidian-tasks-plugin:toggle-done"
                    echo "- obsidian-tasks-plugin:create-or-edit-task"
                    ;;
                "quickadd")
                    echo "- quickadd:runQuickAdd"
                    echo "- quickadd:choice:"
                    ;;
                "templater")
                    echo "- templater-obsidian:create-new-note-from-template"
                    echo "- templater-obsidian:replace-in-file-templater"
                    ;;
                "periodic-notes")
                    echo "- periodic-notes:open-weekly-note"
                    echo "- periodic-notes:open-monthly-note"
                    ;;
                *)
                    echo "- $plugin:* (플러그인 설치 필요)"
                    ;;
            esac
            ;;
        "command")
            # 플러그인 명령어 실행 (placeholder)
            local command_id="$args"
            echo "=== 명령어 실행 시뮬레이션 ==="
            echo "명령어: $command_id"
            echo ""
            echo "이 명령어를 실행하려면 Obsidian Shell Commands 플러그인이 설치되어 있어야 합니다."
            echo ""
            echo "실제 실행을 원하면 Obsidian에서:"
            echo "1. Obsidian Shell Commands 플러그인 설치"
            echo "2. 설정에서 명령어 추가"
            echo "3. 이 스크립트와 연동"
            ;;
        # === PLUGINS Enable/Disable ===
        "plugin:enable")
            local plugin_id="$args"
            echo "플러그인 활성화: $plugin_id"
            echo ""
            echo "Obsidian 설정에서 플러그인을 활성화하세요:"
            echo "설정 > 플러그인 > $plugin_id 활성화"
            ;;
        "plugin:disable")
            local plugin_id="$args"
            echo "플러그인 비활성화: $plugin_id"
            echo ""
            echo "Obsidian 설정에서 플러그인을 비활성화하세요:"
            echo "설정 > 플러그인 > $plugin_id 비활성화"
            ;;
        # === TEMPLATES ===
        "templates"|"template:list")
            ls "$OBSIDIAN_PATH"/templates/ 2>/dev/null || echo "templates 폴더가 없습니다"
            ;;
        "template:read")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/templates/${name}.md"
            if [ -f "$filepath" ]; then
                cat "$filepath"
            else
                echo "템플릿 없음: $name"
            fi
            ;;
        # === LINKS ===
        "backlinks")
            local name="$args"
            local content=$(cat "$OBSIDIAN_PATH/${name}.md" 2>/dev/null)
            echo "$content" | grep -o '\[\[.*\]\]' | sort | uniq
            ;;
        "orphans")
            find "$OBSIDIAN_PATH" -name "*.md" -exec grep -L "\[\[.*\]\]" {} \; 2>/dev/null | head -10
            ;;
        # === PUBLISH ===
        "publish:status")
            echo "Publish 상태 확인 (Obsidian에서 수동 확인 필요)"
            echo ""
            echo "Obsidian > Publish > Settings에서 확인"
            ;;
        "publish:add")
            local name="$args"
            echo "퍼블리시 추가: $name"
            echo ""
            echo "Obsidian > Publish에서 수동으로 퍼블리시하세요"
            ;;
        # === SYNC ===
        "sync:status")
            echo "Sync 상태 확인 (Obsidian에서 수동 확인 필요)"
            ;;
        "sync:history")
            local name="$args"
            echo "동기화 히스토리: $name"
            echo "Obsidian Sync 설정에서 확인"
            ;;
        "sync:restore")
            local name="$args"
            local version="${args#* }"
            echo "동기화 복원: $name (버전 $version)"
            echo "Obsidian Sync에서 수동으로 복원"
            ;;
        # === WORKSPACE ===
        "workspace"|"workspaces")
            echo "Workspace 정보 (Obsidian에서 수동 확인 필요)"
            ;;
        "workspace:save")
            local name="$args"
            echo "워크스페이스 저장: $name"
            echo "Obsidian에서 Ctrl+Shift+S > 이름 입력"
            ;;
        "workspace:load")
            local name="$args"
            echo "워크스페이스 불러오기: $name"
            echo "Obsidian에서 Ctrl+Shift+P > workspace:load"
            ;;
        "tabs")
            echo "열린 탭 (Obsidian에서 수동 확인 필요)"
            ;;
        # === DEVELOPER ===
        "eval")
            local code="$args"
            echo "JS 실행: $code"
            echo ""
            echo "Obsidian Developer 모드 활성화 필요:"
            echo "설정 > Developer > Toggle DevTools"
            ;;
        "dev:screenshot")
            local path="${args#*=}"
            echo "스크린샷: $path"
            echo ""
            echo "Obsidian에서: Ctrl+Shift+I > Console >creenshot()"
            ;;
        "dev:errors")
            echo "에러 로그 확인"
            echo "Obsidian Developer 모드 활성화 필요"
            ;;
        # === VAULT INFO ===
        "vault"|"vaults")
            echo "Vault: $(basename $OBSIDIAN_PATH)"
            find "$OBSIDIAN_PATH" -name "*.md" | wc -l | xargs echo "총 MD 파일:"
            du -sh "$OBSIDIAN_PATH" | xargs echo "용량:"
            ;;
        "files")
            local ext="${args:-md}"
            find "$OBSIDIAN_PATH" -name "*.${ext}" | wc -l | xargs echo "총 $ext 파일:"
            ;;
        # === HELP ===
        "help"|"--help"|"-h")
            cat << 'EOF'
=== 사용 가능한 명령어 ===

NOTES:
  create [이름]              - 새 노트 작성
  create:content [이름]::[내용] - 내용 포함 노트 작성
  read [이름]               - 노트 읽기
  append [이름] [내용]      - 노트에 추가
  prepend [이름] [내용]      - 노트 앞에 추가
  move [from] [to]         - 노트 이동
  delete [이름]             - 노트 삭제 (trash)

DAILY:
  daily                    - 오늘의 데일리 노트
  daily:append [내용]       - 데일리에 추가

SEARCH:
  search [쿼리]             - 검색
  search:context [쿼리] [개수] - 검색+본문

TASKS:
  tasks todo               - 안 한 할 일
  tasks done              - 완료된 할 일
  tasks daily             - 오늘 할 일

TAGS:
  tags                     - 태그 목록
  tag [태그명]             - 해당 태그 파일

PLUGINS:
  commands                 - 모든 명령어 목록
  commands:filter [플러그인] - 특정 플러그인 명령어
  command id="..."        - 플러그인 명령어 실행
  plugin:enable [ID]      - 플러그인 활성화
  plugin:disable [ID]     - 플러그인 비활성화

TEMPLATES:
  templates                - 템플릿 목록
  template:read [이름]     - 템플릿 내용

LINKS:
  backlinks [노트]         - 백링크 목록
  orphans                 - 고립된 노트

PUBLISH:
  publish:status          - 퍼블리시 상태
  publish:add [노트]      - 퍼블리시 추가

SYNC:
  sync:status            - 동기화 상태
  sync:history [노트]    - 동기화 히스토리
  sync:restore [노트] [버전] - 동기화 복원

WORKSPACE:
  workspace              - 워크스페이스 정보
  workspace:save [이름]   - 워크스페이스 저장
  workspace:load [이름]   - 워크스페이스 불러오기

DEVELOPER:
  eval [코드]             - JS 실행
  dev:screenshot [경로]  - 스크린샷
  dev:errors             - 에러 로그

INFO:
  vault                   - 볼트 정보
  files [확장자]          - 파일 목록

PLUGINS 자동화 (Obsidian Shell Commands 설치 필요):
  obsidian command id="dataview:dataview-force-refresh-views"
  obsidian command id="obsidian-tasks-plugin:toggle-done"
  obsidian command id="quickadd:runQuickAdd"
  obsidian command id="templater-obsidian:create-new-note-from-template"
  obsidian command id="periodic-notes:open-weekly-note"
EOF
            ;;
        *)
            echo "알 수 없는 명령어: $cmd"
            echo " 도움말: obsidian-agent.sh run help"
            ;;
    esac
}

# 메인
case "$1" in
    "run")
        shift
        run_obsidian "$@"
        ;;
    *)
        run_obsidian "$@"
        ;;
esac
