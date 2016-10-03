set -e -o pipefail

err() {
    echo -ne $@ 1>&2
}

usage() {
    err "Usage: "
    err "\t$0 create <json params>"
    err "\t$0 delete <json params>"
    err "\t$0 attach <json params>"
    err "\t$0 detach <json params>"
    err "\t$0 mount <mount dir> <device> <json params>"
    err "\t$0 unmount <mount dir> <json params>"
    err "\t$0 init"
    exit 1
}

main()
{

    case $1 in
        init)
            ;;
        create|delete|attach)
            parse "$2"
            ;;
        detach)
            DEVICE="$2"
            ;;
        mount)
            MNT_DEST="$2"
            DEVICE="$3"
            parse "$4"
            ;;
        unmount)
            MNT_DEST="$2" 
            parse "$3"
            ;;
        *)
            usage
            ;;
    esac
    "$@"
}

declare -A OPTS
parse()
{
    mapfile -t < <(echo "$1" | jq -r 'to_entries | map([.key, .value]) | .[]' | jq '.[]' | sed 's!^"\(.*\)"$!\1!g')
    for ((i=0;i < ${#MAPFILE[@]} ; i+=2)) do
        OPTS[${MAPFILE[$i]}]=${MAPFILE[$((i+1))]}
    done
}

print_options()
{
    for ((i=1; i < $#; i+=2)) do
        j=$((i+1))
        jq -n --arg k ${!i} --arg v ${!j} '{"key": $k, "value": $v}'
    done | jq -c -s '{"status": "Success", "options": from_entries}'
}

print_device()
{
    echo -n "$@" | jq -R -c -s '{"status": "Success", "device": .}'
}

print_not_supported()
{
    echo -n "$@" | jq -R -c -s '{"status": "Not supported", "message": .}'
}

print_success()
{
    echo -n "$@" | jq -R -c -s '{"status": "Success", "message": .}'
}

print_error()
{
    echo -n "$@" | jq -R -c -s '{"status": "Failure", "message": .}'
    return 1
}
