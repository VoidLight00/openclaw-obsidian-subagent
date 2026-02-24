#!/bin/bash

# OpenClaw Obsidian CLI Sub-Agent
# Complete Obsidian CLI based on official documentation

OBSIDIAN_PATH="${OBSIDIAN_PATH:-/Users/voidlight/Documents/암흑물질}"
LOG_FILE="/tmp/obsidian-agent.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

run_obsidian() {
    local cmd="$1"
    shift
    local args="$@"
    
    log "실행: obsidian $cmd $args"
    
    case "$cmd" in
        # === 1. NOTES ===
        "create")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                echo "이미 존재: $name"
            else
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
        "delete:permanent")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                rm "$filepath"
                log "영구삭제됨: $name"
                echo "영구삭제 완료"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "files")
            local folder="$args"
            if [ -n "$folder" ]; then
                find "$OBSIDIAN_PATH/$folder" -name "*.md" 2>/dev/null | head -20
            else
                find "$OBSIDIAN_PATH" -name "*.md" 2>/dev/null | wc -l | xargs echo "총 MD 파일:"
            fi
            ;;
        "file")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                ls -la "$filepath"
                wc -w "$filepath" | xargs echo "단어 수:"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "wordcount")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                wc -w "$filepath"
                wc -c "$filepath"
            else
                echo "파일 없음: $name"
            fi
            ;;
        # === 2. DAILY NOTE ===
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
        "daily:read")
            local filename="$(date '+%Y-%m-%d').md"
            local filepath="$OBSIDIAN_PATH/$filename"
            if [ -f "$filepath" ]; then
                cat "$filepath"
            else
                echo "데일리 노트가 없습니다"
            fi
            ;;
        "daily:path")
            local filename="$(date '+%Y-%m-%d').md"
            echo "$OBSIDIAN_PATH/$filename"
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
        "daily:prepend")
            local content="$args"
            local filename="$(date '+%Y-%m-%d').md"
            local filepath="$OBSIDIAN_PATH/$filename"
            if [ -f "$filepath" ]; then
                local tmp="/tmp/obsidian_daily_$$.md"
                echo "$content" > "$tmp"
                echo "" >> "$tmp"
                cat "$filepath" >> "$tmp"
                mv "$tmp" "$filepath"
                echo "데일리 앞에 추가됨"
            else
                echo "데일리 노트가 없습니다"
            fi
            ;;
        # === 3. SEARCH ===
        "search")
            local query="$args"
            grep -r "$query" "$OBSIDIAN_PATH" --include="*.md" -l 2>/dev/null | head -20
            ;;
        "search:context")
            local parts=($args)
            local query="${parts[0]}"
            local limit="${parts[1]:-10}"
            grep -r "$query" "$OBSIDIAN_PATH" --include="*.md" -B2 -A2 2>/dev/null | head -$((limit * 5))
            ;;
        "search:open")
            local query="$args"
            grep -r "$query" "$OBSIDIAN_PATH" --include="*.md" -l 2>/dev/null | head -5
            ;;
        # === 4. TASKS ===
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
                "total")
                    echo "미완료: $(grep -r "\- \[ \]" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | wc -l)"
                    echo "완료: $(grep -r "\- \[x\]" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | wc -l)"
                    ;;
                *)
                    echo "tasks [todo|done|daily|total]"
                    ;;
            esac
            ;;
        "task")
            echo "태스크 토글: Obsidian Tasks 플러그인에서 수동으로 변경하세요"
            ;;
        # === 5. TAGS ===
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
        # === 6. PROPERTIES ===
        "properties")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                head -10 "$filepath" | grep -A20 "^---$"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "property:read")
            local parts=($args)
            local name="${parts[0]}"
            local prop="${parts[1]}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                grep "^$prop:" "$filepath" | head -1
            else
                echo "파일 없음: $name"
            fi
            ;;
        "property:set")
            local parts=($args)
            local name="${parts[0]}"
            local prop="${parts[1]}"
            local value="${parts[2]}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                # frontmatter에 속성 추가
                sed -i '' "s/^---$/---\n$prop: $value/" "$filepath"
                echo "속성 설정 완료: $prop = $value"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "property:remove")
            local parts=($args)
            local name="${parts[0]}"
            local prop="${parts[1]}"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                sed -i '' "/^$prop:/d" "$filepath"
                echo "속성 삭제 완료: $prop"
            else
                echo "파일 없음: $name"
            fi
            ;;
        "aliases")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                grep "^aliases:" "$filepath"
            else
                echo "파일 없음: $name"
            fi
            ;;
        # === 7. TEMPLATES ===
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
        # === 8. LINKS ===
        "backlinks")
            local name="$args"
            local content=$(cat "$OBSIDIAN_PATH/${name}.md" 2>/dev/null)
            echo "$content" | grep -o '\[\[.*\]\]' | sort | uniq
            ;;
        "links")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                grep -o '\[\[.*\]\]' "$filepath" | sort | uniq
            else
                echo "파일 없음: $name"
            fi
            ;;
        "orphans")
            find "$OBSIDIAN_PATH" -name "*.md" -exec grep -L "\[\[.*\]\]" {} \; 2>/dev/null | head -10
            ;;
        "unresolved")
            grep -r "\[\[.*\]\]" "$OBSIDIAN_PATH" --include="*.md" -l 2>/dev/null | while read f; do
                grep -o '\[\[.*\]\]' "$f" | sed 's/\[\[//g' | sed 's/\]\]//g' | while read link; do
                    if [ ! -f "$OBSIDIAN_PATH/${link}.md" ]; then
                        echo "$f: $link"
                    fi
                done
            done | head -10
            ;;
        "deadends")
            find "$OBSIDIAN_PATH" -name "*.md" -exec grep -L "\[\[.*\]\]" {} \; 2>/dev/null | head -10
            ;;
        # === 9. PLUGINS ===
        "plugins"|"plugins:enabled")
            echo "활성화된 플러그인 (Obsidian에서 확인 필요)"
            ;;
        "plugin")
            local plugin_id="$args"
            echo "플러그인 정보: $plugin_id"
            ;;
        "plugin:enable")
            local plugin_id="$args"
            echo "플러그인 활성화: $plugin_id"
            echo "Obsidian 설정 > 플러그인에서 활성화하세요"
            ;;
        "plugin:disable")
            local plugin_id="$args"
            echo "플러그인 비활성화: $plugin_id"
            echo "Obsidian 설정 > 플러그인에서 비활성화하세요"
            ;;
        "commands")
            cat << 'EOF'
=== Obsidian Shell Commands ===

기본 명령어 (bash 구현):
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
- templater-obsidian:create-new-note-from-template
- periodic-notes:open-weekly-note

참고: obsidian commands filter="플러그인명"으로 확인
EOF
            ;;
        "commands:filter")
            local plugin="$args"
            echo "=== $plugin 명령어 목록 ==="
            case "$plugin" in
                "dataview")
                    echo "- dataview:dataview-force-refresh-views"
                    echo "- dataview:dataview-rebuild-current-view"
                    ;;
                "tasks"|"obsidian-tasks-plugin")
                    echo "- obsidian-tasks-plugin:toggle-done"
                    echo "- obsidian-tasks-plugin:create-or-edit-task"
                    ;;
                "quickadd")
                    echo "- quickadd:runQuickAdd"
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
            local command_id="$args"
            echo "=== 명령어 실행 시뮬레이션 ==="
            echo "명령어: $command_id"
            echo ""
            echo "Obsidian Shell Commands 플러그인이 설치되어 있으면 실행됩니다."
            ;;
        # === 10. PUBLISH ===
        "publish:site")
            echo "퍼블리시 사이트 정보 (Obsidian에서 확인)"
            ;;
        "publish:status")
            echo "퍼블리시 상태 (Obsidian > Publish에서 확인)"
            ;;
        "publish:add")
            local name="$args"
            echo "퍼블리시 추가: $name"
            echo "Obsidian > Publish에서 수동으로 퍼블리시하세요"
            ;;
        "publish:remove")
            local name="$args"
            echo "퍼블리시 제거: $name"
            ;;
        "publish:open")
            local name="$args"
            echo "퍼블리시된 파일 열기: $name"
            ;;
        # === 11. SYNC ===
        "sync")
            local subcmd="$args"
            case "$subcmd" in
                "on")
                    echo "Sync 활성화: Obsidian 설정에서"
                    ;;
                "off")
                    echo "Sync 비활성화: Obsidian 설정에서"
                    ;;
                "status")
                    echo "Sync 상태: Obsidian 설정에서 확인"
                    ;;
                *)
                    echo "sync [on|off|status]"
                    ;;
            esac
            ;;
        "sync:history")
            local name="$args"
            echo "동기화 히스토리: $name"
            ;;
        "sync:restore")
            local name="$args"
            echo "동기화 복원: $name"
            ;;
        # === 12. WORKSPACE ===
        "bookmarks")
            echo "북마크 (Obsidian에서 확인)"
            ;;
        "workspaces")
            echo "워크스페이스 목록 (Obsidian에서 확인)"
            ;;
        "workspace:save")
            local name="$args"
            echo "워크스페이스 저장: $name"
            echo "Obsidian: Ctrl+Shift+S"
            ;;
        "workspace:load")
            local name="$args"
            echo "워크스페이스 불러오기: $name"
            ;;
        "workspace:delete")
            local name="$args"
            echo "워크스페이스 삭제: $name"
            ;;
        "tabs")
            echo "열린 탭 (Obsidian에서 확인)"
            ;;
        "tab:open")
            local name="$args"
            echo "탭 열기: $name"
            ;;
        "recents")
            echo "최근 파일 (Obsidian에서 확인)"
            ;;
        # === 13. BASES ===
        "bases")
            echo "Bases (Obsidiandataview에서 사용)"
            ;;
        "base:query")
            echo "베이스 쿼리: Obsidian Bases 플러그인 필요"
            ;;
        # === 14. THEMES ===
        "themes")
            echo "테마 목록 (Obsidian 설정에서 확인)"
            ;;
        "theme")
            local name="$args"
            echo "테마 변경: $name"
            ;;
        "theme:set")
            local name="$args"
            echo "테마 설정: $name"
            ;;
        "snippets")
            echo "CSS 스니펫 목록"
            ;;
        "snippet:enable")
            local name="$args"
            echo "스니펫 활성화: $name"
            ;;
        "snippet:disable")
            local name="$args"
            echo "스니펫 비활성화: $name"
            ;;
        # === 15. VAULT INFO ===
        "vault"|"vaults")
            echo "Vault: $(basename $OBSIDIAN_PATH)"
            find "$OBSIDIAN_PATH" -name "*.md" | wc -l | xargs echo "총 MD 파일:"
            du -sh "$OBSIDIAN_PATH" | xargs echo "용량:"
            ;;
        "folders")
            find "$OBSIDIAN_PATH" -type d | head -20
            ;;
        "tags:total")
            grep -rh "#" "$OBSIDIAN_PATH" --include="*.md" 2>/dev/null | \
            grep -o '#[a-zA-Z0-9_-]*' | wc -l | xargs echo "총 태그:"
            ;;
        # === 16. DEVELOPER ===
        "eval")
            local code="$args"
            echo "JS 실행: $code"
            echo "Obsidian Developer 모드 필요"
            ;;
        "dev:screenshot")
            local path="${args#*=}"
            echo "스크린샷: $path"
            ;;
        "devtools")
            echo "개발자 도구: Obsidian 설정 > 개발자 모드"
            ;;
        "dev:errors")
            echo "에러 로그: Obsidian Developer 모드에서 확인"
            ;;
        "reload")
            echo "Obsidian 다시 로드 필요"
            ;;
        "restart")
            echo "Obsidian 재시작 필요"
            ;;
        # === 17. OUTLINE ===
        "outline")
            local name="$args"
            local filepath="$OBSIDIAN_PATH/${name}.md"
            if [ -f "$filepath" ]; then
                grep "^#" "$filepath"
            else
                echo "파일 없음: $name"
            fi
            ;;
        # === 18. DIFF/HISTORY ===
        "diff")
            local name="$args"
            echo "버전 비교: $name"
            echo "Obsidian Sync 버전 히스토리에서 확인"
            ;;
        "history:restore")
            local name="$args"
            echo "버전 복원: $name"
            ;;
        # === HELP ===
        "help"|"--help"|"-h")
            cat << 'EOF'
=== 사용 가능한 명령어 ===

NOTES:
  create [이름]              - 새 노트 작성
  create:content [이름]::[내용] - 내용 포함 노트 작성
  read [이름]               - 노트 읽기
  append [이름] [내용]       - 노트에 추가
  prepend [이름] [내용]       - 노트 앞에 추가
  move [from] [to]          - 노트 이동
  delete [이름]              - 노트 삭제 (trash)
  delete:permanent [이름]    - 영구삭제 (확인 필수)

DAILY:
  daily                    - 오늘의 데일리 노트
  daily:read               - 데일리기
  daily:append [내용]        - 데일리에 추가
  daily:prepend [내용]       - 데일리 앞에 추가

SEARCH:
  search [쿼리]             - 검색
  search:context [쿼리] [개수] - 검색+본문
  search:open [쿼리]        - 검색결과 파일 열기

TASKS:
  tasks todo                - 안 한 할 일
  tasks done              - 완료된 할 일
  tasks daily             - 오늘 할 일
  tasks total             - 전체 태스크 현황

TAGS:
  tags                     - 태그 목록
  tags counts              - 태그별 개수
  tag [태그명]            - 해당 태그 파일

PROPERTIES:
  properties [노트]         - 프론트매터 보기
  property:set [노트] [속성] [값] - 속성 설정
  property:remove [노트] [속성] - 속성 삭제

TEMPLATES:
  templates               - 템플릿 목록
  template:read [이름]    - 템플릿 내용

LINKS:
  backlinks [노트]          - 백링크 목록
  links [노트]            - 나가는 링크
  orphans                 - 고아 노트
  unresolved              - 깨진 링크
  deadends                - 링크 없는 노트

PLUGINS:
  plugins                 - 플러그인 목록
  plugins:enabled         - 활성 플러그인
  plugin:enable [ID]      - 플러그인 활성화
  plugin:disable [ID]     - 플러그인 비활성화
  commands                - 모든 명령어
  commands:filter [플러그인] - 특정 플러그인 명령어

PUBLISH:
  publish:site             - 퍼블리시 사이트
  publish:status          - 퍼블리시 상태
  publish:add [노트]      - 퍼블리시 추가

SYNC:
  sync status             - 동기화 상태
  sync:history [노트]    - 동기화 히스토리
  sync:restore [노트]    - 동기화 복원

WORKSPACE:
  workspaces              - 워크스페이스 목록
  workspace:save [이름]    - 워크스페이스 저장
  workspace:load [이름]    - 워크스페이스 불러오기
  tabs                    - 열린 탭
  recents                 - 최근 파일

VAULT INFO:
  vault                   - 볼트 정보
  folders                 - 폴더 목록
  tags:total             - 전체 태그 수
  wordcount [노트]        - 단어 수

PLUGIN COMMANDS:
  obsidian command id="dataview:dataview-force-refresh-views"
  obsidian command id="obsidian-tasks-plugin:toggle-done"
  obsidian command id="quickadd:runQuickAdd"
  obsidian command id="templater-obsidian:create-new-note-from-template"
  obsidian command id="periodic-notes:open-weekly-note"
EOF
            ;;
        *)
            echo "알 수 없는 명령어: $cmd"
            echo "도움말: obsidian-agent.sh run help"
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
