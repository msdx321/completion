#
# Completion enhancements
#

if [[ ${TERM} == dumb ]]; then
  return 1
fi

() {
  builtin emulate -L zsh -o EXTENDED_GLOB

  # Check if dumpfile is up-to-date by comparing the full path and
  # last modification time of all the completion functions in fpath.
  local zdumpfile zstats zold_dat
  local -i zdump_dat=1
  zstyle -s ':zim:completion' dumpfile 'zdumpfile' || zdumpfile=${ZDOTDIR:-${HOME}}/.zcompdump
  LC_ALL=C local -r zcomps=(${^fpath}/^([^_]*|*~|*.zwc)(N))
  if (( ${#zcomps} )); then
    zmodload -F zsh/stat b:zstat && zstat -A zstats +mtime ${zcomps} || return 1
  fi
  local -r znew_dat=${ZSH_VERSION}$'\0'${(pj:\0:)zcomps}$'\0'${(pj:\0:)zstats}
  if [[ -e ${zdumpfile}.dat ]]; then
    zmodload -F zsh/system b:sysread && sysread -s ${#znew_dat} zold_dat <${zdumpfile}.dat || return 1
    if [[ ${zold_dat} == ${znew_dat} ]] zdump_dat=0
  fi
  if (( zdump_dat )); then
    command rm -f ${zdumpfile}(|.dat|.zwc(|.old))(N) || return 1
  fi

  # Load and initialize the completion system
  autoload -Uz compinit && compinit -C -d ${zdumpfile} || return 1

  if [[ ! ${zdumpfile}.dat -nt ${zdumpfile} ]]; then
    >! ${zdumpfile}.dat <<<${znew_dat}
  fi
  # Compile the completion dumpfile; significant speedup
  if [[ ! ${zdumpfile}.zwc -nt ${zdumpfile} ]] zcompile ${zdumpfile}
}
