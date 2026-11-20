#!/bin/sh
# Espelha as Releases publicadas do GitHub em $DATA/<tag>/.
#
# Ordem de cada produto (igual à da publicação): 1) pacotes (.nupkg); 2) instaladores; 3) índices por ÚLTIMO.
# Ao contrário, um app que consultasse o espelho no meio da cópia leria um índice apontando para um pacote que
# ainda não existe. Cada arquivo baixa para .part e só então vira o nome final (troca atômica).
# Arquivos que saíram da Release são removidos do espelho no fim.
set -u

REPO="${REPO:-marcosmoraisjr/release}"
DATA="${DATA:-/data}"
INTERVAL="${SYNC_INTERVAL:-300}"
LIST=/tmp/assets.tsv

# Só aceita nomes simples (sem barras nem ..): o que vem do GitHub nunca escolhe o caminho no disco.
seguro() { case "$1" in ''|.*|*[!A-Za-z0-9._-]*) return 1 ;; esac; return 0; }

baixar() {  # $1 destino  $2 url
    if curl -fsSL --retry 2 --max-time 900 -o "$1.part" "$2"; then mv -f "$1.part" "$1"; else rm -f "$1.part"; return 1; fi
}

indice() {  # índices e instaladores: sempre baixados de novo (o tamanho pode não mudar)
    case "$1" in releases.*.json|RELEASES|assets.*.json|*Setup.exe|*Portable.zip) return 0 ;; esac; return 1
}

sync_tag() {  # $1 tag
    tag="$1"; dir="$DATA/$tag"; mkdir -p "$dir"
    awk -F'\t' -v t="$tag" '$1==t {print $2 "\t" $3 "\t" $4}' "$LIST" > /tmp/tag.tsv

    for fase in pacotes instaladores indices; do
        while IFS="$(printf '\t')" read -r nome url tam; do
            seguro "$nome" || continue
            case "$fase" in
                pacotes)      case "$nome" in *.nupkg) ;; *) continue ;; esac ;;
                instaladores) case "$nome" in *Setup.exe|*Portable.zip) ;; *) continue ;; esac ;;
                indices)      case "$nome" in releases.*.json|RELEASES|assets.*.json) ;; *) continue ;; esac ;;
            esac
            atual=$(stat -c %s "$dir/$nome" 2>/dev/null || echo -1)
            if [ "$fase" = pacotes ] && [ "$atual" = "$tam" ]; then continue; fi
            if [ "$fase" != pacotes ] && ! indice "$nome" && [ "$atual" = "$tam" ]; then continue; fi
            echo "sync: $tag/$nome"
            baixar "$dir/$nome" "$url" || echo "sync: falha em $tag/$nome" >&2
        done < /tmp/tag.tsv
    done

    # remove do espelho o que não existe mais na Release
    for f in "$dir"/*; do
        [ -e "$f" ] || continue
        b=$(basename "$f")
        case "$b" in *.part) continue ;; esac
        cut -f2 /tmp/tag.tsv | grep -qxF "$b" || { echo "sync: removendo $tag/$b"; rm -f "$f"; }
    done
}

sync_once() {
    lista=$(curl -fsSL --max-time 60 -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/$REPO/releases?per_page=100") || { echo "sync: não consegui listar as Releases" >&2; return 1; }
    echo "$lista" | jq -r '.[] | select(.draft==false) | .tag_name as $t | .assets[] | [$t, .name, .browser_download_url, (.size|tostring)] | @tsv' > "$LIST" \
        || { echo "sync: resposta inválida do GitHub" >&2; return 1; }
    for tag in $(cut -f1 "$LIST" | sort -u); do
        seguro "$tag" || continue
        sync_tag "$tag"
    done
}

if [ "${1:-}" = "--uma-vez" ]; then sync_once; exit $?; fi

while true; do
    sync_once || true
    sleep "$INTERVAL"
done
