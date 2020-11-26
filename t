#!/bin/bash

EFF_TCACHE_DIR="${TCACHE_DIR:-$HOME/.tcmd-cache}"
mkdir -p $EFF_TCACHE_DIR

main() {
    target="$(command ls -1tp -- *.{cpp,py,java,c} 2>/dev/null | command sed 1q)"
    printf -- "| using target %s\n" "${target}"
    base="${target%.*}"
    printf -- "| using base %s\n" "${base}"
    extension="${target##*.}"
    printf -- "| using extension %s\n" "${extension}"

    run
}

check() {
    local OPTIND opt
    while getopts ":i:" opt; do
        case "$opt" in
            i)
                printf "| input file %s\n" "$opt"
                inputfile="$OPTARG"
                ;;
            \?)
                print_help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
    if [ "$inputfile" = "" ]; then
        printf -- '| no input file given\n'
    elif [ ! -f "$inputfile" ]; then
        printf -- '| %s does not exist, resorting to stdin\n' "$inputfile"
        inputfile=""
    else
        printf -- "| inputfile is %s\n" "${inputfile}"
    fi
}

run() {
    case "$extension" in
        c)
            # gcc "$target" && ./a.out
            ;;
        cpp)
            filehash="$(md5 -q ${target})"
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            printf -- "| hash is %s\n" "$filehash"
            if [ -e "${exppath}" ]; then
                printf -- "| found cached @ %s\n" "$exppath"
                cp "$exppath" ./a.out
            else
                g++-10 -DFEAST_LOCAL -std=c++11 "$target" || exit $?
                printf -- "| caching @ %s\n" "$exppath"
                cp ./a.out "$exppath"
            fi

            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;
        java)
            javac "$target" && java "$base"
            ;;
        py)
            python "$target"
            ;;
        *)
            printf -- "no good procedure found\n"
            ;;
    esac
}

print_help() {
    printf -- '-i <input file>\n'
}

main "$@"
