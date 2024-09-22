#!/bin/bash

# version
version=0.2

# menu 
menu_main() {
    context=main
    URL=

    switch_options
    print_details

    # show if URL is invalid
    if [ "$inv_url" = true ]; then
        random_index=$((RANDOM % ${#inv_text[@]}))
        random_text="${inv_text[$random_index]}"
        
        echo -e "\e[31m$random_text\e[0m"

        inv_url=false
    elif [ "$inv_url" = url ]; then
        echo -e "\e[31mYou need to paste a Link (URL) from your web browser into this field\e[0m"
        inv_url=false
    elif [ "$inv_url" = short ]; then
        inv_url=false
    fi

    echo -n "Enter P/D/X/URL: "
    read URL

    if [ "$URL" = "P" ] || [ "$URL" = "p" ]; then
        URL=
        menu_preferences
        return
    elif [ "$URL" = "D" ] || [ "$URL" = "d" ]; then
        nohup xdg-open "$DOWNLOAD_DIR" &>/dev/null & 
        return
    elif [ "$URL" = "Q" ] || [ "$URL" = "q" ]; then
        # queue mode here
        return
    elif [ "$URL" = "H" ] || [ "$URL" = "h" ]; then
        nohup xdg-open ~/.ytBASH-history &>/dev/null & 
        return
    elif [ "$URL" = "URL" ] || [ "$URL" = "url" ]; then
        inv_url=url
        return
    elif [ "$URL" = "X" ] || [ "$URL" = "x" ]; then
        exit
    fi

    # check cookie option before entering options menu
    if [ "$cookiesdefault" = false ]; then
        option_cookies=true
    fi

    check_url
    if [ ! "$inv_url" = false ]; then
        return
    fi
    clean_url
    menu_options 
    
}

# download options
menu_options() {
    context=options
    FORMAT_CHOICE=

    print_details

    echo "Choose Options:"
    echo
    echo "[A] Audio"
    echo "[V] Video"
    echo "[L] List All"
    echo
    # echo "[F] Change Format"
    # echo "[Q] Add to Queue"
    # echo
    echo -n "[P] Playlist "
        if [ "$option_playlist" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    echo -n "[S] Subtitles "
        if [ "$option_subtitles" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    echo -n "[C] Use Cookies "
        if [ "$option_cookies" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    echo
    echo "[B] Go Back"
    check_invalid
    read -n 1 -p "" FORMAT_CHOICE
    echo 
    
    case "$FORMAT_CHOICE" in
        [Aa])
            dl_audio
            ;;
        [Vv])
            dl_video
            ;;
        [Ll])
            dl_list
            ;;
    #    [Ff])
    #        change_format
    #        ;;
    #    [Qq])
    #        change_queue
    #        ;;
        [Pp])
            if [ "$option_playlist" = false ]; then
                option_playlist=true
            else 
                option_playlist=false
            fi
            menu_options
            ;;
        [Ss])
            if [ "$option_subtitles" = false ]; then
                option_subtitles=true
            else 
                option_subtitles=false
            fi
            menu_options
            ;;
        [Cc])
            check_cookies

            if [ "$cookiereturn" = true ]; then
                cookiereturn=false
            else
                if [ "$option_cookies" = false ]; then
                    option_cookies=true
                else 
                    option_cookies=false
                fi
            fi
            menu_options
            ;;
        [Bb])
            return
            ;;
        *)
            inv_argument=true
            menu_options
            ;;
    esac

}

dl_audio() {
    check_keephistory
    check_options


    clear
    echo "Downloading Audio..."
    print_line
    yt-dlp \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        $playlist_mode \
        $subtitles_mode \
        $cookies_mode \
        $audiocover_mode \
        --output "$DOWNLOAD_DIR/%(title)s.%(ext)s" \
        "$URL"
    print_line
    echo "Finished!"
    echo
    read -n 1 -p "Press any button..."
}

dl_video() {
    check_keephistory
    check_options

    clear
    echo "Downloading Video..."
    print_line
    yt-dlp \
        --format "best[ext=mp4]" \
        $playlist_mode \
        $subtitles_mode \
        $cookies_mode \
        --output "$DOWNLOAD_DIR/%(title)s.%(ext)s" \
        "$URL"
    print_line
    echo "Finished!"
    echo
    read -n 1 -p "Press any button..."
}

dl_list() {
    clear
    echo "Getting all formats..."
    print_line

    check_options

    yt-dlp $cookies_mode -F $URL 

    print_line
    echo
    echo "[B] Go Back"
    echo
    read -p "Enter B/CODE/ID: " LISTALL_CHOICE
    
    if [[ "$LISTALL_CHOICE" =~ [Bb] ]]; then
        return
    fi

    check_keephistory

    clear
    echo "Downloading selected format..."
    print_line
    
    yt-dlp \
        -f $LISTALL_CHOICE \
        $playlist_mode \
        $subtitles_mode \
        $cookies_mode \
        --output "$DOWNLOAD_DIR/%(title)s.%(ext)s" \
        "$URL"
        
    print_line
    echo "Finished!"
    echo
    read -n 1 -p "Press any button..."
    
}

# preferences
menu_preferences() {
    context=preferences
    PREFERENCE_CHOICE=

    print_details

    echo "Preferences:"
    echo
    echo -n "[D] Change default download directory "
        echo -e "\e[34m[$DOWNLOAD_DIR]\e[0m"
    echo -n "[H] Keep download history "
        if [ "$keephistory" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    echo -n "[C] Use cookies by default "
        if [ "$cookiesdefault" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    echo -n "[T] Use video thumbnail as audio cover "
        if [ "$thumbnailaudiocover" = false ]; then
            echo -e "\e[31m[FALSE]\e[0m"
        else 
            echo -e "\e[32m[TRUE]\e[0m"
        fi
    # echo -n "[Q] Clean queue when restarting "
    #    if [ "$cleanqueue" = false ]; then
    #        echo -e "\e[31m[FALSE]\e[0m"
    #    else 
    #        echo -e "\e[32m[TRUE]\e[0m"
    #    fi
    echo
    if [ -f "$DESKTOP_FILE_PATH" ]; then
        echo "[G] Delete .desktop file"
    else
        echo "[G] Generate .desktop file"
    fi
    echo "[O] Open script directory"
    echo
    echo "[B] Go Back "
    check_invalid
    read -n 1 -p "" PREFERENCE_CHOICE
    echo

    case "$PREFERENCE_CHOICE" in
        [Hh])
            if [ "$keephistory" = false ]; then
                keephistory=true
            else 
                keephistory=false
            fi
            write_preferences
            ;;
        [Dd])
            pref_defaultdir
            ;;
        [Cc])

            check_cookies

            if [ "$cookiereturn" = true ]; then
                cookiereturn=false
            else
                if [ "$cookiesdefault" = false ]; then
                    cookiesdefault=true
                else 
                    cookiesdefault=false
                fi
            fi

            write_preferences
            ;;
        [Tt])
            if [ "$thumbnailaudiocover" = false ]; then
                thumbnailaudiocover=true
            else 
                thumbnailaudiocover=false
            fi
            write_preferences
            ;;
    #    [Qq])
    #        if [ "$cleanqueue" = false ]; then
    #            cleanqueue=true
    #        else 
    #            cleanqueue=false
    #        fi
    #        write_preferences
    #        ;;
        [Gg])
            pref_desktop
            ;;
        [Oo])
            nohup xdg-open "$(dirname "$(realpath "$0")")" &>/dev/null & 
            ;;
        [Bb])
            return
            ;;
        *)
            inv_argument=true
            ;;
    esac

    menu_preferences

}

write_preferences() {
    echo "# .ytBASH-config-file:" > ~/.ytBASH-config
    echo "DOWNLOAD_DIR=$DOWNLOAD_DIR" >> ~/.ytBASH-config
    echo "keephistory=$keephistory" >> ~/.ytBASH-config
    echo "cookiesdefault=$cookiesdefault" >> ~/.ytBASH-config
    echo "thumbnailaudiocover=$thumbnailaudiocover" >> ~/.ytBASH-config
    echo "cleanqueue=$cleanqueue" >> ~/.ytBASH-config

    load_preferences
}

pref_defaultdir() {
    print_details
    echo "Choose the folder you want to use with the file manager window that just opened in the background."
    echo
    echo "Warning: If no file manager opens up you do not have zenity installed"
    echo "In that case you need to edit it manually: ~/.ytBASH-config)"
    echo

    DOWNLOAD_DIR_temp=$(zenity --file-selection --directory --title="Select Default Download Directory")

    if [ -n "$DOWNLOAD_DIR_temp" ]; then
        DOWNLOAD_DIR=$DOWNLOAD_DIR_temp
        write_preferences
    else
        echo "No directory selected."
    fi
}

pref_desktop() {
    print_details
    mkdir -p "$HOME/.local/share/applications"

    # delete the desktop entry
    if [ -f "$DESKTOP_FILE_PATH" ]; then
        rm "$DESKTOP_FILE_PATH"
        if [ $? -eq 0 ]; then
            echo "Desktop file successfully removed: $DESKTOP_FILE_PATH"
        else
            echo "Failed to remove desktop file: $DESKTOP_FILE_PATH"
        fi
        echo 
        read -n 1 -p "Press any button..."
    else
        # write the .desktop file content
        echo "[Desktop Entry]" > "$DESKTOP_FILE_PATH"
        echo "Version=$version" >> "$DESKTOP_FILE_PATH"
        echo "Name=ytBASH" >> "$DESKTOP_FILE_PATH"
        echo "Comment=Download video or audio using yt-dlp" >> "$DESKTOP_FILE_PATH"
        echo "Exec=$SCRIPT_PATH" >> "$DESKTOP_FILE_PATH"
        echo "Icon=youtube-dl" >> "$DESKTOP_FILE_PATH"
        echo "Terminal=true" >> "$DESKTOP_FILE_PATH"
        echo "Type=Application" >> "$DESKTOP_FILE_PATH"
        echo "Categories=Utility;Network;" >> "$DESKTOP_FILE_PATH"

        echo "Desktop file generated at $DESKTOP_FILE_PATH"
        echo
        read -n 1 -p "Press any button..."
    fi
}

# various
print_line() {
    printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'
}

print_details() {
    clear
    echo -n "ytBASH $version"

    case "$context" in
        main)
            echo -e " | \e[32m[P] Preferences\e[0m | \e[34m[D] Downloads\e[0m | \e[31m[X] Exit\e[0m"
            ;;
        options)
            echo -e " | \e[4m\e[34m$URL\e[0m\e[0m"
            ;;
        preferences)
            echo
            ;;
        *)
            echo
            ;;
    esac

    context=none

    print_line
}

check_invalid() {
    if [ "$inv_argument" = true ]; then
        echo
        echo -e "\e[31mInvalid Argument!\e[0m"
    else 
        echo
    fi
    inv_argument=false
}

check_keephistory() {
    if [ "$keephistory" = true ]; then
        echo $URL >> .ytBASH-history
    fi
}

check_options() {

    # check if playlist mode is enabled
    if [ "$option_playlist" = true ]; then
        playlist_mode=--yes-playlist
    else 
        playlist_mode=--no-playlist
    fi

    # check if subtitles are enabled
    if [ "$option_subtitles" = true ]; then
        subtitles_mode=--write-subs
    else 
        subtitles_mode=--no-write-subs
    fi

    # check if cookies are enabled
    if [ "$option_cookies" = true ]; then
        cookies_mode="--cookies ~/cookies.txt"
    else 
        cookies_mode=
    fi

    # check if thumbnail audio cover is enabled
    if [ "$thumbnailaudiocover" = true ]; then
        audiocover_mode=--embed-thumbnail
    else 
        audiocover_mode=
    fi
}

check_cookies() {
    if [ ! -f "$HOME/cookies.txt" ]; then

        cookiesdefault=false
        option_cookies=false

        cookiereturn=true

        print_details
        echo -e "\e[31mWarning:\e[0m cookies.txt not found"
        echo "Install the browser addon 'cookies.txt' and export them to your HOME directory"
        echo
        read -n 1 -p "Press any button..."
    fi
    
}

switch_options() {

    # set switch options back to default values
    option_playlist=false
    option_subtitles=false
    option_cookies=false
}

clean_url() {
    if [[ "$URL" =~ ^\".*\"$ || "$URL" =~ ^\'.*\'$ ]]; then
        URL="${URL:1:-1}"
    fi
}

check_url() {
    if [ "${#URL}" -le 4 ]; then
        inv_url=short
        return
    elif [[ "$URL" =~ ^(https?://)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
        inv_url=false
        return
    else
        inv_url=true
        return
    fi
}

# important
set_defaults() {

    # preferences
    DOWNLOAD_DIR=~/Downloads/ytBASH
    keephistory=true
    cookiesdefault=false
    thumbnailaudiocover=true
    cleanqueue=false

    # create folder in case it doesn't exist
    mkdir -p "$DOWNLOAD_DIR"

    # set default values
    URL=
    inv_argument=false
    context=none
    cookiereturn=false
    option_cookies=false
    option_playlist=false
    option_subtitles=false
    inv_url=false
    DESKTOP_FILE_PATH="$HOME/.local/share/applications/ytBASH.desktop"


    switch_options    

    # script path as variable
    SCRIPT_PATH="$(realpath "$0")"

    # invalid url text 
    inv_text=(
        "That's a weird URL."
        "This doesn't look like a URL to me."
        "Please check your URL."
        "Your URL has one or more faults."
        "Do you think that's a URL?"
        "Weird URL detected."
        "Faulty URL detected."
        "Please stop spamming bad URLs."
        "WARNING: CHECK YOUR URL IMMEDIATELY."
        "This URL does not look right."
        "Please eat your URL."
        "Bad URL detected."
        "There seems to be something wrong with your URL."
        "That's not a valid URL."
    )
}

load_preferences() {
    if [ -f ~/.ytBASH-config ]; then
        while IFS='=' read -r key value; do
            case "$key" in
                "DOWNLOAD_DIR") DOWNLOAD_DIR="$value" ;;
                "keephistory") keephistory="$value" ;;
                "cookiesdefault") cookiesdefault="$value" ;;
                "thumbnailaudiocover") thumbnailaudiocover="$value" ;;
                "cleanqueue") cleanqueue="$value" ;;
            esac
        done < ~/.ytBASH-config
    fi
}

check_dependencies() {
    missing_software=()

    # yt-dlp check
    if ! command -v yt-dlp &> /dev/null; then
        missing_software+=("yt-dlp")
    fi

    # ffmpeg check
    if ! command -v ffmpeg &> /dev/null; then
        missing_software+=("ffmpeg")
    fi

    # check if there is missing software
    if [ ${#missing_software[@]} -eq 0 ]; then
        return
    else
        print_details
        echo "You are missing software required by ytBASH:"
        echo
        for software in "${missing_software[@]}"; do
            echo "- $software"
        done
        echo
        read -n 1 -p "Press any button..."
    fi

}

# main script
check_dependencies
set_defaults
load_preferences
while true; do 
    menu_main
done

# todo: 
# queue
# say that it wrote to the history file
# custom arguments
