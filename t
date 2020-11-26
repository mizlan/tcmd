#!/bin/bash

main() {
    check "$@"
    target="$(command ls -1tp -- *.{cpp,py,java,c,ml} 2>/dev/null | command sed 1q)"
    base="${target%.*}"
    extension="${target##*.}"

    verbose_print "using target %s\n" "${target}"
    verbose_print "using base %s\n" "${base}"
    verbose_print "using extension %s\n" "${extension}"

    if [ -z "$inputfile" ]; then
        verbose_print 'no input file given\n'
    elif [ ! -f "$inputfile" ]; then
        verbose_print '%s does not exist, resorting to stdin\n' "$inputfile"
        inputfile=""
    else
        verbose_print "inputfile is %s\n" "${inputfile}"
    fi

    if [ -z "${CACHE_OFF}" ]; then
        verbose_print "using cache\n"

        EFF_TCACHE_DIR="${TCACHE_DIR:-$HOME/.tcmd-cache}"
        if [ ! -d "${EFF_TCACHE_DIR}" ]; then
            error_print "cache directory %s does not exist; creating\n" "${EFF_TCACHE_DIR}"
            mkdir -p "$EFF_TCACHE_DIR"
        fi
    fi

    run
}

check() {
    local OPTIND opt
    while getopts ":vci:" opt; do
        case "$opt" in
            i)
                verbose_print "input file %s\n" "$opt"
                inputfile="$OPTARG"
                ;;
            v)
                VERBOSE="verbose"
                ;;
            c)
                CACHE_OFF="cache_off"
                ;;
            \?)
                print_help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
}

run() {
    case "$extension" in
        c)
            filehash=$(md5sum "${target}" | awk '{ print $1 }')
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "hash is %s\n" "$filehash"
            if [ -e "${exppath}" ] && [ -z "${CACHE_OFF}" ]; then
                verbose_print "found cached @ %s\n" "$exppath"
                cp "$exppath" ./a.out
            else
                verbose_print "building\n"
                gcc "$target" || exit $?
                if [ -z "${CACHE_OFF}" ]; then
                    verbose_print "caching @ %s\n" "$exppath"
                    cp ./a.out "$exppath"
                fi
            fi

            verbose_print "running executable\n"
            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;

        cpp)
            filehash=$(md5sum "${target}" | awk '{ print $1 }')
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "hash is %s\n" "$filehash"
            if [ -e "${exppath}" ] && [ -z "${CACHE_OFF}" ]; then
                verbose_print "found cached @ %s\n" "$exppath"
                cp "$exppath" ./a.out
            else
                verbose_print "building\n"
                g++-10 -DFEAST_LOCAL -std=c++11 "$target" || exit $?
                if [ -z "${CACHE_OFF}" ]; then
                    verbose_print "caching @ %s\n" "$exppath"
                    cp ./a.out "$exppath"
                fi
            fi

            verbose_print "running executable\n"
            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;

        java)
            filehash=$(md5sum "${target}" | awk '{ print $1 }')
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "hash is %s\n" "$filehash"
            if [ -e "${exppath}" ] && [ -z "${CACHE_OFF}" ]; then
                verbose_print "found cached @ %s\n" "$exppath"
                cp "$exppath" "${base}.class"
            else
                verbose_print "building\n"
                javac "$target" || exit $?
                verbose_print "caching @ %s\n" "$exppath"
                if [ -z "${CACHE_OFF}" ]; then
                    verbose_print "caching @ %s\n" "$exppath"
                    cp "${base}.class"  "$exppath"
                fi
            fi

            verbose_print "running executable\n"
            if [ -n "$inputfile" ]; then
                java "$base" < "$inputfile"
            else
                java "$base"
            fi
            ;;

        py)
            # no caching options available
            python "$target"
            ;;

        *)
            error_print "no good procedure found, or not implemented: extension: %s\n" "$extension" 1>&2
            exit 1;
            ;;
    esac
}

print_help() {
    printf -- 'usage:\n'
    printf -- '  -i <input file>\n'
    printf -- '  -v (verbose)\n'
    printf -- '  -c do not use the cache\n'
}

verbose_print() {
    if [ -n "$VERBOSE" ]; then
        tput setaf 3
        printf '(verbose) | '
        # reset tput style change
        tput sgr0
        printf -- "$@"
    fi
}

error_print() {
    tput setaf 1
    printf '[!] ' 1>&2
    # reset tput style change
    tput sgr0
    printf -- "$@" 1>&2
}

main "$@"
