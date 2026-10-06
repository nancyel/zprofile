psalm () {
  local day=$(date +%-d)
  local version=${1:-CJB}
  local url="https://www.biblegateway.com/passage/?search=Psalm%20${day}%2C$((day+30))%2C$((day+60))%2C$((day+90))%2C$((day+120))&version=${version}&interface=print"
  open "$url"
}

# Rename KakaoTalk_Photo* images to <date_token>_1, <date_token>_2, ...
# Usage: kakao-rename 261004 [directory]
# Preview: DRY_RUN=1 kakao-rename 261004 ~/Downloads
kakao-rename() {
  local date_token=$1 dir=${2:-.}
  if [[ -z $date_token ]]; then
    print "Usage: kakao-rename <date_token> [directory]"
    return 1
  fi

  (  # subshell, so the cd and glob options don't leak into your terminal
    cd "$dir" || exit 1
    setopt extended_glob

    # (#i) = case-insensitive, (N) = no error if nothing matches,
    # (.) = regular files only; results are name-sorted (= chronological)
    local -a files
    files=( (#i)KakaoTalk_Photo*.(jpg|jpeg|png|gif|heic|webp)(N.) )

    if (( ${#files} == 0 )); then
      print "No KakaoTalk_Photo* images found in $dir"
      exit 0
    fi

    local count=1 f ext new
    for f in $files; do
      ext=${${f:e}:l}                     # extension, lowercased
      new=${date_token}_${count}.${ext}
      while [[ -e $new ]]; do             # never overwrite existing files
        (( count++ ))
        new=${date_token}_${count}.${ext}
      done

      if [[ -n $DRY_RUN ]]; then
        print "[dry run] $f -> $new"
      else
        mv -n -- "$f" "$new" && print "$f -> $new"
      fi
      (( count++ ))
    done
  )
}

eval "$(/opt/homebrew/bin/brew shellenv)"
