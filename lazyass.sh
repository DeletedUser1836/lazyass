#!/bin/bash

AppsConf="$HOME/.apps-script.conf"

if [[ ! -f "$AppsConf" ]]
then
    echo "Could not locate the config file at $AppsConf"
    echo "Creating config file..."
    cat > "$AppsConf" <<EOF
Apps:
Apps-Amount:
EOF
fi

declare -a apps=()

# shellcheck disable=SC2034
AmountOfApps=$($AppsConf|grep "Apps-Amount:")

for app in "${apps[@]}"
do
    pathToApp=$(which "$app" 2>/dev/null)
    if [[ -z $pathToApp ]]
    then
        echo "$app is missing. Please check if the app is installed."
    fi
    unset pathToApp
done

case "$1" in
    -ap|--add-app)
        shift
        if [[ -n $1 ]]
        then
            echo "$1" >> "$AppsConf"
            echo "App '$1' added to config."
        else
            echo "No app name provided."
        fi
    ;;

    -rma|--remove-app)
        #TODO
    ;;
esac