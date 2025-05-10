#!/bin/bash

AppsConf=$("$HOME"/.apps-script.conf)

if [[ -f $AppsConf==false ]]
then
    echo "Could not lokate the config file at $AppsConf"
    echo "Creating config file..."
    touch .apps-scirpt.conf
    echo "
    Apps:
    Apps-Amount: 
    " > "$AppsConf"
fi

declare -a apps=(

)

AmountOfApps=$($AppsConf | grep "Apps-Amount:")

for app in "${apps[@]}"
do
    pathToApp=$(which "$app" 2>/dev/null)
    if [[ -z $pathToApp ]]
    then
        echo "$app is missng please if the app is installed."
    fi
    unset PathToApp
done

case "$1" in
    -ap|--add-app)
        
    ;;

    -rma|--remove-app)

    ;;
esac