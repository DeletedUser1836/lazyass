#!/bin/bash

AppsConf="$HOME/.apps-script.conf"

if [[ ! -f "$AppsConf" ]]
then
    echo "Could not locate the config file at $AppsConf"
    echo "Creating config file..."
    cat > "$AppsConf" <<END
Apps:
Apps-Amount: 0
END
fi

apps=($(grep '^Apps:' "$AppsConf" | sed 's/^Apps: *//'))
AmountOfApps=$(grep "Apps-Amount:" "$AppsConf" | awk -F': ' '{print $2}')

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
            appName="$1"
            sed -i "/^Apps:/ s|$| $appName|" "$AppsConf"
            newCount=$((AmountOfApps + 1))
            sed -i "s/^Apps-Amount:.*/Apps-Amount: $newCount/" "$AppsConf"
            echo "App '$appName' added to config."
        else
            echo "No app name provided."
        fi
    ;;

    -rma|--remove-app)
        shift
        if [[ -n $1 ]]
        then
            appName="$1"
            if grep -qE "^Apps:.*\b$appName\b" "$AppsConf"
            then
                echo "Do you really want to delete '$appName' from the app list? [y/n]"
                read -r conf
                while true
                do
                    case "$conf" in
                        y)
                            sed -i "s/\b$appName\b//g" "$AppsConf"
                            sed -i 's/  */ /g' "$AppsConf"
                            sed -i 's/Apps: /Apps:/g' "$AppsConf"
                            newCount=$((AmountOfApps - 1))
                            sed -i "s/^Apps-Amount:.*/Apps-Amount: $newCount/" "$AppsConf"
                            echo "App '$appName' was deleted from the list."
                            break
                        ;;
                        n)
                            echo "Abort."
                            break
                        ;;
                        *)
                            echo "Invalid argument provided. Please answer with 'y' or 'n': "
                            read -r conf
                        ;;
                    esac
                done
            else
                echo "App '$appName' is not in the config list."
            fi
        else
            echo "No app name was provided."
        fi
    ;;

    -la|--list-apps)
        echo "Total apps: $AmountOfApps"
        echo "Listing..."
        grep "^Apps:" "$AppsConf" | sed 's/^Apps: *//'
    ;;

    -*)
        echo "Invalid argument provided."
    ;;

    *)
        echo "Launching apps..."
        for app in "${apps[@]}"
        do
            command -v "$app" >/dev/null && "$app" &
        done
    ;;
esac