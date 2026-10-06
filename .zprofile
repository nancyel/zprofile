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

# Split paragraphs in a .txt/.md file into one sentence per line.
# Usage: split-sentences notes.md               (prints to screen)
#        split-sentences notes.md > notes_split.md
split-sentences() {
  local f=$1
  if [[ -z $f || ! -f $f ]]; then
    print "Usage: split-sentences <file.txt|file.md>"; return 1
  fi
  case ${f:e:l} in
    txt|md) ;;
    *) print "Only .txt or .md files are supported"; return 1 ;;
  esac

  perl -CSD -e '
my ($buf, $in_code) = ("", 0);
# Abbreviations and initials that should not end a sentence
my $abbr = qr/(?:\b(?:Mr|Mrs|Ms|Dr|Prof|Sr|Jr|St|vs|cf|No|e\.g|i\.e)|\b[A-Z])\.$/;

sub split_sent {
  my $t = shift; $t =~ s/\s+/ /g; $t =~ s/^ | $//g;
  my (@out, $cur, $depth); $cur = ""; $depth = 0;
  my @c = split //, $t;
  for (my $i = 0; $i < @c; $i++) {
    my $ch = $c[$i]; $cur .= $ch;
    # Track quotes so a quoted passage stays on one line
    if    ($ch eq "\x{201C}") { $depth++ }
    elsif ($ch eq "\x{201D}") { $depth-- if $depth > 0 }
    elsif ($ch eq q("))       { $depth = $depth ? 0 : 1 }
    next if $depth;
    # Split after . ? ! … (plus closing quotes) when the next word is not lowercase
    if ($i + 2 < @c && $c[$i+1] eq " " && $c[$i+2] !~ /\p{Ll}/
        && $cur =~ /[.?!\x{2026}][\x{201D}\x{2019}"\x27)\]]*$/
        && $cur !~ $abbr) {
      push @out, $cur; $cur = ""; $i++;
    }
  }
  push @out, $cur if length $cur;
  return @out;
}
sub flush { if (length $buf) { print "$_\n" for split_sent($buf); $buf = "" } }

while (my $line = <>) {
  chomp $line;
  if ($line =~ /^\s*(```|~~~)/) { flush(); $in_code = !$in_code; print "$line\n"; next }
  if ($in_code)                 { print "$line\n"; next }      # leave code blocks alone
  if ($line =~ /^\s*$/)         { flush(); print "\n"; next }  # keep paragraph breaks
  if ($line =~ /^\s*(#|>|[-*+]\s|\d+[.)]\s|\|)/) { flush(); print "$line\n"; next }  # headings, lists, quotes, tables
  $buf .= " $line";
}
flush();
' -- "$f"
}

eval "$(/opt/homebrew/bin/brew shellenv)"
