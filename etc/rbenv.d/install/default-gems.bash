if declare -Ff after_install >/dev/null; then
  after_install install_default_gems
else
  echo "rbenv: rbenv-default-gems plugin requires ruby-build 20130129 or later" >&2
fi

install_default_gems() {
  # Only install default gems after successfully installing Ruby.
  [ "$STATUS" = "0" ] || return 0

  if [ -f "${RBENV_ROOT}/default-gems" ]; then
    local line gem_name gem_version args

    # Read gem names and versions from $RBENV_ROOT/default-gems.
    while IFS=" " read -r -a line; do

      # Skip empty lines.
      [ "${#line[@]}" -gt 0 ] || continue

      # Skip comment lines that begin with `#`.
      [ "${line[0]:0:1}" != "#" ] || continue

      gem_name="${line[0]}"
      gem_version="${line[1]}"
      gem_no_document="${line[2]}"
      gem_install="install"
      
      arguments=""
      if [ "$gem_name" == "specific_install" ]; then
        gem_install="specific_install"
        arguments="$gem_version"
      else
        if [ "$gem_version" == "--pre" ]; then
          arguments=" --pre "
        elif [ "$gem_version" == "--no-document" ]; then
          arguments=" --no-document "
        elif [ -n "$gem_version" ]; then
          arguments=" --version '$gem_version' "
        fi
      
        if [ "$gem_no_document" == "--no-document" ]; then
          arguments="$arguments --no-document "
        fi
      fi
      
      args=( ${arguments} )

      # Invoke `gem install` in the just-installed Ruby. Point its
      # stdin to /dev/null or else it'll read from our default-gems
      # file.
      RBENV_VERSION="$VERSION_NAME" rbenv-exec gem "$gem_install" "$gem_name" "${args[@]}" < /dev/null || {
        echo "rbenv: error installing gem \`$gem_name'"
      } >&2

    done < "${RBENV_ROOT}/default-gems"
  fi
}
