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

# shellcheck disable=SC2207
appsAR=($(grep '^Apps:' "$AppsConf" | sed 's/^Apps: *//'))
AmountOfApps=$(grep "Apps-Amount:" "$AppsConf" | awk -F': ' '{print $2}')

for app in "${appsAR[@]}"
do
    pathToApp=$(which "$app" 2>/dev/null)
    if [[ -z $pathToApp ]]
    then
        echo "$app is missing. Please check if the app is installed."
    fi
    unset pathToApp
done


# shellcheck disable=SC2120
launchProfileApps() {
    profileName="$1"
    if ! grep -q "^\[profile:$profileName\]" "$AppsConf"
    then
        echo "Profile '$profileName' not found in config."
        exit 1
    fi

    appsLine=$(awk "/\\[profile:$profileName\\]/ {found=1} found && /^Apps:/ {print; exit}" "$AppsConf")
    # shellcheck disable=SC2001
    apps=$(echo "$appsLine" | sed 's/^Apps:[[:space:]]*//')

    if [[ -z $apps ]]
    then
        echo "No applications defined for profile '$profileName'."
        exit 1
    fi

    for app in $apps
    do
        if command -v "$app" >/dev/null 2>&1
        then
            "$app" &
        else
            echo "$app not found on system."
        fi
    done
}

case "$1" in
    -ap|--add-app)
        shift
        if [[ -n $1 ]]
        then
            appName="$1"
            sed -i "/^Apps:/ s|$| $appName|" "$AppsConf"
            newCount=$((AmountOfApps + 1))
            sed -i "s/^Apps-Amount:.*/Apps-Amount: $newCount/" "$AppsConf"  #pancakes are f*cking delicious
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

    -E|--edit)
        echo "Opening config file '$AppsConf' for editing..."
        sudo nano "$AppsConf"
    ;;

    #profiles
    -cP|--create-profile)
    shift
        if [[ -n "$1" ]]
        then
            profile_name="$1"
            if grep -q "^\[profile:$profile_name\]" "$AppsConf"
            then
                echo "Profile '$profile_name' already exists."
            else
                echo "Creating profile '$profile_name'..."

                
                cat >> "$AppsConf" <<EOF

[profile:$profile_name]
Apps:
Apps-Amount: 0
EOF

                echo "Profile '$profile_name' created."

            
                if [[ -n "$2" ]]
                then
                    shift
                    app="$1"
                    sed -i "/^\[profile:$profile_name\]/,/\[profile:/s/Apps:/Apps: $app /" "$AppsConf"
                    echo "App '$app' added to profile '$profile_name'."
                fi
            fi
        else
            echo "Please specify a profile name."
        fi
    ;;

    -dP|--delete-profile)
        shift
        if [[ -n "$1" ]]
        then
            profile_name="$1"
            if grep -q "^\[profile:$profile_name\]" "$AppsConf"
            then
                while true
                do
                    echo "Are you sure you want to delete the profile '$profile_name'? (y/n)"
                    read -r confirm
                    case "$confirm" in
                        y|Y)
                            echo "Deleting profile '$profile_name'..."
                            sed -i "/^\[profile:$profile_name\]/,/^\[profile:/ { /^\[profile:/!d }" "$AppsConf"
                            echo "Profile '$profile_name' deleted."
                            break
                        ;;
                        n|N)
                            echo "Aborted. Profile '$profile_name' not deleted."
                            break
                        ;;
                        *)
                            echo "Invalid input. Please answer with 'y' or 'n'."
                        ;;
                    esac
                done
            else
                echo "Profile '$profile_name' not found."
            fi
        else
            echo "Please specify a profile name."
        fi
    ;;

    -Atp|--add-app-to-profile)
        shift
        if [[ -n "$1" && -n "$2" ]]
        then
            profile_name="$1"
            app_name="$2"

            if grep -q "^\[profile:$profile_name\]" "$AppsConf"
            then
                echo "Adding app '$app_name' to profile '$profile_name'..."
                sed -i "/^\[profile:$profile_name\]/,/^\[profile:/s/Apps: .*/Apps: & $app_name/" "$AppsConf"
                
                sed -i "/^\[profile:$profile_name\]/,/^\[profile:/s/Apps-Amount: [0-9]\+/Apps-Amount: $(( $(grep "Apps-Amount:" "$AppsConf" | awk '{print $2}') + 1 ))/" "$AppsConf"

                echo "App '$app_name' added to profile '$profile_name'."
            else
                echo "Profile '$profile_name' not found."
            fi
        else
            echo "Please specify both a profile name and an app name."
        fi
    ;;

    #misc and help
    -h|-?|--help)
        echo "lazyass - launches the provided apps because you are lazy and dont want to open them all one by one"
        echo "-ap/--add-app - adds app to the list"
        echo "-rma/--remove-app - removes an app from the list"
        echo "-la/--list-apps - lists current apps"

    ;;

    -*)
        echo "Invalid argument provided."
        exit 1
    ;;

    *)
        launchProfileApps
    ;;
esac