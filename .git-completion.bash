<<<<<<< HEAD
# bash/zsh completion support for core Git.
#
# Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Conceptually based on gitcompletion (http://gitweb.hawaga.org.uk/).
# Distributed under the GNU General Public License, version 2.0.
#
# The contained completion routines provide support for completing:
#
#    *) local and remote branch names
#    *) local and remote tag names
#    *) .git/remotes file names
#    *) git 'subcommands'
#    *) tree paths within 'ref:path/to/file' expressions
#    *) file paths within current working directory and index
#    *) common --long-options
#
# To use these routines:
#
#    1) Copy this file to somewhere (e.g. ~/.git-completion.sh).
#    2) Add the following line to your .bashrc/.zshrc:
#        source ~/.git-completion.sh
#    3) Consider changing your PS1 to also show the current branch,
#       see git-prompt.sh for details.

case "$COMP_WORDBREAKS" in
*:*) : great ;;
*)   COMP_WORDBREAKS="$COMP_WORDBREAKS:"
esac

# __gitdir accepts 0 or 1 arguments (i.e., location)
# returns location of .git repo
__gitdir ()
{
	if [ -z "${1-}" ]; then
		if [ -n "${__git_dir-}" ]; then
			echo "$__git_dir"
		elif [ -n "${GIT_DIR-}" ]; then
			test -d "${GIT_DIR-}" || return 1
			echo "$GIT_DIR"
		elif [ -d .git ]; then
			echo .git
		else
			git rev-parse --git-dir 2>/dev/null
		fi
	elif [ -d "$1/.git" ]; then
		echo "$1/.git"
	else
		echo "$1"
	fi
}

# The following function is based on code from:
#
#   bash_completion - programmable completion functions for bash 3.2+
#
#   Copyright © 2006-2008, Ian Macdonald <ian@caliban.org>
#             © 2009-2010, Bash Completion Maintainers
#                     <bash-completion-devel@lists.alioth.debian.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#   The latest version of this software can be obtained here:
#
#   http://bash-completion.alioth.debian.org/
#
#   RELEASE: 2.x

# This function can be used to access a tokenized list of words
# on the command line:
#
#	__git_reassemble_comp_words_by_ref '=:'
#	if test "${words_[cword_-1]}" = -w
#	then
#		...
#	fi
#
# The argument should be a collection of characters from the list of
# word completion separators (COMP_WORDBREAKS) to treat as ordinary
# characters.
#
# This is roughly equivalent to going back in time and setting
# COMP_WORDBREAKS to exclude those characters.  The intent is to
# make option types like --date=<type> and <rev>:<path> easy to
# recognize by treating each shell word as a single token.
#
# It is best not to set COMP_WORDBREAKS directly because the value is
# shared with other completion scripts.  By the time the completion
# function gets called, COMP_WORDS has already been populated so local
# changes to COMP_WORDBREAKS have no effect.
#
# Output: words_, cword_, cur_.

__git_reassemble_comp_words_by_ref()
{
	local exclude i j first
	# Which word separators to exclude?
	exclude="${1//[^$COMP_WORDBREAKS]}"
	cword_=$COMP_CWORD
	if [ -z "$exclude" ]; then
		words_=("${COMP_WORDS[@]}")
		return
	fi
	# List of word completion separators has shrunk;
	# re-assemble words to complete.
	for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++)); do
		# Append each nonempty word consisting of just
		# word separator characters to the current word.
		first=t
		while
			[ $i -gt 0 ] &&
			[ -n "${COMP_WORDS[$i]}" ] &&
			# word consists of excluded word separators
			[ "${COMP_WORDS[$i]//[^$exclude]}" = "${COMP_WORDS[$i]}" ]
		do
			# Attach to the previous token,
			# unless the previous token is the command name.
			if [ $j -ge 2 ] && [ -n "$first" ]; then
				((j--))
			fi
			first=
			words_[$j]=${words_[j]}${COMP_WORDS[i]}
			if [ $i = $COMP_CWORD ]; then
				cword_=$j
			fi
			if (($i < ${#COMP_WORDS[@]} - 1)); then
				((i++))
			else
				# Done.
				return
			fi
		done
		words_[$j]=${words_[j]}${COMP_WORDS[i]}
		if [ $i = $COMP_CWORD ]; then
			cword_=$j
		fi
	done
}

if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
_get_comp_words_by_ref ()
{
	local exclude cur_ words_ cword_
	if [ "$1" = "-n" ]; then
		exclude=$2
		shift 2
	fi
	__git_reassemble_comp_words_by_ref "$exclude"
	cur_=${words_[cword_]}
	while [ $# -gt 0 ]; do
		case "$1" in
		cur)
			cur=$cur_
			;;
		prev)
			prev=${words_[$cword_-1]}
			;;
		words)
			words=("${words_[@]}")
			;;
		cword)
			cword=$cword_
			;;
		esac
		shift
	done
}
fi

__gitcompappend ()
{
	local i=${#COMPREPLY[@]}
	for x in $1; do
		if [[ "$x" == "$3"* ]]; then
			COMPREPLY[i++]="$2$x$4"
		fi
	done
}

__gitcompadd ()
{
	COMPREPLY=()
	__gitcompappend "$@"
}

# Generates completion reply, appending a space to possible completion words,
# if necessary.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word (optional).
__gitcomp ()
{
	local cur_="${3-$cur}"

	case "$cur_" in
	--*=)
		;;
	*)
		local c i=0 IFS=$' \t\n'
		for c in $1; do
			c="$c${4-}"
			if [[ $c == "$cur_"* ]]; then
				case $c in
				--*=*|*.) ;;
				*) c="$c " ;;
				esac
				COMPREPLY[i++]="${2-}$c"
			fi
		done
		;;
	esac
}

# Variation of __gitcomp_nl () that appends to the existing list of
# completion candidates, COMPREPLY.
__gitcomp_nl_append ()
{
	local IFS=$'\n'
	__gitcompappend "$1" "${2-}" "${3-$cur}" "${4- }"
}

# Generates completion reply from newline-separated possible completion words
# by appending a space to all of them.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words, separated by a single newline.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word instead of
#    the default space (optional).  If specified but empty, nothing is
#    appended.
__gitcomp_nl ()
{
	COMPREPLY=()
	__gitcomp_nl_append "$@"
}

# Generates completion reply with compgen from newline-separated possible
# completion filenames.
# It accepts 1 to 3 arguments:
# 1: List of possible completion filenames, separated by a single newline.
# 2: A directory prefix to be added to each possible completion filename
#    (optional).
# 3: Generate possible completion matches for this word (optional).
__gitcomp_file ()
{
	local IFS=$'\n'

	# XXX does not work when the directory prefix contains a tilde,
	# since tilde expansion is not applied.
	# This means that COMPREPLY will be empty and Bash default
	# completion will be used.
	__gitcompadd "$1" "${2-}" "${3-$cur}" ""

	# use a hack to enable file mode in bash < 4
	compopt -o filenames +o nospace 2>/dev/null ||
	compgen -f /non-existing-dir/ > /dev/null
}

# Execute 'git ls-files', unless the --committable option is specified, in
# which case it runs 'git diff-index' to find out the files that can be
# committed.  It return paths relative to the directory specified in the first
# argument, and using the options specified in the second argument.
__git_ls_files_helper ()
{
	(
		test -n "${CDPATH+set}" && unset CDPATH
		cd "$1"
		if [ "$2" == "--committable" ]; then
			git diff-index --name-only --relative HEAD
		else
			# NOTE: $2 is not quoted in order to support multiple options
			git ls-files --exclude-standard $2
		fi
	) 2>/dev/null
}


# __git_index_files accepts 1 or 2 arguments:
# 1: Options to pass to ls-files (required).
# 2: A directory path (optional).
#    If provided, only files within the specified directory are listed.
#    Sub directories are never recursed.  Path must have a trailing
#    slash.
__git_index_files ()
{
	local dir="$(__gitdir)" root="${2-.}" file

	if [ -d "$dir" ]; then
		__git_ls_files_helper "$root" "$1" |
		while read -r file; do
			case "$file" in
			?*/*) echo "${file%%/*}" ;;
			*) echo "$file" ;;
			esac
		done | sort | uniq
	fi
}

__git_heads ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir" ]; then
		git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
			refs/heads
		return
	fi
}

__git_tags ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir" ]; then
		git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
			refs/tags
		return
	fi
}

# __git_refs accepts 0, 1 (to pass to __gitdir), or 2 arguments
# presence of 2nd argument means use the guess heuristic employed
# by checkout for tracking branches
__git_refs ()
{
	local i hash dir="$(__gitdir "${1-}")" track="${2-}"
	local format refs
	if [ -d "$dir" ]; then
		case "$cur" in
		refs|refs/*)
			format="refname"
			refs="${cur%/*}"
			track=""
			;;
		*)
			for i in HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD; do
				if [ -e "$dir/$i" ]; then echo $i; fi
			done
			format="refname:short"
			refs="refs/tags refs/heads refs/remotes"
			;;
		esac
		git --git-dir="$dir" for-each-ref --format="%($format)" \
			$refs
		if [ -n "$track" ]; then
			# employ the heuristic used by git checkout
			# Try to find a remote branch that matches the completion word
			# but only output if the branch name is unique
			local ref entry
			git --git-dir="$dir" for-each-ref --shell --format="ref=%(refname:short)" \
				"refs/remotes/" | \
			while read -r entry; do
				eval "$entry"
				ref="${ref#*/}"
				if [[ "$ref" == "$cur"* ]]; then
					echo "$ref"
				fi
			done | sort | uniq -u
		fi
		return
	fi
	case "$cur" in
	refs|refs/*)
		git ls-remote "$dir" "$cur*" 2>/dev/null | \
		while read -r hash i; do
			case "$i" in
			*^{}) ;;
			*) echo "$i" ;;
			esac
		done
		;;
	*)
		echo "HEAD"
		git for-each-ref --format="%(refname:short)" -- "refs/remotes/$dir/" | sed -e "s#^$dir/##"
		;;
	esac
}

# __git_refs2 requires 1 argument (to pass to __git_refs)
__git_refs2 ()
{
	local i
	for i in $(__git_refs "$1"); do
		echo "$i:$i"
	done
}

# __git_refs_remotes requires 1 argument (to pass to ls-remote)
__git_refs_remotes ()
{
	local i hash
	git ls-remote "$1" 'refs/heads/*' 2>/dev/null | \
	while read -r hash i; do
		echo "$i:refs/remotes/$1/${i#refs/heads/}"
	done
}

__git_remotes ()
{
	local i IFS=$'\n' d="$(__gitdir)"
	test -d "$d/remotes" && ls -1 "$d/remotes"
	for i in $(git --git-dir="$d" config --get-regexp 'remote\..*\.url' 2>/dev/null); do
		i="${i#remote.}"
		echo "${i/.url*/}"
	done
}

__git_list_merge_strategies ()
{
	git merge -s help 2>&1 |
	sed -n -e '/[Aa]vailable strategies are: /,/^$/{
		s/\.$//
		s/.*://
		s/^[ 	]*//
		s/[ 	]*$//
		p
	}'
}

__git_merge_strategies=
# 'git merge -s help' (and thus detection of the merge strategy
# list) fails, unfortunately, if run outside of any git working
# tree.  __git_merge_strategies is set to the empty string in
# that case, and the detection will be repeated the next time it
# is needed.
__git_compute_merge_strategies ()
{
	test -n "$__git_merge_strategies" ||
	__git_merge_strategies=$(__git_list_merge_strategies)
}

__git_complete_revlist_file ()
{
	local pfx ls ref cur_="$cur"
	case "$cur_" in
	*..?*:*)
		return
		;;
	?*:*)
		ref="${cur_%%:*}"
		cur_="${cur_#*:}"
		case "$cur_" in
		?*/*)
			pfx="${cur_%/*}"
			cur_="${cur_##*/}"
			ls="$ref:$pfx"
			pfx="$pfx/"
			;;
		*)
			ls="$ref"
			;;
		esac

		case "$COMP_WORDBREAKS" in
		*:*) : great ;;
		*)   pfx="$ref:$pfx" ;;
		esac

		__gitcomp_nl "$(git --git-dir="$(__gitdir)" ls-tree "$ls" 2>/dev/null \
				| sed '/^100... blob /{
				           s,^.*	,,
				           s,$, ,
				       }
				       /^120000 blob /{
				           s,^.*	,,
				           s,$, ,
				       }
				       /^040000 tree /{
				           s,^.*	,,
				           s,$,/,
				       }
				       s/^.*	//')" \
			"$pfx" "$cur_" ""
		;;
	*...*)
		pfx="${cur_%...*}..."
		cur_="${cur_#*...}"
		__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		;;
	*..*)
		pfx="${cur_%..*}.."
		cur_="${cur_#*..}"
		__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		;;
	*)
		__gitcomp_nl "$(__git_refs)"
		;;
	esac
}


# __git_complete_index_file requires 1 argument:
# 1: the options to pass to ls-file
#
# The exception is --committable, which finds the files appropriate commit.
__git_complete_index_file ()
{
	local pfx="" cur_="$cur"

	case "$cur_" in
	?*/*)
		pfx="${cur_%/*}"
		cur_="${cur_##*/}"
		pfx="${pfx}/"
		;;
	esac

	__gitcomp_file "$(__git_index_files "$1" "$pfx")" "$pfx" "$cur_"
}

__git_complete_file ()
{
	__git_complete_revlist_file
}

__git_complete_revlist ()
{
	__git_complete_revlist_file
}

__git_complete_remote_or_refspec ()
{
	local cur_="$cur" cmd="${words[1]}"
	local i c=2 remote="" pfx="" lhs=1 no_complete_refspec=0
	if [ "$cmd" = "remote" ]; then
		((c++))
	fi
	while [ $c -lt $cword ]; do
		i="${words[c]}"
		case "$i" in
		--mirror) [ "$cmd" = "push" ] && no_complete_refspec=1 ;;
		--all)
			case "$cmd" in
			push) no_complete_refspec=1 ;;
			fetch)
				return
				;;
			*) ;;
			esac
			;;
		-*) ;;
		*) remote="$i"; break ;;
		esac
		((c++))
	done
	if [ -z "$remote" ]; then
		__gitcomp_nl "$(__git_remotes)"
		return
	fi
	if [ $no_complete_refspec = 1 ]; then
		return
	fi
	[ "$remote" = "." ] && remote=
	case "$cur_" in
	*:*)
		case "$COMP_WORDBREAKS" in
		*:*) : great ;;
		*)   pfx="${cur_%%:*}:" ;;
		esac
		cur_="${cur_#*:}"
		lhs=0
		;;
	+*)
		pfx="+"
		cur_="${cur_#+}"
		;;
	esac
	case "$cmd" in
	fetch)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs2 "$remote")" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		fi
		;;
	pull|remote)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		fi
		;;
	push)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
		fi
		;;
	esac
}

__git_complete_strategy ()
{
	__git_compute_merge_strategies
	case "$prev" in
	-s|--strategy)
		__gitcomp "$__git_merge_strategies"
		return 0
	esac
	case "$cur" in
	--strategy=*)
		__gitcomp "$__git_merge_strategies" "" "${cur##--strategy=}"
		return 0
		;;
	esac
	return 1
}

__git_commands () {
	if test -n "${GIT_TESTING_COMMAND_COMPLETION:-}"
	then
		printf "%s" "${GIT_TESTING_COMMAND_COMPLETION}"
	else
		git help -a|egrep '^  [a-zA-Z0-9]'
	fi
}

__git_list_all_commands ()
{
	local i IFS=" "$'\n'
	for i in $(__git_commands)
	do
		case $i in
		*--*)             : helper pattern;;
		*) echo $i;;
		esac
	done
}

__git_all_commands=
__git_compute_all_commands ()
{
	test -n "$__git_all_commands" ||
	__git_all_commands=$(__git_list_all_commands)
}

__git_list_porcelain_commands ()
{
	local i IFS=" "$'\n'
	__git_compute_all_commands
	for i in $__git_all_commands
	do
		case $i in
		*--*)             : helper pattern;;
		applymbox)        : ask gittus;;
		applypatch)       : ask gittus;;
		archimport)       : import;;
		cat-file)         : plumbing;;
		check-attr)       : plumbing;;
		check-ignore)     : plumbing;;
		check-mailmap)    : plumbing;;
		check-ref-format) : plumbing;;
		checkout-index)   : plumbing;;
		commit-tree)      : plumbing;;
		count-objects)    : infrequent;;
		credential-cache) : credentials helper;;
		credential-store) : credentials helper;;
		cvsexportcommit)  : export;;
		cvsimport)        : import;;
		cvsserver)        : daemon;;
		daemon)           : daemon;;
		diff-files)       : plumbing;;
		diff-index)       : plumbing;;
		diff-tree)        : plumbing;;
		fast-import)      : import;;
		fast-export)      : export;;
		fsck-objects)     : plumbing;;
		fetch-pack)       : plumbing;;
		fmt-merge-msg)    : plumbing;;
		for-each-ref)     : plumbing;;
		hash-object)      : plumbing;;
		http-*)           : transport;;
		index-pack)       : plumbing;;
		init-db)          : deprecated;;
		local-fetch)      : plumbing;;
		ls-files)         : plumbing;;
		ls-remote)        : plumbing;;
		ls-tree)          : plumbing;;
		mailinfo)         : plumbing;;
		mailsplit)        : plumbing;;
		merge-*)          : plumbing;;
		mktree)           : plumbing;;
		mktag)            : plumbing;;
		pack-objects)     : plumbing;;
		pack-redundant)   : plumbing;;
		pack-refs)        : plumbing;;
		parse-remote)     : plumbing;;
		patch-id)         : plumbing;;
		prune)            : plumbing;;
		prune-packed)     : plumbing;;
		quiltimport)      : import;;
		read-tree)        : plumbing;;
		receive-pack)     : plumbing;;
		remote-*)         : transport;;
		rerere)           : plumbing;;
		rev-list)         : plumbing;;
		rev-parse)        : plumbing;;
		runstatus)        : plumbing;;
		sh-setup)         : internal;;
		shell)            : daemon;;
		show-ref)         : plumbing;;
		send-pack)        : plumbing;;
		show-index)       : plumbing;;
		ssh-*)            : transport;;
		stripspace)       : plumbing;;
		symbolic-ref)     : plumbing;;
		unpack-file)      : plumbing;;
		unpack-objects)   : plumbing;;
		update-index)     : plumbing;;
		update-ref)       : plumbing;;
		update-server-info) : daemon;;
		upload-archive)   : plumbing;;
		upload-pack)      : plumbing;;
		write-tree)       : plumbing;;
		var)              : infrequent;;
		verify-pack)      : infrequent;;
		verify-tag)       : plumbing;;
		*) echo $i;;
		esac
	done
}

__git_porcelain_commands=
__git_compute_porcelain_commands ()
{
	__git_compute_all_commands
	test -n "$__git_porcelain_commands" ||
	__git_porcelain_commands=$(__git_list_porcelain_commands)
}

__git_pretty_aliases ()
{
	local i IFS=$'\n'
	for i in $(git --git-dir="$(__gitdir)" config --get-regexp "pretty\..*" 2>/dev/null); do
		case "$i" in
		pretty.*)
			i="${i#pretty.}"
			echo "${i/ */}"
			;;
		esac
	done
}

__git_aliases ()
{
	local i IFS=$'\n'
	for i in $(git --git-dir="$(__gitdir)" config --get-regexp "alias\..*" 2>/dev/null); do
		case "$i" in
		alias.*)
			i="${i#alias.}"
			echo "${i/ */}"
			;;
		esac
	done
}

# __git_aliased_command requires 1 argument
__git_aliased_command ()
{
	local word cmdline=$(git --git-dir="$(__gitdir)" \
		config --get "alias.$1")
	for word in $cmdline; do
		case "$word" in
		\!gitk|gitk)
			echo "gitk"
			return
			;;
		\!*)	: shell command alias ;;
		-*)	: option ;;
		*=*)	: setting env ;;
		git)	: git itself ;;
		*)
			echo "$word"
			return
		esac
	done
}

# __git_find_on_cmdline requires 1 argument
__git_find_on_cmdline ()
{
	local word subcommand c=1
	while [ $c -lt $cword ]; do
		word="${words[c]}"
		for subcommand in $1; do
			if [ "$subcommand" = "$word" ]; then
				echo "$subcommand"
				return
			fi
		done
		((c++))
	done
}

__git_has_doubledash ()
{
	local c=1
	while [ $c -lt $cword ]; do
		if [ "--" = "${words[c]}" ]; then
			return 0
		fi
		((c++))
	done
	return 1
}

# Try to count non option arguments passed on the command line for the
# specified git command.
# When options are used, it is necessary to use the special -- option to
# tell the implementation were non option arguments begin.
# XXX this can not be improved, since options can appear everywhere, as
# an example:
#	git mv x -n y
#
# __git_count_arguments requires 1 argument: the git command executed.
__git_count_arguments ()
{
	local word i c=0

	# Skip "git" (first argument)
	for ((i=1; i < ${#words[@]}; i++)); do
		word="${words[i]}"

		case "$word" in
			--)
				# Good; we can assume that the following are only non
				# option arguments.
				((c = 0))
				;;
			"$1")
				# Skip the specified git command and discard git
				# main options
				((c = 0))
				;;
			?*)
				((c++))
				;;
		esac
	done

	printf "%d" $c
}

__git_whitespacelist="nowarn warn error error-all fix"

_git_am ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir"/rebase-apply ]; then
		__gitcomp "--skip --continue --resolved --abort"
		return
	fi
	case "$cur" in
	--whitespace=*)
		__gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
		return
		;;
	--*)
		__gitcomp "
			--3way --committer-date-is-author-date --ignore-date
			--ignore-whitespace --ignore-space-change
			--interactive --keep --no-utf8 --signoff --utf8
			--whitespace= --scissors
			"
		return
	esac
}

_git_apply ()
{
	case "$cur" in
	--whitespace=*)
		__gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
		return
		;;
	--*)
		__gitcomp "
			--stat --numstat --summary --check --index
			--cached --index-info --reverse --reject --unidiff-zero
			--apply --no-add --exclude=
			--ignore-whitespace --ignore-space-change
			--whitespace= --inaccurate-eof --verbose
			"
		return
	esac
}

_git_add ()
{
	case "$cur" in
	--*)
		__gitcomp "
			--interactive --refresh --patch --update --dry-run
			--ignore-errors --intent-to-add
			"
		return
	esac

	# XXX should we check for --update and --all options ?
	__git_complete_index_file "--others --modified --directory --no-empty-directory"
}

_git_archive ()
{
	case "$cur" in
	--format=*)
		__gitcomp "$(git archive --list)" "" "${cur##--format=}"
		return
		;;
	--remote=*)
		__gitcomp_nl "$(__git_remotes)" "" "${cur##--remote=}"
		return
		;;
	--*)
		__gitcomp "
			--format= --list --verbose
			--prefix= --remote= --exec=
			"
		return
		;;
	esac
	__git_complete_file
}

_git_bisect ()
{
	__git_has_doubledash && return

	local subcommands="start bad good skip reset visualize replay log run"
	local subcommand="$(__git_find_on_cmdline "$subcommands")"
	if [ -z "$subcommand" ]; then
		if [ -f "$(__gitdir)"/BISECT_START ]; then
			__gitcomp "$subcommands"
		else
			__gitcomp "replay start"
		fi
		return
	fi

	case "$subcommand" in
	bad|good|reset|skip|start)
		__gitcomp_nl "$(__git_refs)"
		;;
	*)
		;;
	esac
}

_git_branch ()
{
	local i c=1 only_local_ref="n" has_r="n"

	while [ $c -lt $cword ]; do
		i="${words[c]}"
		case "$i" in
		-d|-m)	only_local_ref="y" ;;
		-r)	has_r="y" ;;
		esac
		((c++))
	done

	case "$cur" in
	--set-upstream-to=*)
		__gitcomp "$(__git_refs)" "" "${cur##--set-upstream-to=}"
		;;
	--*)
		__gitcomp "
			--color --no-color --verbose --abbrev= --no-abbrev
			--track --no-track --contains --merged --no-merged
			--set-upstream-to= --edit-description --list
			--unset-upstream
			"
		;;
	*)
		if [ $only_local_ref = "y" -a $has_r = "n" ]; then
			__gitcomp_nl "$(__git_heads)"
		else
			__gitcomp_nl "$(__git_refs)"
		fi
		;;
	esac
}

_git_bundle ()
{
	local cmd="${words[2]}"
	case "$cword" in
	2)
		__gitcomp "create list-heads verify unbundle"
		;;
	3)
		# looking for a file
		;;
	*)
		case "$cmd" in
			create)
				__git_complete_revlist
			;;
		esac
		;;
	esac
}

_git_checkout ()
{
	__git_has_doubledash && return

	case "$cur" in
	--conflict=*)
		__gitcomp "diff3 merge" "" "${cur##--conflict=}"
		;;
	--*)
		__gitcomp "
			--quiet --ours --theirs --track --no-track --merge
			--conflict= --orphan --patch
			"
		;;
	*)
		# check if --track, --no-track, or --no-guess was specified
		# if so, disable DWIM mode
		local flags="--track --no-track --no-guess" track=1
		if [ -n "$(__git_find_on_cmdline "$flags")" ]; then
			track=''
		fi
		__gitcomp_nl "$(__git_refs '' $track)"
		;;
	esac
}

_git_cherry ()
{
	__gitcomp "$(__git_refs)"
}

_git_cherry_pick ()
{
	local dir="$(__gitdir)"
	if [ -f "$dir"/CHERRY_PICK_HEAD ]; then
		__gitcomp "--continue --quit --abort"
		return
	fi
	case "$cur" in
	--*)
		__gitcomp "--edit --no-commit --signoff --strategy= --mainline"
		;;
	*)
		__gitcomp_nl "$(__git_refs)"
		;;
	esac
}

_git_clean ()
{
	case "$cur" in
	--*)
		__gitcomp "--dry-run --quiet"
		return
		;;
	esac

	# XXX should we check for -x option ?
	__git_complete_index_file "--others --directory"
}

_git_clone ()
{
	case "$cur" in
	--*)
		__gitcomp "
			--local
			--no-hardlinks
			--shared
			--reference
			--quiet
			--no-checkout
			--bare
			--mirror
			--origin
			--upload-pack
			--template=
			--depth
			--single-branch
			--branch
			"
		return
		;;
	esac
}

_git_commit ()
{
	case "$prev" in
	-c|-C)
		__gitcomp_nl "$(__git_refs)" "" "${cur}"
		return
		;;
	esac

	case "$cur" in
	--cleanup=*)
		__gitcomp "default strip verbatim whitespace
			" "" "${cur##--cleanup=}"
		return
		;;
	--reuse-message=*|--reedit-message=*|\
	--fixup=*|--squash=*)
		__gitcomp_nl "$(__git_refs)" "" "${cur#*=}"
		return
		;;
	--untracked-files=*)
		__gitcomp "all no normal" "" "${cur##--untracked-files=}"
		return
		;;
	--*)
		__gitcomp "
			--all --author= --signoff --verify --no-verify
			--edit --no-edit
			--amend --include --only --interactive
			--dry-run --reuse-message= --reedit-message=
			--reset-author --file= --message= --template=
			--cleanup= --untracked-files --untracked-files=
			--verbose --quiet --fixup= --squash=
			"
		return
	esac

	if git rev-parse --verify --quiet HEAD >/dev/null; then
		__git_complete_index_file "--committable"
	else
		# This is the first commit
		__git_complete_index_file "--cached"
	fi
}

_git_describe ()
{
	case "$cur" in
	--*)
		__gitcomp "
			--all --tags --contains --abbrev= --candidates=
			--exact-match --debug --long --match --always
			"
		return
	esac
	__gitcomp_nl "$(__git_refs)"
}

__git_diff_algorithms="myers minimal patience histogram"

__git_diff_common_options="--stat --numstat --shortstat --summary
			--patch-with-stat --name-only --name-status --color
			--no-color --color-words --no-renames --check
			--full-index --binary --abbrev --diff-filter=
			--find-copies-harder
			--text --ignore-space-at-eol --ignore-space-change
			--ignore-all-space --exit-code --quiet --ext-diff
			--no-ext-diff
			--no-prefix --src-prefix= --dst-prefix=
			--inter-hunk-context=
			--patience --histogram --minimal
			--raw --word-diff
			--dirstat --dirstat= --dirstat-by-file
			--dirstat-by-file= --cumulative
			--diff-algorithm=
"

_git_diff ()
{
	__git_has_doubledash && return

	case "$cur" in
	--diff-algorithm=*)
		__gitcomp "$__git_diff_algorithms" "" "${cur##--diff-algorithm=}"
		return
		;;
	--*)
		__gitcomp "--cached --staged --pickaxe-all --pickaxe-regex
			--base --ours --theirs --no-index
			$__git_diff_common_options
			"
		return
		;;
	esac
	__git_complete_revlist_file
}

__git_mergetools_common="diffuse diffmerge ecmerge emerge kdiff3 meld opendiff
			tkdiff vimdiff gvimdiff xxdiff araxis p4merge bc3 codecompare
"

_git_difftool ()
{
	__git_has_doubledash && return

	case "$cur" in
	--tool=*)
		__gitcomp "$__git_mergetools_common kompare" "" "${cur##--tool=}"
		return
		;;
	--*)
		__gitcomp "--cached --staged --pickaxe-all --pickaxe-regex
			--base --ours --theirs
			--no-renames --diff-filter= --find-copies-harder
			--relative --ignore-submodules
			--tool="
		return
		;;
	esac
	__git_complete_revlist_file
}

__git_fetch_options="
	--quiet --verbose --append --upload-pack --force --keep --depth=
	--tags --no-tags --all --prune --dry-run
"

_git_fetch ()
{
	case "$cur" in
	--*)
		__gitcomp "$__git_fetch_options"
		return
		;;
	esac
	__git_complete_remote_or_refspec
}

__git_format_patch_options="
	--stdout --attach --no-attach --thread --thread= --no-thread
	--numbered --start-number --numbered-files --keep-subject --signoff
	--signature --no-signature --in-reply-to= --cc= --full-index --binary
	--not --all --cover-letter --no-prefix --src-prefix= --dst-prefix=
	--inline --suffix= --ignore-if-in-upstream --subject-prefix=
	--output-directory --reroll-count --to= --quiet --notes
"

_git_format_patch ()
{
	case "$cur" in
	--thread=*)
		__gitcomp "
			deep shallow
			" "" "${cur##--thread=}"
		return
		;;
	--*)
		__gitcomp "$__git_format_patch_options"
		return
		;;
	esac
	__git_complete_revlist
}

_git_fsck ()
{
	case "$cur" in
	--*)
		__gitcomp "
			--tags --root --unreachable --cache --no-reflogs --full
			--strict --verbose --lost-found
			"
		return
		;;
	esac
}

_git_gc ()
{
	case "$cur" in
	--*)
		__gitcomp "--prune --aggressive"
		return
		;;
	esac
}

_git_gitk ()
{
	_gitk
}

__git_match_ctag() {
	awk "/^${1////\\/}/ { print \$1 }" "$2"
}

_git_grep ()
{
	__git_has_doubledash && return

	case "$cur" in
	--*)
		__gitcomp "
			--cached
			--text --ignore-case --word-regexp --invert-match
			--full-name --line-number
			--extended-regexp --basic-regexp --fixed-strings
			--perl-regexp
			--files-with-matches --name-only
			--files-without-match
			--max-depth
			--count
			--and --or --not --all-match
			"
		return
		;;
	esac

	case "$cword,$prev" in
	2,*|*,-*)
		if test -r tags; then
			__gitcomp_nl "$(__git_match_ctag "$cur" tags)"
			return
		fi
		;;
	esac

	__gitcomp_nl "$(__git_refs)"
}

_git_help ()
{
	case "$cur" in
	--*)
		__gitcomp "--all --info --man --web"
		return
		;;
	esac
	__git_compute_all_commands
	__gitcomp "$__git_all_commands $(__git_aliases)
		attributes cli core-tutorial cvs-migration
		diffcore gitk glossary hooks ignore modules
		namespaces repository-layout tutorial tutorial-2
		workflows
		"
}

_git_init ()
{
	case "$cur" in
	--shared=*)
		__gitcomp "
			false true umask group all world everybody
			" "" "${cur##--shared=}"
		return
		;;
	--*)
		__gitcomp "--quiet --bare --template= --shared --shared="
		return
		;;
	esac
}

_git_ls_files ()
{
	case "$cur" in
	--*)
		__gitcomp "--cached --deleted --modified --others --ignored
			--stage --directory --no-empty-directory --unmerged
			--killed --exclude= --exclude-from=
			--exclude-per-directory= --exclude-standard
			--error-unmatch --with-tree= --full-name
			--abbrev --ignored --exclude-per-directory
			"
		return
		;;
	esac

	# XXX ignore options like --modified and always suggest all cached
	# files.
	__git_complete_index_file "--cached"
}

_git_ls_remote ()
{
	__gitcomp_nl "$(__git_remotes)"
}

_git_ls_tree ()
{
	__git_complete_file
}

# Options that go well for log, shortlog and gitk
__git_log_common_options="
	--not --all
	--branches --tags --remotes
	--first-parent --merges --no-merges
	--max-count=
	--max-age= --since= --after=
	--min-age= --until= --before=
	--min-parents= --max-parents=
	--no-min-parents --no-max-parents
"
# Options that go well for log and gitk (not shortlog)
__git_log_gitk_options="
	--dense --sparse --full-history
	--simplify-merges --simplify-by-decoration
	--left-right --notes --no-notes
"
# Options that go well for log and shortlog (not gitk)
__git_log_shortlog_options="
	--author= --committer= --grep=
	--all-match
"

__git_log_pretty_formats="oneline short medium full fuller email raw format:"
__git_log_date_formats="relative iso8601 rfc2822 short local default raw"

_git_log ()
{
	__git_has_doubledash && return

	local g="$(git rev-parse --git-dir 2>/dev/null)"
	local merge=""
	if [ -f "$g/MERGE_HEAD" ]; then
		merge="--merge"
	fi
	case "$cur" in
	--pretty=*|--format=*)
		__gitcomp "$__git_log_pretty_formats $(__git_pretty_aliases)
			" "" "${cur#*=}"
		return
		;;
	--date=*)
		__gitcomp "$__git_log_date_formats" "" "${cur##--date=}"
		return
		;;
	--decorate=*)
		__gitcomp "long short" "" "${cur##--decorate=}"
		return
		;;
	--*)
		__gitcomp "
			$__git_log_common_options
			$__git_log_shortlog_options
			$__git_log_gitk_options
			--root --topo-order --date-order --reverse
			--follow --full-diff
			--abbrev-commit --abbrev=
			--relative-date --date=
			--pretty= --format= --oneline
			--cherry-pick
			--graph
			--decorate --decorate=
			--walk-reflogs
			--parents --children
			$merge
			$__git_diff_common_options
			--pickaxe-all --pickaxe-regex
			"
		return
		;;
	esac
	__git_complete_revlist
}

__git_merge_options="
	--no-commit --no-stat --log --no-log --squash --strategy
	--commit --stat --no-squash --ff --no-ff --ff-only --edit --no-edit
"

_git_merge ()
{
	__git_complete_strategy && return

	case "$cur" in
	--*)
		__gitcomp "$__git_merge_options"
		return
	esac
	__gitcomp_nl "$(__git_refs)"
}

_git_mergetool ()
{
	case "$cur" in
	--tool=*)
		__gitcomp "$__git_mergetools_common tortoisemerge" "" "${cur##--tool=}"
		return
		;;
	--*)
		__gitcomp "--tool="
		return
		;;
	esac
}

_git_merge_base ()
{
	__gitcomp_nl "$(__git_refs)"
}

_git_mv ()
{
	case "$cur" in
	--*)
		__gitcomp "--dry-run"
		return
		;;
	esac

	if [ $(__git_count_arguments "mv") -gt 0 ]; then
		# We need to show both cached and untracked files (including
		# empty directories) since this may not be the last argument.
		__git_complete_index_file "--cached --others --directory"
	else
		__git_complete_index_file "--cached"
	fi
}

_git_name_rev ()
{
	__gitcomp "--tags --all --stdin"
}

_git_notes ()
{
	local subcommands='add append copy edit list prune remove show'
	local subcommand="$(__git_find_on_cmdline "$subcommands")"

	case "$subcommand,$cur" in
	,--*)
		__gitcomp '--ref'
		;;
	,*)
		case "$prev" in
		--ref)
			__gitcomp_nl "$(__git_refs)"
			;;
		*)
			__gitcomp "$subcommands --ref"
			;;
		esac
		;;
	add,--reuse-message=*|append,--reuse-message=*|\
	add,--reedit-message=*|append,--reedit-message=*)
		__gitcomp_nl "$(__git_refs)" "" "${cur#*=}"
		;;
	add,--*|append,--*)
		__gitcomp '--file= --message= --reedit-message=
				--reuse-message='
		;;
	copy,--*)
		__gitcomp '--stdin'
		;;
	prune,--*)
		__gitcomp '--dry-run --verbose'
		;;
	prune,*)
		;;
	*)
		case "$prev" in
		-m|-F)
			;;
		*)
			__gitcomp_nl "$(__git_refs)"
			;;
		esac
		;;
	esac
}

_git_pull ()
{
	__git_complete_strategy && return

	case "$cur" in
	--*)
		__gitcomp "
			--rebase --no-rebase
			$__git_merge_options
			$__git_fetch_options
		"
		return
		;;
	esac
	__git_complete_remote_or_refspec
}

_git_push ()
{
	case "$prev" in
	--repo)
		__gitcomp_nl "$(__git_remotes)"
		return
	esac
	case "$cur" in
	--repo=*)
		__gitcomp_nl "$(__git_remotes)" "" "${cur##--repo=}"
		return
		;;
	--*)
		__gitcomp "
			--all --mirror --tags --dry-run --force --verbose
			--receive-pack= --repo= --set-upstream
		"
		return
		;;
	esac
	__git_complete_remote_or_refspec
}

_git_rebase ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir"/rebase-apply ] || [ -d "$dir"/rebase-merge ]; then
		__gitcomp "--continue --skip --abort"
		return
	fi
	__git_complete_strategy && return
	case "$cur" in
	--whitespace=*)
		__gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
		return
		;;
	--*)
		__gitcomp "
			--onto --merge --strategy --interactive
			--preserve-merges --stat --no-stat
			--committer-date-is-author-date --ignore-date
			--ignore-whitespace --whitespace=
			--autosquash
			"

		return
	esac
	__gitcomp_nl "$(__git_refs)"
}

_git_reflog ()
{
	local subcommands="show delete expire"
	local subcommand="$(__git_find_on_cmdline "$subcommands")"

	if [ -z "$subcommand" ]; then
		__gitcomp "$subcommands"
	else
		__gitcomp_nl "$(__git_refs)"
	fi
}

__git_send_email_confirm_options="always never auto cc compose"
__git_send_email_suppresscc_options="author self cc bodycc sob cccmd body all"

_git_send_email ()
{
	case "$cur" in
	--confirm=*)
		__gitcomp "
			$__git_send_email_confirm_options
			" "" "${cur##--confirm=}"
		return
		;;
	--suppress-cc=*)
		__gitcomp "
			$__git_send_email_suppresscc_options
			" "" "${cur##--suppress-cc=}"

		return
		;;
	--smtp-encryption=*)
		__gitcomp "ssl tls" "" "${cur##--smtp-encryption=}"
		return
		;;
	--thread=*)
		__gitcomp "
			deep shallow
			" "" "${cur##--thread=}"
		return
		;;
	--*)
		__gitcomp "--annotate --bcc --cc --cc-cmd --chain-reply-to
			--compose --confirm= --dry-run --envelope-sender
			--from --identity
			--in-reply-to --no-chain-reply-to --no-signed-off-by-cc
			--no-suppress-from --no-thread --quiet
			--signed-off-by-cc --smtp-pass --smtp-server
			--smtp-server-port --smtp-encryption= --smtp-user
			--subject --suppress-cc= --suppress-from --thread --to
			--validate --no-validate
			$__git_format_patch_options"
		return
		;;
	esac
	__git_complete_revlist
}

_git_stage ()
{
	_git_add
}

__git_config_get_set_variables ()
{
	local prevword word config_file= c=$cword
	while [ $c -gt 1 ]; do
		word="${words[c]}"
		case "$word" in
		--system|--global|--local|--file=*)
			config_file="$word"
			break
			;;
		-f|--file)
			config_file="$word $prevword"
			break
			;;
		esac
		prevword=$word
		c=$((--c))
	done

	git --git-dir="$(__gitdir)" config $config_file --list 2>/dev/null |
	while read -r line
	do
		case "$line" in
		*.*=*)
			echo "${line/=*/}"
			;;
		esac
	done
}

_git_config ()
{
	case "$prev" in
	branch.*.remote|branch.*.pushremote)
		__gitcomp_nl "$(__git_remotes)"
		return
		;;
	branch.*.merge)
		__gitcomp_nl "$(__git_refs)"
		return
		;;
	branch.*.rebase)
		__gitcomp "false true"
		return
		;;
	remote.pushdefault)
		__gitcomp_nl "$(__git_remotes)"
		return
		;;
	remote.*.fetch)
		local remote="${prev#remote.}"
		remote="${remote%.fetch}"
		if [ -z "$cur" ]; then
			__gitcomp_nl "refs/heads/" "" "" ""
			return
		fi
		__gitcomp_nl "$(__git_refs_remotes "$remote")"
		return
		;;
	remote.*.push)
		local remote="${prev#remote.}"
		remote="${remote%.push}"
		__gitcomp_nl "$(git --git-dir="$(__gitdir)" \
			for-each-ref --format='%(refname):%(refname)' \
			refs/heads)"
		return
		;;
	pull.twohead|pull.octopus)
		__git_compute_merge_strategies
		__gitcomp "$__git_merge_strategies"
		return
		;;
	color.branch|color.diff|color.interactive|\
	color.showbranch|color.status|color.ui)
		__gitcomp "always never auto"
		return
		;;
	color.pager)
		__gitcomp "false true"
		return
		;;
	color.*.*)
		__gitcomp "
			normal black red green yellow blue magenta cyan white
			bold dim ul blink reverse
			"
		return
		;;
	diff.submodule)
		__gitcomp "log short"
		return
		;;
	help.format)
		__gitcomp "man info web html"
		return
		;;
	log.date)
		__gitcomp "$__git_log_date_formats"
		return
		;;
	sendemail.aliasesfiletype)
		__gitcomp "mutt mailrc pine elm gnus"
		return
		;;
	sendemail.confirm)
		__gitcomp "$__git_send_email_confirm_options"
		return
		;;
	sendemail.suppresscc)
		__gitcomp "$__git_send_email_suppresscc_options"
		return
		;;
	--get|--get-all|--unset|--unset-all)
		__gitcomp_nl "$(__git_config_get_set_variables)"
		return
		;;
	*.*)
		return
		;;
	esac
	case "$cur" in
	--*)
		__gitcomp "
			--system --global --local --file=
			--list --replace-all
			--get --get-all --get-regexp
			--add --unset --unset-all
			--remove-section --rename-section
			"
		return
		;;
	branch.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "remote pushremote merge mergeoptions rebase" "$pfx" "$cur_"
		return
		;;
	branch.*)
		local pfx="${cur%.*}." cur_="${cur#*.}"
		__gitcomp_nl "$(__git_heads)" "$pfx" "$cur_" "."
		__gitcomp_nl_append $'autosetupmerge\nautosetuprebase\n' "$pfx" "$cur_"
		return
		;;
	guitool.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "
			argprompt cmd confirm needsfile noconsole norescan
			prompt revprompt revunmerged title
			" "$pfx" "$cur_"
		return
		;;
	difftool.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "cmd path" "$pfx" "$cur_"
		return
		;;
	man.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "cmd path" "$pfx" "$cur_"
		return
		;;
	mergetool.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "cmd path trustExitCode" "$pfx" "$cur_"
		return
		;;
	pager.*)
		local pfx="${cur%.*}." cur_="${cur#*.}"
		__git_compute_all_commands
		__gitcomp_nl "$__git_all_commands" "$pfx" "$cur_"
		return
		;;
	remote.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "
			url proxy fetch push mirror skipDefaultUpdate
			receivepack uploadpack tagopt pushurl
			" "$pfx" "$cur_"
		return
		;;
	remote.*)
		local pfx="${cur%.*}." cur_="${cur#*.}"
		__gitcomp_nl "$(__git_remotes)" "$pfx" "$cur_" "."
		__gitcomp_nl_append "pushdefault" "$pfx" "$cur_"
		return
		;;
	url.*.*)
		local pfx="${cur%.*}." cur_="${cur##*.}"
		__gitcomp "insteadOf pushInsteadOf" "$pfx" "$cur_"
		return
		;;
	esac
	__gitcomp "
		add.ignoreErrors
		advice.commitBeforeMerge
		advice.detachedHead
		advice.implicitIdentity
		advice.pushNonFastForward
		advice.resolveConflict
		advice.statusHints
		alias.
		am.keepcr
		apply.ignorewhitespace
		apply.whitespace
		branch.autosetupmerge
		branch.autosetuprebase
		browser.
		clean.requireForce
		color.branch
		color.branch.current
		color.branch.local
		color.branch.plain
		color.branch.remote
		color.decorate.HEAD
		color.decorate.branch
		color.decorate.remoteBranch
		color.decorate.stash
		color.decorate.tag
		color.diff
		color.diff.commit
		color.diff.frag
		color.diff.func
		color.diff.meta
		color.diff.new
		color.diff.old
		color.diff.plain
		color.diff.whitespace
		color.grep
		color.grep.context
		color.grep.filename
		color.grep.function
		color.grep.linenumber
		color.grep.match
		color.grep.selected
		color.grep.separator
		color.interactive
		color.interactive.error
		color.interactive.header
		color.interactive.help
		color.interactive.prompt
		color.pager
		color.showbranch
		color.status
		color.status.added
		color.status.changed
		color.status.header
		color.status.nobranch
		color.status.untracked
		color.status.updated
		color.ui
		commit.status
		commit.template
		core.abbrev
		core.askpass
		core.attributesfile
		core.autocrlf
		core.bare
		core.bigFileThreshold
		core.compression
		core.createObject
		core.deltaBaseCacheLimit
		core.editor
		core.eol
		core.excludesfile
		core.fileMode
		core.fsyncobjectfiles
		core.gitProxy
		core.ignoreStat
		core.ignorecase
		core.logAllRefUpdates
		core.loosecompression
		core.notesRef
		core.packedGitLimit
		core.packedGitWindowSize
		core.pager
		core.preferSymlinkRefs
		core.preloadindex
		core.quotepath
		core.repositoryFormatVersion
		core.safecrlf
		core.sharedRepository
		core.sparseCheckout
		core.symlinks
		core.trustctime
		core.warnAmbiguousRefs
		core.whitespace
		core.worktree
		diff.autorefreshindex
		diff.external
		diff.ignoreSubmodules
		diff.mnemonicprefix
		diff.noprefix
		diff.renameLimit
		diff.renames
		diff.statGraphWidth
		diff.submodule
		diff.suppressBlankEmpty
		diff.tool
		diff.wordRegex
		diff.algorithm
		difftool.
		difftool.prompt
		fetch.recurseSubmodules
		fetch.unpackLimit
		format.attach
		format.cc
		format.headers
		format.numbered
		format.pretty
		format.signature
		format.signoff
		format.subjectprefix
		format.suffix
		format.thread
		format.to
		gc.
		gc.aggressiveWindow
		gc.auto
		gc.autopacklimit
		gc.packrefs
		gc.pruneexpire
		gc.reflogexpire
		gc.reflogexpireunreachable
		gc.rerereresolved
		gc.rerereunresolved
		gitcvs.allbinary
		gitcvs.commitmsgannotation
		gitcvs.dbTableNamePrefix
		gitcvs.dbdriver
		gitcvs.dbname
		gitcvs.dbpass
		gitcvs.dbuser
		gitcvs.enabled
		gitcvs.logfile
		gitcvs.usecrlfattr
		guitool.
		gui.blamehistoryctx
		gui.commitmsgwidth
		gui.copyblamethreshold
		gui.diffcontext
		gui.encoding
		gui.fastcopyblame
		gui.matchtrackingbranch
		gui.newbranchtemplate
		gui.pruneduringfetch
		gui.spellingdictionary
		gui.trustmtime
		help.autocorrect
		help.browser
		help.format
		http.lowSpeedLimit
		http.lowSpeedTime
		http.maxRequests
		http.minSessions
		http.noEPSV
		http.postBuffer
		http.proxy
		http.sslCAInfo
		http.sslCAPath
		http.sslCert
		http.sslCertPasswordProtected
		http.sslKey
		http.sslVerify
		http.useragent
		i18n.commitEncoding
		i18n.logOutputEncoding
		imap.authMethod
		imap.folder
		imap.host
		imap.pass
		imap.port
		imap.preformattedHTML
		imap.sslverify
		imap.tunnel
		imap.user
		init.templatedir
		instaweb.browser
		instaweb.httpd
		instaweb.local
		instaweb.modulepath
		instaweb.port
		interactive.singlekey
		log.date
		log.decorate
		log.showroot
		mailmap.file
		man.
		man.viewer
		merge.
		merge.conflictstyle
		merge.log
		merge.renameLimit
		merge.renormalize
		merge.stat
		merge.tool
		merge.verbosity
		mergetool.
		mergetool.keepBackup
		mergetool.keepTemporaries
		mergetool.prompt
		notes.displayRef
		notes.rewrite.
		notes.rewrite.amend
		notes.rewrite.rebase
		notes.rewriteMode
		notes.rewriteRef
		pack.compression
		pack.deltaCacheLimit
		pack.deltaCacheSize
		pack.depth
		pack.indexVersion
		pack.packSizeLimit
		pack.threads
		pack.window
		pack.windowMemory
		pager.
		pretty.
		pull.octopus
		pull.twohead
		push.default
		rebase.autosquash
		rebase.stat
		receive.autogc
		receive.denyCurrentBranch
		receive.denyDeleteCurrent
		receive.denyDeletes
		receive.denyNonFastForwards
		receive.fsckObjects
		receive.unpackLimit
		receive.updateserverinfo
		remote.pushdefault
		remotes.
		repack.usedeltabaseoffset
		rerere.autoupdate
		rerere.enabled
		sendemail.
		sendemail.aliasesfile
		sendemail.aliasfiletype
		sendemail.bcc
		sendemail.cc
		sendemail.cccmd
		sendemail.chainreplyto
		sendemail.confirm
		sendemail.envelopesender
		sendemail.from
		sendemail.identity
		sendemail.multiedit
		sendemail.signedoffbycc
		sendemail.smtpdomain
		sendemail.smtpencryption
		sendemail.smtppass
		sendemail.smtpserver
		sendemail.smtpserveroption
		sendemail.smtpserverport
		sendemail.smtpuser
		sendemail.suppresscc
		sendemail.suppressfrom
		sendemail.thread
		sendemail.to
		sendemail.validate
		showbranch.default
		status.relativePaths
		status.showUntrackedFiles
		status.submodulesummary
		submodule.
		tar.umask
		transfer.unpackLimit
		url.
		user.email
		user.name
		user.signingkey
		web.browser
		branch. remote.
	"
}

_git_remote ()
{
	local subcommands="add rename remove set-head set-branches set-url show prune update"
	local subcommand="$(__git_find_on_cmdline "$subcommands")"
	if [ -z "$subcommand" ]; then
		__gitcomp "$subcommands"
		return
	fi

	case "$subcommand" in
	rename|remove|set-url|show|prune)
		__gitcomp_nl "$(__git_remotes)"
		;;
	set-head|set-branches)
		__git_complete_remote_or_refspec
		;;
	update)
		local i c='' IFS=$'\n'
		for i in $(git --git-dir="$(__gitdir)" config --get-regexp "remotes\..*" 2>/dev/null); do
			i="${i#remotes.}"
			c="$c ${i/ */}"
		done
		__gitcomp "$c"
		;;
	*)
		;;
	esac
}

_git_replace ()
{
	__gitcomp_nl "$(__git_refs)"
}

_git_reset ()
{
	__git_has_doubledash && return

	case "$cur" in
	--*)
		__gitcomp "--merge --mixed --hard --soft --patch"
		return
		;;
	esac
	__gitcomp_nl "$(__git_refs)"
}

_git_revert ()
{
	case "$cur" in
	--*)
		__gitcomp "--edit --mainline --no-edit --no-commit --signoff"
		return
		;;
	esac
	__gitcomp_nl "$(__git_refs)"
}

_git_rm ()
{
	case "$cur" in
	--*)
		__gitcomp "--cached --dry-run --ignore-unmatch --quiet"
		return
		;;
	esac

	__git_complete_index_file "--cached"
}

_git_shortlog ()
{
	__git_has_doubledash && return

	case "$cur" in
	--*)
		__gitcomp "
			$__git_log_common_options
			$__git_log_shortlog_options
			--numbered --summary
			"
		return
		;;
	esac
	__git_complete_revlist
}

_git_show ()
{
	__git_has_doubledash && return

	case "$cur" in
	--pretty=*|--format=*)
		__gitcomp "$__git_log_pretty_formats $(__git_pretty_aliases)
			" "" "${cur#*=}"
		return
		;;
	--diff-algorithm=*)
		__gitcomp "$__git_diff_algorithms" "" "${cur##--diff-algorithm=}"
		return
		;;
	--*)
		__gitcomp "--pretty= --format= --abbrev-commit --oneline
			$__git_diff_common_options
			"
		return
		;;
	esac
	__git_complete_revlist_file
}

_git_show_branch ()
{
	case "$cur" in
	--*)
		__gitcomp "
			--all --remotes --topo-order --current --more=
			--list --independent --merge-base --no-name
			--color --no-color
			--sha1-name --sparse --topics --reflog
			"
		return
		;;
	esac
	__git_complete_revlist
}

_git_stash ()
{
	local save_opts='--keep-index --no-keep-index --quiet --patch'
	local subcommands='save list show apply clear drop pop create branch'
	local subcommand="$(__git_find_on_cmdline "$subcommands")"
	if [ -z "$subcommand" ]; then
		case "$cur" in
		--*)
			__gitcomp "$save_opts"
			;;
		*)
			if [ -z "$(__git_find_on_cmdline "$save_opts")" ]; then
				__gitcomp "$subcommands"
			fi
			;;
		esac
	else
		case "$subcommand,$cur" in
		save,--*)
			__gitcomp "$save_opts"
			;;
		apply,--*|pop,--*)
			__gitcomp "--index --quiet"
			;;
		show,--*|drop,--*|branch,--*)
			;;
		show,*|apply,*|drop,*|pop,*|branch,*)
			__gitcomp_nl "$(git --git-dir="$(__gitdir)" stash list \
					| sed -n -e 's/:.*//p')"
			;;
		*)
			;;
		esac
	fi
}

_git_submodule ()
{
	__git_has_doubledash && return

	local subcommands="add status init deinit update summary foreach sync"
	if [ -z "$(__git_find_on_cmdline "$subcommands")" ]; then
		case "$cur" in
		--*)
			__gitcomp "--quiet --cached"
			;;
		*)
			__gitcomp "$subcommands"
			;;
		esac
		return
	fi
}

_git_svn ()
{
	local subcommands="
		init fetch clone rebase dcommit log find-rev
		set-tree commit-diff info create-ignore propget
		proplist show-ignore show-externals branch tag blame
		migrate mkdirs reset gc
		"
	local subcommand="$(__git_find_on_cmdline "$subcommands")"
	if [ -z "$subcommand" ]; then
		__gitcomp "$subcommands"
	else
		local remote_opts="--username= --config-dir= --no-auth-cache"
		local fc_opts="
			--follow-parent --authors-file= --repack=
			--no-metadata --use-svm-props --use-svnsync-props
			--log-window-size= --no-checkout --quiet
			--repack-flags --use-log-author --localtime
			--ignore-paths= --include-paths= $remote_opts
			"
		local init_opts="
			--template= --shared= --trunk= --tags=
			--branches= --stdlayout --minimize-url
			--no-metadata --use-svm-props --use-svnsync-props
			--rewrite-root= --prefix= --use-log-author
			--add-author-from $remote_opts
			"
		local cmt_opts="
			--edit --rmdir --find-copies-harder --copy-similarity=
			"

		case "$subcommand,$cur" in
		fetch,--*)
			__gitcomp "--revision= --fetch-all $fc_opts"
			;;
		clone,--*)
			__gitcomp "--revision= $fc_opts $init_opts"
			;;
		init,--*)
			__gitcomp "$init_opts"
			;;
		dcommit,--*)
			__gitcomp "
				--merge --strategy= --verbose --dry-run
				--fetch-all --no-rebase --commit-url
				--revision --interactive $cmt_opts $fc_opts
				"
			;;
		set-tree,--*)
			__gitcomp "--stdin $cmt_opts $fc_opts"
			;;
		create-ignore,--*|propget,--*|proplist,--*|show-ignore,--*|\
		show-externals,--*|mkdirs,--*)
			__gitcomp "--revision="
			;;
		log,--*)
			__gitcomp "
				--limit= --revision= --verbose --incremental
				--oneline --show-commit --non-recursive
				--authors-file= --color
				"
			;;
		rebase,--*)
			__gitcomp "
				--merge --verbose --strategy= --local
				--fetch-all --dry-run $fc_opts
				"
			;;
		commit-diff,--*)
			__gitcomp "--message= --file= --revision= $cmt_opts"
			;;
		info,--*)
			__gitcomp "--url"
			;;
		branch,--*)
			__gitcomp "--dry-run --message --tag"
			;;
		tag,--*)
			__gitcomp "--dry-run --message"
			;;
		blame,--*)
			__gitcomp "--git-format"
			;;
		migrate,--*)
			__gitcomp "
				--config-dir= --ignore-paths= --minimize
				--no-auth-cache --username=
				"
			;;
		reset,--*)
			__gitcomp "--revision= --parent"
			;;
		*)
			;;
		esac
	fi
}

_git_tag ()
{
	local i c=1 f=0
	while [ $c -lt $cword ]; do
		i="${words[c]}"
		case "$i" in
		-d|-v)
			__gitcomp_nl "$(__git_tags)"
			return
			;;
		-f)
			f=1
			;;
		esac
		((c++))
	done

	case "$prev" in
	-m|-F)
		;;
	-*|tag)
		if [ $f = 1 ]; then
			__gitcomp_nl "$(__git_tags)"
		fi
		;;
	*)
		__gitcomp_nl "$(__git_refs)"
		;;
	esac
}

_git_whatchanged ()
{
	_git_log
}

__git_main ()
{
	local i c=1 command __git_dir

	while [ $c -lt $cword ]; do
		i="${words[c]}"
		case "$i" in
		--git-dir=*) __git_dir="${i#--git-dir=}" ;;
		--git-dir)   ((c++)) ; __git_dir="${words[c]}" ;;
		--bare)      __git_dir="." ;;
		--help) command="help"; break ;;
		-c|--work-tree|--namespace) ((c++)) ;;
		-*) ;;
		*) command="$i"; break ;;
		esac
		((c++))
	done

	if [ -z "$command" ]; then
		case "$cur" in
		--*)   __gitcomp "
			--paginate
			--no-pager
			--git-dir=
			--bare
			--version
			--exec-path
			--exec-path=
			--html-path
			--man-path
			--info-path
			--work-tree=
			--namespace=
			--no-replace-objects
			--help
			"
			;;
		*)     __git_compute_porcelain_commands
		       __gitcomp "$__git_porcelain_commands $(__git_aliases)" ;;
		esac
		return
	fi

	local completion_func="_git_${command//-/_}"
	declare -f $completion_func >/dev/null && $completion_func && return

	local expansion=$(__git_aliased_command "$command")
	if [ -n "$expansion" ]; then
		completion_func="_git_${expansion//-/_}"
		declare -f $completion_func >/dev/null && $completion_func
	fi
}

__gitk_main ()
{
	__git_has_doubledash && return

	local g="$(__gitdir)"
	local merge=""
	if [ -f "$g/MERGE_HEAD" ]; then
		merge="--merge"
	fi
	case "$cur" in
	--*)
		__gitcomp "
			$__git_log_common_options
			$__git_log_gitk_options
			$merge
			"
		return
		;;
	esac
	__git_complete_revlist
}

if [[ -n ${ZSH_VERSION-} ]]; then
	echo "WARNING: this script is deprecated, please see git-completion.zsh" 1>&2

	autoload -U +X compinit && compinit

	__gitcomp ()
	{
		emulate -L zsh

		local cur_="${3-$cur}"

		case "$cur_" in
		--*=)
			;;
		*)
			local c IFS=$' \t\n'
			local -a array
			for c in ${=1}; do
				c="$c${4-}"
				case $c in
				--*=*|*.) ;;
				*) c="$c " ;;
				esac
				array[${#array[@]}+1]="$c"
			done
			compset -P '*[=:]'
			compadd -Q -S '' -p "${2-}" -a -- array && _ret=0
			;;
		esac
	}

	__gitcomp_nl ()
	{
		emulate -L zsh

		local IFS=$'\n'
		compset -P '*[=:]'
		compadd -Q -S "${4- }" -p "${2-}" -- ${=1} && _ret=0
	}

	__gitcomp_file ()
	{
		emulate -L zsh

		local IFS=$'\n'
		compset -P '*[=:]'
		compadd -Q -p "${2-}" -f -- ${=1} && _ret=0
	}

	_git ()
	{
		local _ret=1 cur cword prev
		cur=${words[CURRENT]}
		prev=${words[CURRENT-1]}
		let cword=CURRENT-1
		emulate ksh -c __${service}_main
		let _ret && _default && _ret=0
		return _ret
	}

	compdef _git git gitk
	return
fi

__git_func_wrap ()
{
	local cur words cword prev
	_get_comp_words_by_ref -n =: cur words cword prev
	$1
}

# Setup completion for certain functions defined above by setting common
# variables and workarounds.
# This is NOT a public function; use at your own risk.
__git_complete ()
{
	local wrapper="__git_wrap${2}"
	eval "$wrapper () { __git_func_wrap $2 ; }"
	complete -o bashdefault -o default -o nospace -F $wrapper $1 2>/dev/null \
		|| complete -o default -o nospace -F $wrapper $1
}

# wrapper for backwards compatibility
_git ()
{
	__git_wrap__git_main
}

# wrapper for backwards compatibility
_gitk ()
{
	__git_wrap__gitk_main
}

__git_complete git __git_main
__git_complete gitk __gitk_main

# The following are necessary only for Cygwin, and only are needed
# when the user has tab-completed the executable name and consequently
# included the '.exe' suffix.
#
if [ Cygwin = "$(uname -o 2>/dev/null)" ]; then
__git_complete git.exe __git_main
fi
=======



<!DOCTYPE html>
<html>
  <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# githubog: http://ogp.me/ns/fb/githubog#">
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>git/contrib/completion/git-completion.bash at master · git/git · GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub" />
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub" />
    <link rel="apple-touch-icon" sizes="57x57" href="/apple-touch-icon-114.png" />
    <link rel="apple-touch-icon" sizes="114x114" href="/apple-touch-icon-114.png" />
    <link rel="apple-touch-icon" sizes="72x72" href="/apple-touch-icon-144.png" />
    <link rel="apple-touch-icon" sizes="144x144" href="/apple-touch-icon-144.png" />
    <link rel="logo" type="image/svg" href="https://github-media-downloads.s3.amazonaws.com/github-logo.svg" />
    <meta property="og:image" content="https://github.global.ssl.fastly.net/images/modules/logos_page/Octocat.png">
    <meta name="hostname" content="github-fe133-cp1-prd.iad.github.net">
    <meta name="ruby" content="ruby 1.9.3p194-tcs-github-tcmalloc (e1c0c3f392) [x86_64-linux]">
    <link rel="assets" href="https://github.global.ssl.fastly.net/">
    <link rel="conduit-xhr" href="https://ghconduit.com:25035/">
    <link rel="xhr-socket" href="/_sockets" />
    


    <meta name="msapplication-TileImage" content="/windows-tile.png" />
    <meta name="msapplication-TileColor" content="#ffffff" />
    <meta name="selected-link" value="repo_source" data-pjax-transient />
    <meta content="collector.githubapp.com" name="octolytics-host" /><meta content="collector-cdn.github.com" name="octolytics-script-host" /><meta content="github" name="octolytics-app-id" /><meta content="4DFDE193:4E6B:8AFE4A4:52BAC97E" name="octolytics-dimension-request_id" />
    

    
    
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />

    <meta content="authenticity_token" name="csrf-param" />
<meta content="nzmMhyfs1kb0PcVWCTwCAA1+LdnFikKDwvizH9KUV4c=" name="csrf-token" />

    <link href="https://github.global.ssl.fastly.net/assets/github-8f6ca9b17ae3eba1e30276eef0a16282cb651c78.css" media="all" rel="stylesheet" type="text/css" />
    <link href="https://github.global.ssl.fastly.net/assets/github2-5a80bdfa39bad96522873dfd72fa56c72e6675b3.css" media="all" rel="stylesheet" type="text/css" />
    

    

      <script src="https://github.global.ssl.fastly.net/assets/frameworks-29a3fb0547e33bd8d4530bbad9bae3ef00d83293.js" type="text/javascript"></script>
      <script src="https://github.global.ssl.fastly.net/assets/github-0b6bf4a8bb8bc8246eb6d07db6a63cde130f5001.js" type="text/javascript"></script>
      
      <meta http-equiv="x-pjax-version" content="25e9435426189c5ffea9ed5e7a16f621">

        <link data-pjax-transient rel='permalink' href='/git/git/blob/7794a680e63a2a11b73cb1194653662f2769a792/contrib/completion/git-completion.bash'>
  <meta property="og:title" content="git"/>
  <meta property="og:type" content="githubog:gitrepository"/>
  <meta property="og:url" content="https://github.com/git/git"/>
  <meta property="og:image" content="https://github.global.ssl.fastly.net/images/gravatars/gravatar-user-420.png"/>
  <meta property="og:site_name" content="GitHub"/>
  <meta property="og:description" content="git - Git Source Code Mirror - This is a publish-only repository and all pull requests are ignored. Please follow Documentation/SubmittingPatches procedure for any of your improvements."/>

  <meta name="description" content="git - Git Source Code Mirror - This is a publish-only repository and all pull requests are ignored. Please follow Documentation/SubmittingPatches procedure for any of your improvements." />

  <meta content="18133" name="octolytics-dimension-user_id" /><meta content="git" name="octolytics-dimension-user_login" /><meta content="36502" name="octolytics-dimension-repository_id" /><meta content="git/git" name="octolytics-dimension-repository_nwo" /><meta content="true" name="octolytics-dimension-repository_public" /><meta content="false" name="octolytics-dimension-repository_is_fork" /><meta content="36502" name="octolytics-dimension-repository_network_root_id" /><meta content="git/git" name="octolytics-dimension-repository_network_root_nwo" />
  <link href="https://github.com/git/git/commits/master.atom" rel="alternate" title="Recent Commits to git:master" type="application/atom+xml" />

  </head>


  <body class="logged_out  env-production  vis-public page-blob">
    <div class="wrapper">
      
      
      
      


      
      <div class="header header-logged-out">
  <div class="container clearfix">

    <a class="header-logo-wordmark" href="https://github.com/">
      <span class="mega-octicon octicon-logo-github"></span>
    </a>

    <div class="header-actions">
        <a class="button primary" href="/join">Sign up</a>
      <a class="button signin" href="/login?return_to=%2Fgit%2Fgit%2Fblob%2Fmaster%2Fcontrib%2Fcompletion%2Fgit-completion.bash">Sign in</a>
    </div>

    <div class="command-bar js-command-bar  in-repository">

      <ul class="top-nav">
          <li class="explore"><a href="/explore">Explore</a></li>
        <li class="features"><a href="/features">Features</a></li>
          <li class="enterprise"><a href="https://enterprise.github.com/">Enterprise</a></li>
          <li class="blog"><a href="/blog">Blog</a></li>
      </ul>
        <form accept-charset="UTF-8" action="/search" class="command-bar-form" id="top_search_form" method="get">

<input type="text" data-hotkey="/ s" name="q" id="js-command-bar-field" placeholder="Search or type a command" tabindex="1" autocapitalize="off"
    
    
      data-repo="git/git"
      data-branch="master"
      data-sha="02af835624487074efb46d224cdc3530d9f83da0"
  >

    <input type="hidden" name="nwo" value="git/git" />

    <div class="select-menu js-menu-container js-select-menu search-context-select-menu">
      <span class="minibutton select-menu-button js-menu-target">
        <span class="js-select-button">This repository</span>
      </span>

      <div class="select-menu-modal-holder js-menu-content js-navigation-container">
        <div class="select-menu-modal">

          <div class="select-menu-item js-navigation-item js-this-repository-navigation-item selected">
            <span class="select-menu-item-icon octicon octicon-check"></span>
            <input type="radio" class="js-search-this-repository" name="search_target" value="repository" checked="checked" />
            <div class="select-menu-item-text js-select-button-text">This repository</div>
          </div> <!-- /.select-menu-item -->

          <div class="select-menu-item js-navigation-item js-all-repositories-navigation-item">
            <span class="select-menu-item-icon octicon octicon-check"></span>
            <input type="radio" name="search_target" value="global" />
            <div class="select-menu-item-text js-select-button-text">All repositories</div>
          </div> <!-- /.select-menu-item -->

        </div>
      </div>
    </div>

  <span class="octicon help tooltipped downwards" title="Show command bar help">
    <span class="octicon octicon-question"></span>
  </span>


  <input type="hidden" name="ref" value="cmdform">

</form>
    </div>

  </div>
</div>


      


          <div class="site" itemscope itemtype="http://schema.org/WebPage">
    
    <div class="pagehead repohead instapaper_ignore readability-menu">
      <div class="container">
        

<ul class="pagehead-actions">


  <li>
    <a href="/login?return_to=%2Fgit%2Fgit"
    class="minibutton with-count js-toggler-target star-button tooltipped upwards"
    title="You must be signed in to use this feature" rel="nofollow">
    <span class="octicon octicon-star"></span>Star
  </a>

    <a class="social-count js-social-count" href="/git/git/stargazers">
      5,080
    </a>

  </li>

    <li>
      <a href="/login?return_to=%2Fgit%2Fgit"
        class="minibutton with-count js-toggler-target fork-button tooltipped upwards"
        title="You must be signed in to fork a repository" rel="nofollow">
        <span class="octicon octicon-git-branch"></span>Fork
      </a>
      <a href="/git/git/network" class="social-count">
        2,523
      </a>
    </li>
</ul>

        <h1 itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="entry-title public">
          <span class="repo-label"><span>public</span></span>
          <span class="mega-octicon octicon-repo"></span>
          <span class="author">
            <a href="/git" class="url fn" itemprop="url" rel="author"><span itemprop="title">git</span></a>
          </span>
          <span class="repohead-name-divider">/</span>
          <strong><a href="/git/git" class="js-current-repository js-repo-home-link">git</a></strong>

          <span class="page-context-loader">
            <img alt="Octocat-spinner-32" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
          </span>

        </h1>
      </div><!-- /.container -->
    </div><!-- /.repohead -->

    <div class="container">
      

      <div class="repository-with-sidebar repo-container  ">

        <div class="repository-sidebar">
            

<div class="sunken-menu vertical-right repo-nav js-repo-nav js-repository-container-pjax js-octicon-loaders">
  <div class="sunken-menu-contents">
    <ul class="sunken-menu-group">
      <li class="tooltipped leftwards" title="Code">
        <a href="/git/git" aria-label="Code" class="selected js-selected-navigation-item sunken-menu-item" data-gotokey="c" data-pjax="true" data-selected-links="repo_source repo_downloads repo_commits repo_tags repo_branches /git/git">
          <span class="octicon octicon-code"></span> <span class="full-word">Code</span>
          <img alt="Octocat-spinner-32" class="mini-loader" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>


      <li class="tooltipped leftwards" title="Pull Requests">
        <a href="/git/git/pulls" aria-label="Pull Requests" class="js-selected-navigation-item sunken-menu-item js-disable-pjax" data-gotokey="p" data-selected-links="repo_pulls /git/git/pulls">
            <span class="octicon octicon-git-pull-request"></span> <span class="full-word">Pull Requests</span>
            <span class='counter'>8</span>
            <img alt="Octocat-spinner-32" class="mini-loader" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>


    </ul>
    <div class="sunken-menu-separator"></div>
    <ul class="sunken-menu-group">

      <li class="tooltipped leftwards" title="Pulse">
        <a href="/git/git/pulse" aria-label="Pulse" class="js-selected-navigation-item sunken-menu-item" data-pjax="true" data-selected-links="pulse /git/git/pulse">
          <span class="octicon octicon-pulse"></span> <span class="full-word">Pulse</span>
          <img alt="Octocat-spinner-32" class="mini-loader" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>

      <li class="tooltipped leftwards" title="Graphs">
        <a href="/git/git/graphs" aria-label="Graphs" class="js-selected-navigation-item sunken-menu-item" data-pjax="true" data-selected-links="repo_graphs repo_contributors /git/git/graphs">
          <span class="octicon octicon-graph"></span> <span class="full-word">Graphs</span>
          <img alt="Octocat-spinner-32" class="mini-loader" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>

      <li class="tooltipped leftwards" title="Network">
        <a href="/git/git/network" aria-label="Network" class="js-selected-navigation-item sunken-menu-item js-disable-pjax" data-selected-links="repo_network /git/git/network">
          <span class="octicon octicon-git-branch"></span> <span class="full-word">Network</span>
          <img alt="Octocat-spinner-32" class="mini-loader" height="16" src="https://github.global.ssl.fastly.net/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>
    </ul>


  </div>
</div>

            <div class="only-with-full-nav">
              

  

<div class="clone-url open"
  data-protocol-type="http"
  data-url="/users/set_protocol?protocol_selector=http&amp;protocol_type=clone">
  <h3><strong>HTTPS</strong> clone URL</h3>
  <div class="clone-url-box">
    <input type="text" class="clone js-url-field"
           value="https://github.com/git/git.git" readonly="readonly">

    <span class="js-zeroclipboard url-box-clippy minibutton zeroclipboard-button" data-clipboard-text="https://github.com/git/git.git" data-copied-hint="copied!" title="copy to clipboard"><span class="octicon octicon-clippy"></span></span>
  </div>
</div>

  

<div class="clone-url "
  data-protocol-type="subversion"
  data-url="/users/set_protocol?protocol_selector=subversion&amp;protocol_type=clone">
  <h3><strong>Subversion</strong> checkout URL</h3>
  <div class="clone-url-box">
    <input type="text" class="clone js-url-field"
           value="https://github.com/git/git" readonly="readonly">

    <span class="js-zeroclipboard url-box-clippy minibutton zeroclipboard-button" data-clipboard-text="https://github.com/git/git" data-copied-hint="copied!" title="copy to clipboard"><span class="octicon octicon-clippy"></span></span>
  </div>
</div>


<p class="clone-options">You can clone with
      <a href="#" class="js-clone-selector" data-protocol="http">HTTPS</a>,
      or <a href="#" class="js-clone-selector" data-protocol="subversion">Subversion</a>.
  <span class="octicon help tooltipped upwards" title="Get help on which URL is right for you.">
    <a href="https://help.github.com/articles/which-remote-url-should-i-use">
    <span class="octicon octicon-question"></span>
    </a>
  </span>
</p>



              <a href="/git/git/archive/master.zip"
                 class="minibutton sidebar-button"
                 title="Download this repository as a zip file"
                 rel="nofollow">
                <span class="octicon octicon-cloud-download"></span>
                Download ZIP
              </a>
            </div>
        </div><!-- /.repository-sidebar -->

        <div id="js-repo-pjax-container" class="repository-content context-loader-container" data-pjax-container>
          


<!-- blob contrib key: blob_contributors:v21:5e1c60623b4b7667d0fc24813fb18f38 -->

<p title="This is a placeholder element" class="js-history-link-replace hidden"></p>

<a href="/git/git/find/master" data-pjax data-hotkey="t" class="js-show-file-finder" style="display:none">Show File Finder</a>

<div class="file-navigation">
  

<div class="select-menu js-menu-container js-select-menu" >
  <span class="minibutton select-menu-button js-menu-target" data-hotkey="w"
    data-master-branch="master"
    data-ref="master"
    role="button" aria-label="Switch branches or tags" tabindex="0">
    <span class="octicon octicon-git-branch"></span>
    <i>branch:</i>
    <span class="js-select-button">master</span>
  </span>

  <div class="select-menu-modal-holder js-menu-content js-navigation-container" data-pjax>

    <div class="select-menu-modal">
      <div class="select-menu-header">
        <span class="select-menu-title">Switch branches/tags</span>
        <span class="octicon octicon-remove-close js-menu-close"></span>
      </div> <!-- /.select-menu-header -->

      <div class="select-menu-filters">
        <div class="select-menu-text-filter">
          <input type="text" aria-label="Filter branches/tags" id="context-commitish-filter-field" class="js-filterable-field js-navigation-enable" placeholder="Filter branches/tags">
        </div>
        <div class="select-menu-tabs">
          <ul>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="branches" class="js-select-menu-tab">Branches</a>
            </li>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="tags" class="js-select-menu-tab">Tags</a>
            </li>
          </ul>
        </div><!-- /.select-menu-tabs -->
      </div><!-- /.select-menu-filters -->

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="branches">

        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/blob/maint/contrib/completion/git-completion.bash"
                 data-name="maint"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="maint">maint</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item selected">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/blob/master/contrib/completion/git-completion.bash"
                 data-name="master"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="master">master</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/blob/next/contrib/completion/git-completion.bash"
                 data-name="next"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="next">next</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/blob/pu/contrib/completion/git-completion.bash"
                 data-name="pu"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="pu">pu</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/blob/todo/contrib/completion/git-completion.bash"
                 data-name="todo"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="todo">todo</a>
            </div> <!-- /.select-menu-item -->
        </div>

          <div class="select-menu-no-results">Nothing to show</div>
      </div> <!-- /.select-menu-list -->

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="tags">
        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.5-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5-rc3">v1.8.5-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.5-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5-rc2">v1.8.5-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.5-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5-rc1">v1.8.5-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.5-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5-rc0">v1.8.5-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5.2">v1.8.5.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5.1">v1.8.5.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.5/contrib/completion/git-completion.bash"
                 data-name="v1.8.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.5">v1.8.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.8.4-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4-rc4">v1.8.4-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.4-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4-rc3">v1.8.4-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.4-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4-rc2">v1.8.4-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.4-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4-rc1">v1.8.4-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.4-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4-rc0">v1.8.4-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4.5/contrib/completion/git-completion.bash"
                 data-name="v1.8.4.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4.5">v1.8.4.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.8.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4.4">v1.8.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4.3">v1.8.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4.2">v1.8.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4.1">v1.8.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.4/contrib/completion/git-completion.bash"
                 data-name="v1.8.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.4">v1.8.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.3-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3-rc3">v1.8.3-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.3-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3-rc2">v1.8.3-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.3-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3-rc1">v1.8.3-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.3-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3-rc0">v1.8.3-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3.4/contrib/completion/git-completion.bash"
                 data-name="v1.8.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3.4">v1.8.3.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3.3">v1.8.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3.2">v1.8.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3.1">v1.8.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.3">v1.8.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.2-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2-rc3">v1.8.2-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.2-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2-rc2">v1.8.2-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.2-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2-rc1">v1.8.2-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.2-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2-rc0">v1.8.2-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2.3">v1.8.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2.2">v1.8.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2.1">v1.8.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.2">v1.8.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.1-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1-rc3">v1.8.1-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.1-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1-rc2">v1.8.1-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1-rc1">v1.8.1-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.1-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1-rc0">v1.8.1-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.6/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.6">v1.8.1.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.5/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.5">v1.8.1.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.4/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.4">v1.8.1.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.3">v1.8.1.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.2">v1.8.1.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1.1">v1.8.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.1">v1.8.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.8.0-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0-rc3">v1.8.0-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.8.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0-rc2">v1.8.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.8.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0-rc1">v1.8.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.8.0-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0-rc0">v1.8.0-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0.3/contrib/completion/git-completion.bash"
                 data-name="v1.8.0.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0.3">v1.8.0.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0.2/contrib/completion/git-completion.bash"
                 data-name="v1.8.0.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0.2">v1.8.0.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0.1/contrib/completion/git-completion.bash"
                 data-name="v1.8.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0.1">v1.8.0.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.8.0/contrib/completion/git-completion.bash"
                 data-name="v1.8.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.8.0">v1.8.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.12-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12-rc3">v1.7.12-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.12-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12-rc2">v1.7.12-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.12-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12-rc1">v1.7.12-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.12-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12-rc0">v1.7.12-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.12.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12.4">v1.7.12.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.12.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12.3">v1.7.12.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.12.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12.2">v1.7.12.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.12.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12.1">v1.7.12.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.12/contrib/completion/git-completion.bash"
                 data-name="v1.7.12"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.12">v1.7.12</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.11-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11-rc3">v1.7.11-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.11-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11-rc2">v1.7.11-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.11-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11-rc1">v1.7.11-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.11-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11-rc0">v1.7.11-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.7/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.7">v1.7.11.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.6">v1.7.11.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.5">v1.7.11.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.4">v1.7.11.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.3">v1.7.11.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.2">v1.7.11.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.11.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11.1">v1.7.11.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.11/contrib/completion/git-completion.bash"
                 data-name="v1.7.11"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.11">v1.7.11</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.7.10-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10-rc4">v1.7.10-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.10-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10-rc3">v1.7.10-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.10-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10-rc2">v1.7.10-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.10-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10-rc1">v1.7.10-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.10-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10-rc0">v1.7.10-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.10.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10.5">v1.7.10.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.10.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10.4">v1.7.10.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.10.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10.3">v1.7.10.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.10.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10.2">v1.7.10.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.10.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10.1">v1.7.10.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.10/contrib/completion/git-completion.bash"
                 data-name="v1.7.10"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.10">v1.7.10</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.9-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9-rc2">v1.7.9-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.9-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9-rc1">v1.7.9-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.9-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9-rc0">v1.7.9-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.7/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.7">v1.7.9.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.6">v1.7.9.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.5">v1.7.9.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.4">v1.7.9.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.3">v1.7.9.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.2">v1.7.9.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.9.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9.1">v1.7.9.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.9/contrib/completion/git-completion.bash"
                 data-name="v1.7.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.9">v1.7.9</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.7.8-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8-rc4">v1.7.8-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.8-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8-rc3">v1.7.8-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.8-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8-rc2">v1.7.8-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.8-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8-rc1">v1.7.8-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.8-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8-rc0">v1.7.8-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.6">v1.7.8.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.5">v1.7.8.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.4">v1.7.8.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.3">v1.7.8.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.2">v1.7.8.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.8.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8.1">v1.7.8.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.8/contrib/completion/git-completion.bash"
                 data-name="v1.7.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.8">v1.7.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.7-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7-rc3">v1.7.7-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.7-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7-rc2">v1.7.7-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.7-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7-rc1">v1.7.7-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.7-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7-rc0">v1.7.7-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.7/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.7">v1.7.7.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.6">v1.7.7.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.5">v1.7.7.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.4">v1.7.7.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.3">v1.7.7.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.2">v1.7.7.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.7.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7.1">v1.7.7.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.7/contrib/completion/git-completion.bash"
                 data-name="v1.7.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.7">v1.7.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.6-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6-rc3">v1.7.6-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.6-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6-rc2">v1.7.6-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.6-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6-rc1">v1.7.6-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.6-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6-rc0">v1.7.6-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.6">v1.7.6.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.5">v1.7.6.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.4">v1.7.6.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.3">v1.7.6.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.2">v1.7.6.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6.1">v1.7.6.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.6">v1.7.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.5-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5-rc3">v1.7.5-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.5-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5-rc2">v1.7.5-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.5-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5-rc1">v1.7.5-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.5-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5-rc0">v1.7.5-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5.4">v1.7.5.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5.3">v1.7.5.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5.2">v1.7.5.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5.1">v1.7.5.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.5">v1.7.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.4-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4-rc3">v1.7.4-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.4-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4-rc2">v1.7.4-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.4-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4-rc1">v1.7.4-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.4-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4-rc0">v1.7.4-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.4.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4.5">v1.7.4.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4.4">v1.7.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4.3">v1.7.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4.2">v1.7.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4.1">v1.7.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.4">v1.7.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.3-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3-rc2">v1.7.3-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.3-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3-rc1">v1.7.3-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.3-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3-rc0">v1.7.3-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.3.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3.5">v1.7.3.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3.4">v1.7.3.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3.3">v1.7.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3.2">v1.7.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3.1">v1.7.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.3">v1.7.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.7.2-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2-rc3">v1.7.2-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.2-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2-rc2">v1.7.2-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.2-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2-rc1">v1.7.2-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.2-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2-rc0">v1.7.2-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.2.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2.5">v1.7.2.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.2.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2.4">v1.7.2.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2.3">v1.7.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2.2">v1.7.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2.1">v1.7.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.2">v1.7.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.1-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1-rc2">v1.7.1-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1-rc1">v1.7.1-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.1-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1-rc0">v1.7.1-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1.4">v1.7.1.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1.3">v1.7.1.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1.2">v1.7.1.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1.1">v1.7.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.1">v1.7.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.7.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0-rc2">v1.7.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.7.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0-rc1">v1.7.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.7.0-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0-rc0">v1.7.0-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.9/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.9">v1.7.0.9</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.8/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.8">v1.7.0.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.7/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.7">v1.7.0.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.6/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.6">v1.7.0.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.5/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.5">v1.7.0.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.4/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.4">v1.7.0.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.3/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.3">v1.7.0.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.2/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.2">v1.7.0.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0.1/contrib/completion/git-completion.bash"
                 data-name="v1.7.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0.1">v1.7.0.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.7.0/contrib/completion/git-completion.bash"
                 data-name="v1.7.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.7.0">v1.7.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.6.6-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6-rc4">v1.6.6-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.6-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6-rc3">v1.6.6-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.6-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6-rc2">v1.6.6-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.6-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6-rc1">v1.6.6-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.6-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6-rc0">v1.6.6-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.6.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6.3">v1.6.6.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6.2">v1.6.6.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6.1">v1.6.6.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.6/contrib/completion/git-completion.bash"
                 data-name="v1.6.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.6">v1.6.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.5-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5-rc3">v1.6.5-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.5-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5-rc2">v1.6.5-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.5-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5-rc1">v1.6.5-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.5-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5-rc0">v1.6.5-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.9/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.9">v1.6.5.9</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.8/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.8">v1.6.5.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.7/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.7">v1.6.5.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.6/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.6">v1.6.5.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.5/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.5">v1.6.5.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.4">v1.6.5.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.3">v1.6.5.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.2">v1.6.5.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5.1">v1.6.5.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.5/contrib/completion/git-completion.bash"
                 data-name="v1.6.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.5">v1.6.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.4-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4-rc3">v1.6.4-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.4-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4-rc2">v1.6.4-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.4-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4-rc1">v1.6.4-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.4-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4-rc0">v1.6.4-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4.5/contrib/completion/git-completion.bash"
                 data-name="v1.6.4.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4.5">v1.6.4.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4.4">v1.6.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4.3">v1.6.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4.2">v1.6.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4.1">v1.6.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.4">v1.6.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.6.3-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3-rc4">v1.6.3-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.3-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3-rc3">v1.6.3-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.3-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3-rc2">v1.6.3-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.3-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3-rc1">v1.6.3-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.3-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3-rc0">v1.6.3-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3.4">v1.6.3.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3.3">v1.6.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3.2">v1.6.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3.1">v1.6.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.3">v1.6.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.2-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2-rc2">v1.6.2-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.2-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2-rc1">v1.6.2-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.2-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2-rc0">v1.6.2-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2.5/contrib/completion/git-completion.bash"
                 data-name="v1.6.2.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2.5">v1.6.2.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.2.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2.4">v1.6.2.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2.3">v1.6.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2.2">v1.6.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2.1">v1.6.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.2">v1.6.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.6.1-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1-rc4">v1.6.1-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.1-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1-rc3">v1.6.1-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.1-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1-rc2">v1.6.1-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1-rc1">v1.6.1-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1.4">v1.6.1.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1.3">v1.6.1.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1.2">v1.6.1.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1.1">v1.6.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.1">v1.6.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.6.0-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0-rc3">v1.6.0-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.6.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0-rc2">v1.6.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.6.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0-rc1">v1.6.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.6.0-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0-rc0">v1.6.0-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.6/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.6">v1.6.0.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.5/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.5">v1.6.0.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.4/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.4">v1.6.0.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.3/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.3">v1.6.0.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.2/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.2">v1.6.0.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0.1/contrib/completion/git-completion.bash"
                 data-name="v1.6.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0.1">v1.6.0.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.6.0/contrib/completion/git-completion.bash"
                 data-name="v1.6.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.6.0">v1.6.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.6-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6-rc3">v1.5.6-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.6-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6-rc2">v1.5.6-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.6-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6-rc1">v1.5.6-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.6-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6-rc0">v1.5.6-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.6">v1.5.6.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.5">v1.5.6.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.4">v1.5.6.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.3">v1.5.6.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.2">v1.5.6.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6.1">v1.5.6.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.6">v1.5.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.5-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5-rc3">v1.5.5-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.5-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5-rc2">v1.5.5-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.5-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5-rc1">v1.5.5-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.5-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5-rc0">v1.5.5-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.6">v1.5.5.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.5">v1.5.5.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.4">v1.5.5.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.3">v1.5.5.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.2">v1.5.5.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5.1">v1.5.5.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.5">v1.5.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc5/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc5">v1.5.4-rc5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc4">v1.5.4-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc3">v1.5.4-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc2">v1.5.4-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc1">v1.5.4-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.4-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4-rc0">v1.5.4-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.7/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.7">v1.5.4.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.6">v1.5.4.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.5">v1.5.4.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.4">v1.5.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.3">v1.5.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.2">v1.5.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4.1">v1.5.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.4">v1.5.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc7/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc7">v1.5.3-rc7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc6/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc6">v1.5.3-rc6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc5/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc5">v1.5.3-rc5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc4">v1.5.3-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc3">v1.5.3-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc2">v1.5.3-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc1">v1.5.3-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.3-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3-rc0">v1.5.3-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.8/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.8">v1.5.3.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.7/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.7">v1.5.3.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.6">v1.5.3.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.5">v1.5.3.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.4">v1.5.3.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.3">v1.5.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.2">v1.5.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3.1">v1.5.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.3">v1.5.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.2-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2-rc3">v1.5.2-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.2-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2-rc2">v1.5.2-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.2-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2-rc1">v1.5.2-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.2-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2-rc0">v1.5.2-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.2.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2.5">v1.5.2.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.2.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2.4">v1.5.2.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2.3">v1.5.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2.2">v1.5.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2.1">v1.5.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.2">v1.5.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.1-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1-rc3">v1.5.1-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.1-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1-rc2">v1.5.1-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1-rc1">v1.5.1-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.6">v1.5.1.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.5">v1.5.1.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.4">v1.5.1.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.3">v1.5.1.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.2">v1.5.1.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1.1">v1.5.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.1">v1.5.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.5.0-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0-rc4">v1.5.0-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.5.0-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0-rc3">v1.5.0-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.5.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0-rc2">v1.5.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.5.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0-rc1">v1.5.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0-rc0/contrib/completion/git-completion.bash"
                 data-name="v1.5.0-rc0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0-rc0">v1.5.0-rc0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.7/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.7">v1.5.0.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.6/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.6">v1.5.0.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.5/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.5">v1.5.0.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.4/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.4">v1.5.0.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.3/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.3">v1.5.0.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.2/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.2">v1.5.0.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0.1/contrib/completion/git-completion.bash"
                 data-name="v1.5.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0.1">v1.5.0.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.5.0/contrib/completion/git-completion.bash"
                 data-name="v1.5.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.5.0">v1.5.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.4.4-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4-rc2">v1.4.4-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.4.4-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4-rc1">v1.4.4-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4.5/contrib/completion/git-completion.bash"
                 data-name="v1.4.4.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4.5">v1.4.4.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.4.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4.4">v1.4.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.4.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4.3">v1.4.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.4.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4.2">v1.4.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.4.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4.1">v1.4.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.4/contrib/completion/git-completion.bash"
                 data-name="v1.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.4">v1.4.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.4.3-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3-rc3">v1.4.3-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.4.3-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3-rc2">v1.4.3-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.4.3-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3-rc1">v1.4.3-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3.5/contrib/completion/git-completion.bash"
                 data-name="v1.4.3.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3.5">v1.4.3.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3.4/contrib/completion/git-completion.bash"
                 data-name="v1.4.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3.4">v1.4.3.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.4.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3.3">v1.4.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.4.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3.2">v1.4.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.4.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3.1">v1.4.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.3/contrib/completion/git-completion.bash"
                 data-name="v1.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.3">v1.4.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.4.2-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2-rc4">v1.4.2-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.4.2-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2-rc3">v1.4.2-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.4.2-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2-rc2">v1.4.2-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.4.2-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2-rc1">v1.4.2-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2.4/contrib/completion/git-completion.bash"
                 data-name="v1.4.2.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2.4">v1.4.2.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.4.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2.3">v1.4.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.4.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2.2">v1.4.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.4.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2.1">v1.4.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.2/contrib/completion/git-completion.bash"
                 data-name="v1.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.2">v1.4.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.1-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.4.1-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.1-rc2">v1.4.1-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.1-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.4.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.1-rc1">v1.4.1-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.4.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.1.1">v1.4.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.1/contrib/completion/git-completion.bash"
                 data-name="v1.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.1">v1.4.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.4.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.0-rc2">v1.4.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.4.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.0-rc1">v1.4.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.4.0/contrib/completion/git-completion.bash"
                 data-name="v1.4.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.4.0">v1.4.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.3/contrib/completion/git-completion.bash"
                 data-name="v1.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.3">v1.3.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.2/contrib/completion/git-completion.bash"
                 data-name="v1.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.2">v1.3.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.1/contrib/completion/git-completion.bash"
                 data-name="v1.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.1">v1.3.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.0-rc4/contrib/completion/git-completion.bash"
                 data-name="v1.3.0-rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.0-rc4">v1.3.0-rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.0-rc3/contrib/completion/git-completion.bash"
                 data-name="v1.3.0-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.0-rc3">v1.3.0-rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.0-rc2/contrib/completion/git-completion.bash"
                 data-name="v1.3.0-rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.0-rc2">v1.3.0-rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.0-rc1/contrib/completion/git-completion.bash"
                 data-name="v1.3.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.0-rc1">v1.3.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.3.0/contrib/completion/git-completion.bash"
                 data-name="v1.3.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.3.0">v1.3.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.6/contrib/completion/git-completion.bash"
                 data-name="v1.2.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.6">v1.2.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.5/contrib/completion/git-completion.bash"
                 data-name="v1.2.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.5">v1.2.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.4/contrib/completion/git-completion.bash"
                 data-name="v1.2.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.4">v1.2.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.3/contrib/completion/git-completion.bash"
                 data-name="v1.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.3">v1.2.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.2/contrib/completion/git-completion.bash"
                 data-name="v1.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.2">v1.2.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.1/contrib/completion/git-completion.bash"
                 data-name="v1.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.1">v1.2.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.2.0/contrib/completion/git-completion.bash"
                 data-name="v1.2.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.2.0">v1.2.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.6/contrib/completion/git-completion.bash"
                 data-name="v1.1.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.6">v1.1.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.5/contrib/completion/git-completion.bash"
                 data-name="v1.1.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.5">v1.1.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.4/contrib/completion/git-completion.bash"
                 data-name="v1.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.4">v1.1.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.3/contrib/completion/git-completion.bash"
                 data-name="v1.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.3">v1.1.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.2/contrib/completion/git-completion.bash"
                 data-name="v1.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.2">v1.1.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.1/contrib/completion/git-completion.bash"
                 data-name="v1.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.1">v1.1.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.1.0/contrib/completion/git-completion.bash"
                 data-name="v1.1.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.1.0">v1.1.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc6/contrib/completion/git-completion.bash"
                 data-name="v1.0rc6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc6">v1.0rc6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc5/contrib/completion/git-completion.bash"
                 data-name="v1.0rc5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc5">v1.0rc5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc4/contrib/completion/git-completion.bash"
                 data-name="v1.0rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc4">v1.0rc4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc3/contrib/completion/git-completion.bash"
                 data-name="v1.0rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc3">v1.0rc3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc2/contrib/completion/git-completion.bash"
                 data-name="v1.0rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc2">v1.0rc2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0rc1/contrib/completion/git-completion.bash"
                 data-name="v1.0rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0rc1">v1.0rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.13/contrib/completion/git-completion.bash"
                 data-name="v1.0.13"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.13">v1.0.13</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.12/contrib/completion/git-completion.bash"
                 data-name="v1.0.12"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.12">v1.0.12</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.11/contrib/completion/git-completion.bash"
                 data-name="v1.0.11"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.11">v1.0.11</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.10/contrib/completion/git-completion.bash"
                 data-name="v1.0.10"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.10">v1.0.10</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.9/contrib/completion/git-completion.bash"
                 data-name="v1.0.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.9">v1.0.9</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.8/contrib/completion/git-completion.bash"
                 data-name="v1.0.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.8">v1.0.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.7/contrib/completion/git-completion.bash"
                 data-name="v1.0.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.7">v1.0.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.6/contrib/completion/git-completion.bash"
                 data-name="v1.0.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.6">v1.0.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.5/contrib/completion/git-completion.bash"
                 data-name="v1.0.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.5">v1.0.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.4/contrib/completion/git-completion.bash"
                 data-name="v1.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.4">v1.0.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.3/contrib/completion/git-completion.bash"
                 data-name="v1.0.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.3">v1.0.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.2/contrib/completion/git-completion.bash"
                 data-name="v1.0.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.2">v1.0.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.1/contrib/completion/git-completion.bash"
                 data-name="v1.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.1">v1.0.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.0b/contrib/completion/git-completion.bash"
                 data-name="v1.0.0b"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.0b">v1.0.0b</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.0a/contrib/completion/git-completion.bash"
                 data-name="v1.0.0a"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.0a">v1.0.0a</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v1.0.0/contrib/completion/git-completion.bash"
                 data-name="v1.0.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v1.0.0">v1.0.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9n/contrib/completion/git-completion.bash"
                 data-name="v0.99.9n"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9n">v0.99.9n</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9m/contrib/completion/git-completion.bash"
                 data-name="v0.99.9m"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9m">v0.99.9m</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9l/contrib/completion/git-completion.bash"
                 data-name="v0.99.9l"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9l">v0.99.9l</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9k/contrib/completion/git-completion.bash"
                 data-name="v0.99.9k"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9k">v0.99.9k</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9j/contrib/completion/git-completion.bash"
                 data-name="v0.99.9j"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9j">v0.99.9j</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9i/contrib/completion/git-completion.bash"
                 data-name="v0.99.9i"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9i">v0.99.9i</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9h/contrib/completion/git-completion.bash"
                 data-name="v0.99.9h"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9h">v0.99.9h</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9g/contrib/completion/git-completion.bash"
                 data-name="v0.99.9g"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9g">v0.99.9g</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9f/contrib/completion/git-completion.bash"
                 data-name="v0.99.9f"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9f">v0.99.9f</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9e/contrib/completion/git-completion.bash"
                 data-name="v0.99.9e"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9e">v0.99.9e</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9d/contrib/completion/git-completion.bash"
                 data-name="v0.99.9d"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9d">v0.99.9d</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9c/contrib/completion/git-completion.bash"
                 data-name="v0.99.9c"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9c">v0.99.9c</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9b/contrib/completion/git-completion.bash"
                 data-name="v0.99.9b"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9b">v0.99.9b</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9a/contrib/completion/git-completion.bash"
                 data-name="v0.99.9a"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9a">v0.99.9a</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.9/contrib/completion/git-completion.bash"
                 data-name="v0.99.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.9">v0.99.9</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8g/contrib/completion/git-completion.bash"
                 data-name="v0.99.8g"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8g">v0.99.8g</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8f/contrib/completion/git-completion.bash"
                 data-name="v0.99.8f"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8f">v0.99.8f</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8e/contrib/completion/git-completion.bash"
                 data-name="v0.99.8e"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8e">v0.99.8e</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8d/contrib/completion/git-completion.bash"
                 data-name="v0.99.8d"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8d">v0.99.8d</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8c/contrib/completion/git-completion.bash"
                 data-name="v0.99.8c"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8c">v0.99.8c</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8b/contrib/completion/git-completion.bash"
                 data-name="v0.99.8b"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8b">v0.99.8b</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8a/contrib/completion/git-completion.bash"
                 data-name="v0.99.8a"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8a">v0.99.8a</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.8/contrib/completion/git-completion.bash"
                 data-name="v0.99.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.8">v0.99.8</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.7d/contrib/completion/git-completion.bash"
                 data-name="v0.99.7d"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.7d">v0.99.7d</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.7c/contrib/completion/git-completion.bash"
                 data-name="v0.99.7c"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.7c">v0.99.7c</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.7b/contrib/completion/git-completion.bash"
                 data-name="v0.99.7b"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.7b">v0.99.7b</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.7a/contrib/completion/git-completion.bash"
                 data-name="v0.99.7a"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.7a">v0.99.7a</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.7/contrib/completion/git-completion.bash"
                 data-name="v0.99.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.7">v0.99.7</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.6/contrib/completion/git-completion.bash"
                 data-name="v0.99.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.6">v0.99.6</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.5/contrib/completion/git-completion.bash"
                 data-name="v0.99.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.5">v0.99.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.4/contrib/completion/git-completion.bash"
                 data-name="v0.99.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.4">v0.99.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.3/contrib/completion/git-completion.bash"
                 data-name="v0.99.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.3">v0.99.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.2/contrib/completion/git-completion.bash"
                 data-name="v0.99.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.2">v0.99.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99.1/contrib/completion/git-completion.bash"
                 data-name="v0.99.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99.1">v0.99.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/v0.99/contrib/completion/git-completion.bash"
                 data-name="v0.99"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="v0.99">v0.99</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/junio-gpg-pub/contrib/completion/git-completion.bash"
                 data-name="junio-gpg-pub"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="junio-gpg-pub">junio-gpg-pub</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.18.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.18.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.18.0">gitgui-0.18.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.17.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.17.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.17.0">gitgui-0.17.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.16.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.16.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.16.0">gitgui-0.16.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.15.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.15.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.15.0">gitgui-0.15.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.14.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.14.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.14.0">gitgui-0.14.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.13.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.13.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.13.0">gitgui-0.13.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.12.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.12.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.12.0">gitgui-0.12.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.11.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.11.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.11.0">gitgui-0.11.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.10.2/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.10.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.10.2">gitgui-0.10.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.10.1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.10.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.10.1">gitgui-0.10.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.10.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.10.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.10.0">gitgui-0.10.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.9.3/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.9.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.9.3">gitgui-0.9.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.9.2/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.9.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.9.2">gitgui-0.9.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.9.1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.9.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.9.1">gitgui-0.9.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.9.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.9.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.9.0">gitgui-0.9.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.8.4/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.8.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.8.4">gitgui-0.8.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.8.3/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.8.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.8.3">gitgui-0.8.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.8.2/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.8.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.8.2">gitgui-0.8.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.8.1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.8.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.8.1">gitgui-0.8.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.8.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.8.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.8.0">gitgui-0.8.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.5/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.5">gitgui-0.7.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.4/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.4">gitgui-0.7.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.3/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.3">gitgui-0.7.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.2/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.2">gitgui-0.7.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.1">gitgui-0.7.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.0-rc1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.0-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.0-rc1">gitgui-0.7.0-rc1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.7.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.7.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.7.0">gitgui-0.7.0</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.5/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.5">gitgui-0.6.5</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.4/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.4">gitgui-0.6.4</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.3/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.3">gitgui-0.6.3</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.2/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.2">gitgui-0.6.2</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.1/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.1">gitgui-0.6.1</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/git/git/tree/gitgui-0.6.0/contrib/completion/git-completion.bash"
                 data-name="gitgui-0.6.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text js-select-button-text css-truncate-target"
                 title="gitgui-0.6.0">gitgui-0.6.0</a>
            </div> <!-- /.select-menu-item -->
        </div>

        <div class="select-menu-no-results">Nothing to show</div>
      </div> <!-- /.select-menu-list -->

    </div> <!-- /.select-menu-modal -->
  </div> <!-- /.select-menu-modal-holder -->
</div> <!-- /.select-menu -->

  <div class="breadcrumb">
    <span class='repo-root js-repo-root'><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/git/git" data-branch="master" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">git</span></a></span></span><span class="separator"> / </span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/git/git/tree/master/contrib" data-branch="master" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">contrib</span></a></span><span class="separator"> / </span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/git/git/tree/master/contrib/completion" data-branch="master" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">completion</span></a></span><span class="separator"> / </span><strong class="final-path">git-completion.bash</strong> <span class="js-zeroclipboard minibutton zeroclipboard-button" data-clipboard-text="contrib/completion/git-completion.bash" data-copied-hint="copied!" title="copy to clipboard"><span class="octicon octicon-clippy"></span></span>
  </div>
</div>



  <div class="commit file-history-tease">
    <img class="main-avatar" height="24" src="https://1.gravatar.com/avatar/750680c9dcc7d0be3ca83464a0da49d8?d=https%3A%2F%2Fidenticons.github.com%2Ff8e73a1fe6b3a5565851969c2cb234a7.png&amp;r=x&amp;s=140" width="24" />
    <span class="author"><a href="/gitster" rel="author">gitster</a></span>
    <time class="js-relative-date" datetime="2013-12-12T14:22:59-08:00" title="2013-12-12 14:22:59">December 12, 2013</time>
    <div class="commit-title">
        <a href="/git/git/commit/694a88a309c74ffeefa9a0db0396ee4c168a521c" class="message" data-pjax="true" title="Merge branch &#39;jn/scripts-updates&#39;

* jn/scripts-updates:
  remove #!interpreter line from shell libraries
  test: replace shebangs with descriptions in shell libraries
  test: make FILEMODE a lazy prereq
  contrib: remove git-p4import
  mark contributed hooks executable
  mark perl test scripts executable
  mark Windows build scripts executable">Merge branch 'jn/scripts-updates'</a>
    </div>

    <div class="participation">
      <p class="quickstat"><a href="#blob_contributors_box" rel="facebox"><strong>91</strong> contributors</a></p>
          <a class="avatar tooltipped downwards" title="gitster" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=gitster"><img height="20" src="https://1.gravatar.com/avatar/750680c9dcc7d0be3ca83464a0da49d8?d=https%3A%2F%2Fidenticons.github.com%2Ff8e73a1fe6b3a5565851969c2cb234a7.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="szeder" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=szeder"><img height="20" src="https://2.gravatar.com/avatar/1a82bb17c136cbbf8b4ae16fc05c8b8e?d=https%3A%2F%2Fidenticons.github.com%2F8aab444b40da14de62674f5995002cfc.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="spearce" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=spearce"><img height="20" src="https://2.gravatar.com/avatar/a4611f1fb34714fc54ceec3859c490f7?d=https%3A%2F%2Fidenticons.github.com%2F0629fccd9ea3789671acab64a17ed21a.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="felipec" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=felipec"><img height="20" src="https://2.gravatar.com/avatar/1bb1c1a41b92d9f18e2890c3f6d33970?d=https%3A%2F%2Fidenticons.github.com%2Fee715daa76f1b51d80343f45547be570.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="lmarlow" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=lmarlow"><img height="20" src="https://0.gravatar.com/avatar/5fc52b212d554dd8e0337bf27a5187f3?d=https%3A%2F%2Fidenticons.github.com%2F42e77b63637ab381e8be5f8318cc28a2.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="bebarino" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=bebarino"><img height="20" src="https://1.gravatar.com/avatar/4c185a1882ddf64b4f74bea339ab8f5b?d=https%3A%2F%2Fidenticons.github.com%2Fa256bb3540f67720ff261ce1da6d2cf2.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="trast" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=trast"><img height="20" src="https://0.gravatar.com/avatar/485d294f8726c4d905c09f6aa8292357?d=https%3A%2F%2Fidenticons.github.com%2F11beb4ca45aae2a1bbec3b136d2819f8.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="tpavlic" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=tpavlic"><img height="20" src="https://1.gravatar.com/avatar/235788771a6477a3cd6312ce377653c3?d=https%3A%2F%2Fidenticons.github.com%2Fb6046ddf263bc8970f3ccfe9861d81ae.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="artagnon" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=artagnon"><img height="20" src="https://1.gravatar.com/avatar/f8ccaacf28ae129491de5f4de9888873?d=https%3A%2F%2Fidenticons.github.com%2Ff1b325ca803c9e81662f52cfd88dabbe.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="tlikonen" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=tlikonen"><img height="20" src="https://0.gravatar.com/avatar/c88d06e54e6906b74c4ff584cc83de43?d=https%3A%2F%2Fidenticons.github.com%2F9c4a6ac64ace469c7d572acf8e44bf73.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="johnkeeping" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=johnkeeping"><img height="20" src="https://2.gravatar.com/avatar/aea7d8738c91da1cb0dfa9d86f2bbc47?d=https%3A%2F%2Fidenticons.github.com%2Faa278449ae8d1b01af1814fe450dfaa4.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="jrn" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=jrn"><img height="20" src="https://0.gravatar.com/avatar/292ced60b486e70de200807fc7b07e7d?d=https%3A%2F%2Fidenticons.github.com%2F6e3e4c2642e0d87bb6dd4f5bce233c19.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="jaysoffian" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=jaysoffian"><img height="20" src="https://2.gravatar.com/avatar/10f8003eaf5a7b87e8deab54dddb2b75?d=https%3A%2F%2Fidenticons.github.com%2F913c4d10ff9198596bd79d105e167b3a.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="mjg" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=mjg"><img height="20" src="https://0.gravatar.com/avatar/a2d4479df9914160837d0b974e60ce22?d=https%3A%2F%2Fidenticons.github.com%2F4807ec840a855f066543fa0ce4d032ed.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="bjorng" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=bjorng"><img height="20" src="https://2.gravatar.com/avatar/68e31f58b5edbea75f841467e5187ba4?d=https%3A%2F%2Fidenticons.github.com%2F7ebd6c32842532b6122d0b505dc3020c.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="toofishes" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=toofishes"><img height="20" src="https://2.gravatar.com/avatar/8fcb4f47c72791dd9e567cec85c762e3?d=https%3A%2F%2Fidenticons.github.com%2F58477224a538ba7fc5ac304a6c097caf.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="peff" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=peff"><img height="20" src="https://1.gravatar.com/avatar/63027897db609fdbe6ac820fa12736b9?d=https%3A%2F%2Fidenticons.github.com%2Fe0078b2675c0261aae3eed3eabfdada5.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="joshtriplett" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=joshtriplett"><img height="20" src="https://1.gravatar.com/avatar/1bd07f791d8ed5989a92790b0a1f9ea4?d=https%3A%2F%2Fidenticons.github.com%2F5e4cd0be139ac84bc2578bd0b56171b1.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="foolip" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=foolip"><img height="20" src="https://2.gravatar.com/avatar/f7c6debc698bf9bc007dd36ddccd1d83?d=https%3A%2F%2Fidenticons.github.com%2Fcd3473e1ff81344dcf9960bd6ca05f7f.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="drafnel" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=drafnel"><img height="20" src="https://1.gravatar.com/avatar/b568817d3b2a8bda0746d8ce19911d74?d=https%3A%2F%2Fidenticons.github.com%2Fb795601a075854cf6d9264e7499aff44.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="tmzullinger" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=tmzullinger"><img height="20" src="https://2.gravatar.com/avatar/f10bf4ea18a58c83f99e6d5a4b12e322?d=https%3A%2F%2Fidenticons.github.com%2F96072731bcb1298c8fcdeff3102b7fa9.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="tmatilai" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=tmatilai"><img height="20" src="https://2.gravatar.com/avatar/dc1b5e60b297c92392d3695e98b4ed53?d=https%3A%2F%2Fidenticons.github.com%2F2bb9d11bfdac13dd5cc91127c564c07f.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="davvid" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=davvid"><img height="20" src="https://2.gravatar.com/avatar/6b12b00e4f75ce5d85434cec28de4078?d=https%3A%2F%2Fidenticons.github.com%2F91a448039265fc4a83f545a4945e37a3.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="sschuberth" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=sschuberth"><img height="20" src="https://0.gravatar.com/avatar/e7eccba442d1ee3ca8e4ded89b343362?d=https%3A%2F%2Fidenticons.github.com%2F1b1ee498dd54d7dd835c9711fcdd6c45.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="Oblomov" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=Oblomov"><img height="20" src="https://0.gravatar.com/avatar/955680802bc3d50476786bb3ca9cfc52?d=https%3A%2F%2Fidenticons.github.com%2Fc913303f392ffc643f7240b180602652.png&amp;r=x&amp;s=140" width="20" /></a>
    <a class="avatar tooltipped downwards" title="dan-t" href="/git/git/commits/master/contrib/completion/git-completion.bash?author=dan-t"><img height="20" src="https://0.gravatar.com/avatar/4bda64711485d4f380c5d884f90b6dfb?d=https%3A%2F%2Fidenticons.github.com%2F20643cd7efd7b3893cf2a3a0c517e4d8.png&amp;r=x&amp;s=140" width="20" /></a>

      <a href="#blob_contributors_box" rel="facebox" class="others-text">and others.</a>

    </div>
    <div id="blob_contributors_box" style="display:none">
      <h2 class="facebox-header">Users who have contributed to this file</h2>
      <ul class="facebox-user-list">
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/750680c9dcc7d0be3ca83464a0da49d8?d=https%3A%2F%2Fidenticons.github.com%2Ff8e73a1fe6b3a5565851969c2cb234a7.png&amp;r=x&amp;s=140" width="24" />
            <a href="/gitster">gitster</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/1a82bb17c136cbbf8b4ae16fc05c8b8e?d=https%3A%2F%2Fidenticons.github.com%2F8aab444b40da14de62674f5995002cfc.png&amp;r=x&amp;s=140" width="24" />
            <a href="/szeder">szeder</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/a4611f1fb34714fc54ceec3859c490f7?d=https%3A%2F%2Fidenticons.github.com%2F0629fccd9ea3789671acab64a17ed21a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/spearce">spearce</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/1bb1c1a41b92d9f18e2890c3f6d33970?d=https%3A%2F%2Fidenticons.github.com%2Fee715daa76f1b51d80343f45547be570.png&amp;r=x&amp;s=140" width="24" />
            <a href="/felipec">felipec</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/5fc52b212d554dd8e0337bf27a5187f3?d=https%3A%2F%2Fidenticons.github.com%2F42e77b63637ab381e8be5f8318cc28a2.png&amp;r=x&amp;s=140" width="24" />
            <a href="/lmarlow">lmarlow</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/4c185a1882ddf64b4f74bea339ab8f5b?d=https%3A%2F%2Fidenticons.github.com%2Fa256bb3540f67720ff261ce1da6d2cf2.png&amp;r=x&amp;s=140" width="24" />
            <a href="/bebarino">bebarino</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/485d294f8726c4d905c09f6aa8292357?d=https%3A%2F%2Fidenticons.github.com%2F11beb4ca45aae2a1bbec3b136d2819f8.png&amp;r=x&amp;s=140" width="24" />
            <a href="/trast">trast</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/235788771a6477a3cd6312ce377653c3?d=https%3A%2F%2Fidenticons.github.com%2Fb6046ddf263bc8970f3ccfe9861d81ae.png&amp;r=x&amp;s=140" width="24" />
            <a href="/tpavlic">tpavlic</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/f8ccaacf28ae129491de5f4de9888873?d=https%3A%2F%2Fidenticons.github.com%2Ff1b325ca803c9e81662f52cfd88dabbe.png&amp;r=x&amp;s=140" width="24" />
            <a href="/artagnon">artagnon</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/c88d06e54e6906b74c4ff584cc83de43?d=https%3A%2F%2Fidenticons.github.com%2F9c4a6ac64ace469c7d572acf8e44bf73.png&amp;r=x&amp;s=140" width="24" />
            <a href="/tlikonen">tlikonen</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/aea7d8738c91da1cb0dfa9d86f2bbc47?d=https%3A%2F%2Fidenticons.github.com%2Faa278449ae8d1b01af1814fe450dfaa4.png&amp;r=x&amp;s=140" width="24" />
            <a href="/johnkeeping">johnkeeping</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/292ced60b486e70de200807fc7b07e7d?d=https%3A%2F%2Fidenticons.github.com%2F6e3e4c2642e0d87bb6dd4f5bce233c19.png&amp;r=x&amp;s=140" width="24" />
            <a href="/jrn">jrn</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/10f8003eaf5a7b87e8deab54dddb2b75?d=https%3A%2F%2Fidenticons.github.com%2F913c4d10ff9198596bd79d105e167b3a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/jaysoffian">jaysoffian</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/a2d4479df9914160837d0b974e60ce22?d=https%3A%2F%2Fidenticons.github.com%2F4807ec840a855f066543fa0ce4d032ed.png&amp;r=x&amp;s=140" width="24" />
            <a href="/mjg">mjg</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/68e31f58b5edbea75f841467e5187ba4?d=https%3A%2F%2Fidenticons.github.com%2F7ebd6c32842532b6122d0b505dc3020c.png&amp;r=x&amp;s=140" width="24" />
            <a href="/bjorng">bjorng</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/8fcb4f47c72791dd9e567cec85c762e3?d=https%3A%2F%2Fidenticons.github.com%2F58477224a538ba7fc5ac304a6c097caf.png&amp;r=x&amp;s=140" width="24" />
            <a href="/toofishes">toofishes</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/63027897db609fdbe6ac820fa12736b9?d=https%3A%2F%2Fidenticons.github.com%2Fe0078b2675c0261aae3eed3eabfdada5.png&amp;r=x&amp;s=140" width="24" />
            <a href="/peff">peff</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/1bd07f791d8ed5989a92790b0a1f9ea4?d=https%3A%2F%2Fidenticons.github.com%2F5e4cd0be139ac84bc2578bd0b56171b1.png&amp;r=x&amp;s=140" width="24" />
            <a href="/joshtriplett">joshtriplett</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/f7c6debc698bf9bc007dd36ddccd1d83?d=https%3A%2F%2Fidenticons.github.com%2Fcd3473e1ff81344dcf9960bd6ca05f7f.png&amp;r=x&amp;s=140" width="24" />
            <a href="/foolip">foolip</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/b568817d3b2a8bda0746d8ce19911d74?d=https%3A%2F%2Fidenticons.github.com%2Fb795601a075854cf6d9264e7499aff44.png&amp;r=x&amp;s=140" width="24" />
            <a href="/drafnel">drafnel</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/f10bf4ea18a58c83f99e6d5a4b12e322?d=https%3A%2F%2Fidenticons.github.com%2F96072731bcb1298c8fcdeff3102b7fa9.png&amp;r=x&amp;s=140" width="24" />
            <a href="/tmzullinger">tmzullinger</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/dc1b5e60b297c92392d3695e98b4ed53?d=https%3A%2F%2Fidenticons.github.com%2F2bb9d11bfdac13dd5cc91127c564c07f.png&amp;r=x&amp;s=140" width="24" />
            <a href="/tmatilai">tmatilai</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/6b12b00e4f75ce5d85434cec28de4078?d=https%3A%2F%2Fidenticons.github.com%2F91a448039265fc4a83f545a4945e37a3.png&amp;r=x&amp;s=140" width="24" />
            <a href="/davvid">davvid</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/e7eccba442d1ee3ca8e4ded89b343362?d=https%3A%2F%2Fidenticons.github.com%2F1b1ee498dd54d7dd835c9711fcdd6c45.png&amp;r=x&amp;s=140" width="24" />
            <a href="/sschuberth">sschuberth</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/955680802bc3d50476786bb3ca9cfc52?d=https%3A%2F%2Fidenticons.github.com%2Fc913303f392ffc643f7240b180602652.png&amp;r=x&amp;s=140" width="24" />
            <a href="/Oblomov">Oblomov</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/4bda64711485d4f380c5d884f90b6dfb?d=https%3A%2F%2Fidenticons.github.com%2F20643cd7efd7b3893cf2a3a0c517e4d8.png&amp;r=x&amp;s=140" width="24" />
            <a href="/dan-t">dan-t</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/6451ee8093c9cedc94f6c813b4dde2c5?d=https%3A%2F%2Fidenticons.github.com%2Fd14220ee66aeec73c49038385428ec4c.png&amp;r=x&amp;s=140" width="24" />
            <a href="/kballard">kballard</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/881c7ff5a0dc2a30e27ba38c06d62f52?d=https%3A%2F%2Fidenticons.github.com%2Fe1b97c787a5677efa5eba575c41e8688.png&amp;r=x&amp;s=140" width="24" />
            <a href="/moy">moy</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/3f040653a47615de7660f0ec03f39f2c?d=https%3A%2F%2Fidenticons.github.com%2Fc5812b152bd3f9b0229b9faa3672579d.png&amp;r=x&amp;s=140" width="24" />
            <a href="/kraai">kraai</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/64b20e74c613dede455f69d6a8f30a76?d=https%3A%2F%2Fidenticons.github.com%2F3388c1df29818f993c83fcc32d3d7ec5.png&amp;r=x&amp;s=140" width="24" />
            <a href="/awde">awde</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/2ba36f553521381741fcc3f87a48ba04?d=https%3A%2F%2Fidenticons.github.com%2F6bc49d1ca96d2e14eb7b3c9355d4e1c0.png&amp;r=x&amp;s=140" width="24" />
            <a href="/MarkLodato">MarkLodato</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/0b2c894697b915d1a3a81025501b3893?d=https%3A%2F%2Fidenticons.github.com%2Fcfa5301358b9fcbe7aa45b1ceea088c6.png&amp;r=x&amp;s=140" width="24" />
            <a href="/mstormo">mstormo</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/5f51a8aed80f7259d7653ff6845257d5?d=https%3A%2F%2Fidenticons.github.com%2F825ab77fe4eb3419db2fc9c6ceff7146.png&amp;r=x&amp;s=140" width="24" />
            <a href="/neoeinstein">neoeinstein</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/e0d162978e4e6db04a96a4eee77c1c30?d=https%3A%2F%2Fidenticons.github.com%2F60fc0162b7337c8eaa8bd2492f2bd13a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/amhk">amhk</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/81b889b8ad092c080bd0de0c2cde8b2d?d=https%3A%2F%2Fidenticons.github.com%2Fb55b74227a67cc0f3e668c9cc29cd499.png&amp;r=x&amp;s=140" width="24" />
            <a href="/martinvonz">martinvonz</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/8b5a0fb455aa05cd79ec7f25f5d1281f?d=https%3A%2F%2Fidenticons.github.com%2F4de81d9105c85bca6e6e4666e6dd536a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/matthiask">matthiask</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/100c4331fc50b6e8f003caf0eaa231ce?d=https%3A%2F%2Fidenticons.github.com%2Ffa786d68957fd7fa2facd33e8fd20637.png&amp;r=x&amp;s=140" width="24" />
            <a href="/mark987">mark987</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/6c3f54f62cfa6d9a1f76ccd9e14777f2?d=https%3A%2F%2Fidenticons.github.com%2Fc776f1e313a89cdcc6d8bc6925be4df6.png&amp;r=x&amp;s=140" width="24" />
            <a href="/kevinmcconnell">kevinmcconnell</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/e85558061ca47ddfe864e8fcfbfc8c02?d=https%3A%2F%2Fidenticons.github.com%2F7f56061fb30e16364c61cc7fc0a8b4e9.png&amp;r=x&amp;s=140" width="24" />
            <a href="/namhyung">namhyung</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/d816531140e37f01f364122aadc361f3?d=https%3A%2F%2Fidenticons.github.com%2F4b13504eff30b9bc375ea8dab99302d2.png&amp;r=x&amp;s=140" width="24" />
            <a href="/pasky">pasky</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/7ec152ffc75b7667caa9e83875455800?d=https%3A%2F%2Fidenticons.github.com%2Fbb889964ac14ceb1b9771a8c18aef803.png&amp;r=x&amp;s=140" width="24" />
            <a href="/jre">jre</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/3b4a0bbb261dd20a5334d9de4212c222?d=https%3A%2F%2Fidenticons.github.com%2F5f2c22cb4a5380af7ca75622a6426917.png&amp;r=x&amp;s=140" width="24" />
            <a href="/pclouds">pclouds</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/f50876dc489df65c750c9fa32f9dd33e?d=https%3A%2F%2Fidenticons.github.com%2Fe3d919894eae205571f75954704bf5a1.png&amp;r=x&amp;s=140" width="24" />
            <a href="/keszybz">keszybz</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/68cb11dd951afa51dc3a612d6535e4f5?d=https%3A%2F%2Fidenticons.github.com%2Fa894588c9dc670e2f2a5d2f521faf7f9.png&amp;r=x&amp;s=140" width="24" />
            <a href="/jlehmann">jlehmann</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/e27ffc80a05a6beadf1c10d03227a57a?d=https%3A%2F%2Fidenticons.github.com%2F08d502822e25cefc71182b00ddda8646.png&amp;r=x&amp;s=140" width="24" />
            <a href="/petervanderdoes">petervanderdoes</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/b8c5bbbe74f020d88486f9f8098fef80?d=https%3A%2F%2Fidenticons.github.com%2F2c835908abb9ee423ac025e84663066a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/j16sdiz">j16sdiz</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/79e8983cfc1915be2f1d22a8aeef9ed5?d=https%3A%2F%2Fidenticons.github.com%2F5e05cab170c3d7fae52c2bb15163538d.png&amp;r=x&amp;s=140" width="24" />
            <a href="/mantiz">mantiz</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/80a17685b32a6ba432f45c20cbe1c2e4?d=https%3A%2F%2Fidenticons.github.com%2F596952edb4cbdb0e718d522cbf0cffd0.png&amp;r=x&amp;s=140" width="24" />
            <a href="/icomfort">icomfort</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/ee1f16d50e9a8cede09b98b16d2d2759?d=https%3A%2F%2Fidenticons.github.com%2F118f120e664e30d7394651a361a902f2.png&amp;r=x&amp;s=140" width="24" />
            <a href="/rctay">rctay</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/95f2c756cb967bcde26a20c0430a1df4?d=https%3A%2F%2Fidenticons.github.com%2F4c58929be07e6b830daccf2144f77125.png&amp;r=x&amp;s=140" width="24" />
            <a href="/andyparkins">andyparkins</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/32add678ed8bb5d57eedd0d9529598f3?d=https%3A%2F%2Fidenticons.github.com%2F9a48eb4ad2962275cb9d947410994356.png&amp;r=x&amp;s=140" width="24" />
            <a href="/razeh">razeh</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/fab599a96f418b7b52427e568efc1fa3?d=https%3A%2F%2Fidenticons.github.com%2Fc8cc6e90ccbff44c9cee23611711cdc4.png&amp;r=x&amp;s=140" width="24" />
            <a href="/jonas">jonas</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/ae572d3430ac024b649162ca52ce5f5b?d=https%3A%2F%2Fidenticons.github.com%2Fbc55d3363ee659d6ab6c908b932c7705.png&amp;r=x&amp;s=140" width="24" />
            <a href="/robinrosenberg">robinrosenberg</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/c19cbf1e1ba0f38bade96e63d3518618?d=https%3A%2F%2Fidenticons.github.com%2F9e769eec32a6e8784289f08b9b1faf7a.png&amp;r=x&amp;s=140" width="24" />
            <a href="/erickmattos">erickmattos</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/d6af3d9442783aa00ef1e5d7772f997d?d=https%3A%2F%2Fidenticons.github.com%2F95f1d47eb81295ff9866b9f7291894c1.png&amp;r=x&amp;s=140" width="24" />
            <a href="/dylanahsmith">dylanahsmith</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/cbb24c9af2bec4e193c0560e159c234e?d=https%3A%2F%2Fidenticons.github.com%2Fdc78a04dfc111836a818427ac7097def.png&amp;r=x&amp;s=140" width="24" />
            <a href="/sbeyer">sbeyer</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/9375a9529679f1b42b567a640d775e7d?d=https%3A%2F%2Fidenticons.github.com%2F7cbbc409ec990f19c78c75bd1e06f215.png&amp;r=x&amp;s=140" width="24" />
            <a href="/schacon">schacon</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/1da77a3f953f08fb758bc9cb19ae42bb?d=https%3A%2F%2Fidenticons.github.com%2Fb709742d89f8d9a642a31abd93dfd49d.png&amp;r=x&amp;s=140" width="24" />
            <a href="/randomguy3">randomguy3</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/c8e9b74785f7f4361e0573a0ad4cc2b4?d=https%3A%2F%2Fidenticons.github.com%2Fbb965766540b75c505520ea5ccc42510.png&amp;r=x&amp;s=140" width="24" />
            <a href="/dstosberg">dstosberg</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/9042bc4e33fec719f490547d1097fc4b?d=https%3A%2F%2Fidenticons.github.com%2F94eed871999707901614b979ac321a07.png&amp;r=x&amp;s=140" width="24" />
            <a href="/hartwork">hartwork</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/83b15544816930ad38c887ad59fd5767?d=https%3A%2F%2Fidenticons.github.com%2F185e65bc40581880c4f2c82958de8cfe.png&amp;r=x&amp;s=140" width="24" />
            <a href="/juretta">juretta</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/023e1295851b018af03706f391b76931?d=https%3A%2F%2Fidenticons.github.com%2F4b1d46c6ab16ff5ab0be9a112d6f0b53.png&amp;r=x&amp;s=140" width="24" />
            <a href="/carlosmn">carlosmn</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://1.gravatar.com/avatar/a04e891f882ab39b6b79b9c2603c1394?d=https%3A%2F%2Fidenticons.github.com%2Fb4d0509ed4a1714466204c0b30de3f62.png&amp;r=x&amp;s=140" width="24" />
            <a href="/bonzini">bonzini</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/7fe6efc14e21da46e0b2fa036d6966a4?d=https%3A%2F%2Fidenticons.github.com%2F88c040adb393832c87914347cc2afc3f.png&amp;r=x&amp;s=140" width="24" />
            <a href="/snaewe">snaewe</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/20764c70330022de12b573848ee65092?d=https%3A%2F%2Fidenticons.github.com%2Fa18e0e1908b473f4106e816f874f15ac.png&amp;r=x&amp;s=140" width="24" />
            <a href="/sunshineco">sunshineco</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/e81edff3af564b86f4c9d780a8023299?d=https%3A%2F%2Fidenticons.github.com%2Fed8ed7dd7e0836bc79f7543fca7de56f.png&amp;r=x&amp;s=140" width="24" />
            <a href="/tomprince">tomprince</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://2.gravatar.com/avatar/1b1d983e092b649de25c520a40d325fc?d=https%3A%2F%2Fidenticons.github.com%2F85690f81aadc1749175c187784afc9ee.png&amp;r=x&amp;s=140" width="24" />
            <a href="/richq">richq</a>
          </li>
          <li class="facebox-user-list-item">
            <img height="24" src="https://0.gravatar.com/avatar/c2938f05cefad961fec000e7734c73ac?d=https%3A%2F%2Fidenticons.github.com%2Fededb77aa92ee371e6ca5b555a8b718c.png&amp;r=x&amp;s=140" width="24" />
            <a href="/dscho">dscho</a>
          </li>
      </ul>
    </div>
  </div>

<div id="files" class="bubble">
  <div class="file">
    <div class="meta">
      <div class="info">
        <span class="icon"><b class="octicon octicon-file-text"></b></span>
        <span class="mode" title="File Mode">file</span>
          <span>2658 lines (2485 sloc)</span>
        <span>53.996 kb</span>
      </div>
      <div class="actions">
        <div class="button-group">
              <a class="minibutton disabled tooltipped leftwards" href="#"
                 title="You must be signed in to make or propose changes">Edit</a>
          <a href="/git/git/raw/master/contrib/completion/git-completion.bash" class="button minibutton " id="raw-url">Raw</a>
            <a href="/git/git/blame/master/contrib/completion/git-completion.bash" class="button minibutton ">Blame</a>
          <a href="/git/git/commits/master/contrib/completion/git-completion.bash" class="button minibutton " rel="nofollow">History</a>
        </div><!-- /.button-group -->
          <a class="minibutton danger disabled empty-icon tooltipped leftwards" href="#"
             title="You must be signed in to make or propose changes">
          Delete
        </a>
      </div><!-- /.actions -->

    </div>
        <div class="blob-wrapper data type-shell js-blob-data">
        <table class="file-code file-diff">
          <tr class="file-code-line">
            <td class="blob-line-nums">
              <span id="L1" rel="#L1">1</span>
<span id="L2" rel="#L2">2</span>
<span id="L3" rel="#L3">3</span>
<span id="L4" rel="#L4">4</span>
<span id="L5" rel="#L5">5</span>
<span id="L6" rel="#L6">6</span>
<span id="L7" rel="#L7">7</span>
<span id="L8" rel="#L8">8</span>
<span id="L9" rel="#L9">9</span>
<span id="L10" rel="#L10">10</span>
<span id="L11" rel="#L11">11</span>
<span id="L12" rel="#L12">12</span>
<span id="L13" rel="#L13">13</span>
<span id="L14" rel="#L14">14</span>
<span id="L15" rel="#L15">15</span>
<span id="L16" rel="#L16">16</span>
<span id="L17" rel="#L17">17</span>
<span id="L18" rel="#L18">18</span>
<span id="L19" rel="#L19">19</span>
<span id="L20" rel="#L20">20</span>
<span id="L21" rel="#L21">21</span>
<span id="L22" rel="#L22">22</span>
<span id="L23" rel="#L23">23</span>
<span id="L24" rel="#L24">24</span>
<span id="L25" rel="#L25">25</span>
<span id="L26" rel="#L26">26</span>
<span id="L27" rel="#L27">27</span>
<span id="L28" rel="#L28">28</span>
<span id="L29" rel="#L29">29</span>
<span id="L30" rel="#L30">30</span>
<span id="L31" rel="#L31">31</span>
<span id="L32" rel="#L32">32</span>
<span id="L33" rel="#L33">33</span>
<span id="L34" rel="#L34">34</span>
<span id="L35" rel="#L35">35</span>
<span id="L36" rel="#L36">36</span>
<span id="L37" rel="#L37">37</span>
<span id="L38" rel="#L38">38</span>
<span id="L39" rel="#L39">39</span>
<span id="L40" rel="#L40">40</span>
<span id="L41" rel="#L41">41</span>
<span id="L42" rel="#L42">42</span>
<span id="L43" rel="#L43">43</span>
<span id="L44" rel="#L44">44</span>
<span id="L45" rel="#L45">45</span>
<span id="L46" rel="#L46">46</span>
<span id="L47" rel="#L47">47</span>
<span id="L48" rel="#L48">48</span>
<span id="L49" rel="#L49">49</span>
<span id="L50" rel="#L50">50</span>
<span id="L51" rel="#L51">51</span>
<span id="L52" rel="#L52">52</span>
<span id="L53" rel="#L53">53</span>
<span id="L54" rel="#L54">54</span>
<span id="L55" rel="#L55">55</span>
<span id="L56" rel="#L56">56</span>
<span id="L57" rel="#L57">57</span>
<span id="L58" rel="#L58">58</span>
<span id="L59" rel="#L59">59</span>
<span id="L60" rel="#L60">60</span>
<span id="L61" rel="#L61">61</span>
<span id="L62" rel="#L62">62</span>
<span id="L63" rel="#L63">63</span>
<span id="L64" rel="#L64">64</span>
<span id="L65" rel="#L65">65</span>
<span id="L66" rel="#L66">66</span>
<span id="L67" rel="#L67">67</span>
<span id="L68" rel="#L68">68</span>
<span id="L69" rel="#L69">69</span>
<span id="L70" rel="#L70">70</span>
<span id="L71" rel="#L71">71</span>
<span id="L72" rel="#L72">72</span>
<span id="L73" rel="#L73">73</span>
<span id="L74" rel="#L74">74</span>
<span id="L75" rel="#L75">75</span>
<span id="L76" rel="#L76">76</span>
<span id="L77" rel="#L77">77</span>
<span id="L78" rel="#L78">78</span>
<span id="L79" rel="#L79">79</span>
<span id="L80" rel="#L80">80</span>
<span id="L81" rel="#L81">81</span>
<span id="L82" rel="#L82">82</span>
<span id="L83" rel="#L83">83</span>
<span id="L84" rel="#L84">84</span>
<span id="L85" rel="#L85">85</span>
<span id="L86" rel="#L86">86</span>
<span id="L87" rel="#L87">87</span>
<span id="L88" rel="#L88">88</span>
<span id="L89" rel="#L89">89</span>
<span id="L90" rel="#L90">90</span>
<span id="L91" rel="#L91">91</span>
<span id="L92" rel="#L92">92</span>
<span id="L93" rel="#L93">93</span>
<span id="L94" rel="#L94">94</span>
<span id="L95" rel="#L95">95</span>
<span id="L96" rel="#L96">96</span>
<span id="L97" rel="#L97">97</span>
<span id="L98" rel="#L98">98</span>
<span id="L99" rel="#L99">99</span>
<span id="L100" rel="#L100">100</span>
<span id="L101" rel="#L101">101</span>
<span id="L102" rel="#L102">102</span>
<span id="L103" rel="#L103">103</span>
<span id="L104" rel="#L104">104</span>
<span id="L105" rel="#L105">105</span>
<span id="L106" rel="#L106">106</span>
<span id="L107" rel="#L107">107</span>
<span id="L108" rel="#L108">108</span>
<span id="L109" rel="#L109">109</span>
<span id="L110" rel="#L110">110</span>
<span id="L111" rel="#L111">111</span>
<span id="L112" rel="#L112">112</span>
<span id="L113" rel="#L113">113</span>
<span id="L114" rel="#L114">114</span>
<span id="L115" rel="#L115">115</span>
<span id="L116" rel="#L116">116</span>
<span id="L117" rel="#L117">117</span>
<span id="L118" rel="#L118">118</span>
<span id="L119" rel="#L119">119</span>
<span id="L120" rel="#L120">120</span>
<span id="L121" rel="#L121">121</span>
<span id="L122" rel="#L122">122</span>
<span id="L123" rel="#L123">123</span>
<span id="L124" rel="#L124">124</span>
<span id="L125" rel="#L125">125</span>
<span id="L126" rel="#L126">126</span>
<span id="L127" rel="#L127">127</span>
<span id="L128" rel="#L128">128</span>
<span id="L129" rel="#L129">129</span>
<span id="L130" rel="#L130">130</span>
<span id="L131" rel="#L131">131</span>
<span id="L132" rel="#L132">132</span>
<span id="L133" rel="#L133">133</span>
<span id="L134" rel="#L134">134</span>
<span id="L135" rel="#L135">135</span>
<span id="L136" rel="#L136">136</span>
<span id="L137" rel="#L137">137</span>
<span id="L138" rel="#L138">138</span>
<span id="L139" rel="#L139">139</span>
<span id="L140" rel="#L140">140</span>
<span id="L141" rel="#L141">141</span>
<span id="L142" rel="#L142">142</span>
<span id="L143" rel="#L143">143</span>
<span id="L144" rel="#L144">144</span>
<span id="L145" rel="#L145">145</span>
<span id="L146" rel="#L146">146</span>
<span id="L147" rel="#L147">147</span>
<span id="L148" rel="#L148">148</span>
<span id="L149" rel="#L149">149</span>
<span id="L150" rel="#L150">150</span>
<span id="L151" rel="#L151">151</span>
<span id="L152" rel="#L152">152</span>
<span id="L153" rel="#L153">153</span>
<span id="L154" rel="#L154">154</span>
<span id="L155" rel="#L155">155</span>
<span id="L156" rel="#L156">156</span>
<span id="L157" rel="#L157">157</span>
<span id="L158" rel="#L158">158</span>
<span id="L159" rel="#L159">159</span>
<span id="L160" rel="#L160">160</span>
<span id="L161" rel="#L161">161</span>
<span id="L162" rel="#L162">162</span>
<span id="L163" rel="#L163">163</span>
<span id="L164" rel="#L164">164</span>
<span id="L165" rel="#L165">165</span>
<span id="L166" rel="#L166">166</span>
<span id="L167" rel="#L167">167</span>
<span id="L168" rel="#L168">168</span>
<span id="L169" rel="#L169">169</span>
<span id="L170" rel="#L170">170</span>
<span id="L171" rel="#L171">171</span>
<span id="L172" rel="#L172">172</span>
<span id="L173" rel="#L173">173</span>
<span id="L174" rel="#L174">174</span>
<span id="L175" rel="#L175">175</span>
<span id="L176" rel="#L176">176</span>
<span id="L177" rel="#L177">177</span>
<span id="L178" rel="#L178">178</span>
<span id="L179" rel="#L179">179</span>
<span id="L180" rel="#L180">180</span>
<span id="L181" rel="#L181">181</span>
<span id="L182" rel="#L182">182</span>
<span id="L183" rel="#L183">183</span>
<span id="L184" rel="#L184">184</span>
<span id="L185" rel="#L185">185</span>
<span id="L186" rel="#L186">186</span>
<span id="L187" rel="#L187">187</span>
<span id="L188" rel="#L188">188</span>
<span id="L189" rel="#L189">189</span>
<span id="L190" rel="#L190">190</span>
<span id="L191" rel="#L191">191</span>
<span id="L192" rel="#L192">192</span>
<span id="L193" rel="#L193">193</span>
<span id="L194" rel="#L194">194</span>
<span id="L195" rel="#L195">195</span>
<span id="L196" rel="#L196">196</span>
<span id="L197" rel="#L197">197</span>
<span id="L198" rel="#L198">198</span>
<span id="L199" rel="#L199">199</span>
<span id="L200" rel="#L200">200</span>
<span id="L201" rel="#L201">201</span>
<span id="L202" rel="#L202">202</span>
<span id="L203" rel="#L203">203</span>
<span id="L204" rel="#L204">204</span>
<span id="L205" rel="#L205">205</span>
<span id="L206" rel="#L206">206</span>
<span id="L207" rel="#L207">207</span>
<span id="L208" rel="#L208">208</span>
<span id="L209" rel="#L209">209</span>
<span id="L210" rel="#L210">210</span>
<span id="L211" rel="#L211">211</span>
<span id="L212" rel="#L212">212</span>
<span id="L213" rel="#L213">213</span>
<span id="L214" rel="#L214">214</span>
<span id="L215" rel="#L215">215</span>
<span id="L216" rel="#L216">216</span>
<span id="L217" rel="#L217">217</span>
<span id="L218" rel="#L218">218</span>
<span id="L219" rel="#L219">219</span>
<span id="L220" rel="#L220">220</span>
<span id="L221" rel="#L221">221</span>
<span id="L222" rel="#L222">222</span>
<span id="L223" rel="#L223">223</span>
<span id="L224" rel="#L224">224</span>
<span id="L225" rel="#L225">225</span>
<span id="L226" rel="#L226">226</span>
<span id="L227" rel="#L227">227</span>
<span id="L228" rel="#L228">228</span>
<span id="L229" rel="#L229">229</span>
<span id="L230" rel="#L230">230</span>
<span id="L231" rel="#L231">231</span>
<span id="L232" rel="#L232">232</span>
<span id="L233" rel="#L233">233</span>
<span id="L234" rel="#L234">234</span>
<span id="L235" rel="#L235">235</span>
<span id="L236" rel="#L236">236</span>
<span id="L237" rel="#L237">237</span>
<span id="L238" rel="#L238">238</span>
<span id="L239" rel="#L239">239</span>
<span id="L240" rel="#L240">240</span>
<span id="L241" rel="#L241">241</span>
<span id="L242" rel="#L242">242</span>
<span id="L243" rel="#L243">243</span>
<span id="L244" rel="#L244">244</span>
<span id="L245" rel="#L245">245</span>
<span id="L246" rel="#L246">246</span>
<span id="L247" rel="#L247">247</span>
<span id="L248" rel="#L248">248</span>
<span id="L249" rel="#L249">249</span>
<span id="L250" rel="#L250">250</span>
<span id="L251" rel="#L251">251</span>
<span id="L252" rel="#L252">252</span>
<span id="L253" rel="#L253">253</span>
<span id="L254" rel="#L254">254</span>
<span id="L255" rel="#L255">255</span>
<span id="L256" rel="#L256">256</span>
<span id="L257" rel="#L257">257</span>
<span id="L258" rel="#L258">258</span>
<span id="L259" rel="#L259">259</span>
<span id="L260" rel="#L260">260</span>
<span id="L261" rel="#L261">261</span>
<span id="L262" rel="#L262">262</span>
<span id="L263" rel="#L263">263</span>
<span id="L264" rel="#L264">264</span>
<span id="L265" rel="#L265">265</span>
<span id="L266" rel="#L266">266</span>
<span id="L267" rel="#L267">267</span>
<span id="L268" rel="#L268">268</span>
<span id="L269" rel="#L269">269</span>
<span id="L270" rel="#L270">270</span>
<span id="L271" rel="#L271">271</span>
<span id="L272" rel="#L272">272</span>
<span id="L273" rel="#L273">273</span>
<span id="L274" rel="#L274">274</span>
<span id="L275" rel="#L275">275</span>
<span id="L276" rel="#L276">276</span>
<span id="L277" rel="#L277">277</span>
<span id="L278" rel="#L278">278</span>
<span id="L279" rel="#L279">279</span>
<span id="L280" rel="#L280">280</span>
<span id="L281" rel="#L281">281</span>
<span id="L282" rel="#L282">282</span>
<span id="L283" rel="#L283">283</span>
<span id="L284" rel="#L284">284</span>
<span id="L285" rel="#L285">285</span>
<span id="L286" rel="#L286">286</span>
<span id="L287" rel="#L287">287</span>
<span id="L288" rel="#L288">288</span>
<span id="L289" rel="#L289">289</span>
<span id="L290" rel="#L290">290</span>
<span id="L291" rel="#L291">291</span>
<span id="L292" rel="#L292">292</span>
<span id="L293" rel="#L293">293</span>
<span id="L294" rel="#L294">294</span>
<span id="L295" rel="#L295">295</span>
<span id="L296" rel="#L296">296</span>
<span id="L297" rel="#L297">297</span>
<span id="L298" rel="#L298">298</span>
<span id="L299" rel="#L299">299</span>
<span id="L300" rel="#L300">300</span>
<span id="L301" rel="#L301">301</span>
<span id="L302" rel="#L302">302</span>
<span id="L303" rel="#L303">303</span>
<span id="L304" rel="#L304">304</span>
<span id="L305" rel="#L305">305</span>
<span id="L306" rel="#L306">306</span>
<span id="L307" rel="#L307">307</span>
<span id="L308" rel="#L308">308</span>
<span id="L309" rel="#L309">309</span>
<span id="L310" rel="#L310">310</span>
<span id="L311" rel="#L311">311</span>
<span id="L312" rel="#L312">312</span>
<span id="L313" rel="#L313">313</span>
<span id="L314" rel="#L314">314</span>
<span id="L315" rel="#L315">315</span>
<span id="L316" rel="#L316">316</span>
<span id="L317" rel="#L317">317</span>
<span id="L318" rel="#L318">318</span>
<span id="L319" rel="#L319">319</span>
<span id="L320" rel="#L320">320</span>
<span id="L321" rel="#L321">321</span>
<span id="L322" rel="#L322">322</span>
<span id="L323" rel="#L323">323</span>
<span id="L324" rel="#L324">324</span>
<span id="L325" rel="#L325">325</span>
<span id="L326" rel="#L326">326</span>
<span id="L327" rel="#L327">327</span>
<span id="L328" rel="#L328">328</span>
<span id="L329" rel="#L329">329</span>
<span id="L330" rel="#L330">330</span>
<span id="L331" rel="#L331">331</span>
<span id="L332" rel="#L332">332</span>
<span id="L333" rel="#L333">333</span>
<span id="L334" rel="#L334">334</span>
<span id="L335" rel="#L335">335</span>
<span id="L336" rel="#L336">336</span>
<span id="L337" rel="#L337">337</span>
<span id="L338" rel="#L338">338</span>
<span id="L339" rel="#L339">339</span>
<span id="L340" rel="#L340">340</span>
<span id="L341" rel="#L341">341</span>
<span id="L342" rel="#L342">342</span>
<span id="L343" rel="#L343">343</span>
<span id="L344" rel="#L344">344</span>
<span id="L345" rel="#L345">345</span>
<span id="L346" rel="#L346">346</span>
<span id="L347" rel="#L347">347</span>
<span id="L348" rel="#L348">348</span>
<span id="L349" rel="#L349">349</span>
<span id="L350" rel="#L350">350</span>
<span id="L351" rel="#L351">351</span>
<span id="L352" rel="#L352">352</span>
<span id="L353" rel="#L353">353</span>
<span id="L354" rel="#L354">354</span>
<span id="L355" rel="#L355">355</span>
<span id="L356" rel="#L356">356</span>
<span id="L357" rel="#L357">357</span>
<span id="L358" rel="#L358">358</span>
<span id="L359" rel="#L359">359</span>
<span id="L360" rel="#L360">360</span>
<span id="L361" rel="#L361">361</span>
<span id="L362" rel="#L362">362</span>
<span id="L363" rel="#L363">363</span>
<span id="L364" rel="#L364">364</span>
<span id="L365" rel="#L365">365</span>
<span id="L366" rel="#L366">366</span>
<span id="L367" rel="#L367">367</span>
<span id="L368" rel="#L368">368</span>
<span id="L369" rel="#L369">369</span>
<span id="L370" rel="#L370">370</span>
<span id="L371" rel="#L371">371</span>
<span id="L372" rel="#L372">372</span>
<span id="L373" rel="#L373">373</span>
<span id="L374" rel="#L374">374</span>
<span id="L375" rel="#L375">375</span>
<span id="L376" rel="#L376">376</span>
<span id="L377" rel="#L377">377</span>
<span id="L378" rel="#L378">378</span>
<span id="L379" rel="#L379">379</span>
<span id="L380" rel="#L380">380</span>
<span id="L381" rel="#L381">381</span>
<span id="L382" rel="#L382">382</span>
<span id="L383" rel="#L383">383</span>
<span id="L384" rel="#L384">384</span>
<span id="L385" rel="#L385">385</span>
<span id="L386" rel="#L386">386</span>
<span id="L387" rel="#L387">387</span>
<span id="L388" rel="#L388">388</span>
<span id="L389" rel="#L389">389</span>
<span id="L390" rel="#L390">390</span>
<span id="L391" rel="#L391">391</span>
<span id="L392" rel="#L392">392</span>
<span id="L393" rel="#L393">393</span>
<span id="L394" rel="#L394">394</span>
<span id="L395" rel="#L395">395</span>
<span id="L396" rel="#L396">396</span>
<span id="L397" rel="#L397">397</span>
<span id="L398" rel="#L398">398</span>
<span id="L399" rel="#L399">399</span>
<span id="L400" rel="#L400">400</span>
<span id="L401" rel="#L401">401</span>
<span id="L402" rel="#L402">402</span>
<span id="L403" rel="#L403">403</span>
<span id="L404" rel="#L404">404</span>
<span id="L405" rel="#L405">405</span>
<span id="L406" rel="#L406">406</span>
<span id="L407" rel="#L407">407</span>
<span id="L408" rel="#L408">408</span>
<span id="L409" rel="#L409">409</span>
<span id="L410" rel="#L410">410</span>
<span id="L411" rel="#L411">411</span>
<span id="L412" rel="#L412">412</span>
<span id="L413" rel="#L413">413</span>
<span id="L414" rel="#L414">414</span>
<span id="L415" rel="#L415">415</span>
<span id="L416" rel="#L416">416</span>
<span id="L417" rel="#L417">417</span>
<span id="L418" rel="#L418">418</span>
<span id="L419" rel="#L419">419</span>
<span id="L420" rel="#L420">420</span>
<span id="L421" rel="#L421">421</span>
<span id="L422" rel="#L422">422</span>
<span id="L423" rel="#L423">423</span>
<span id="L424" rel="#L424">424</span>
<span id="L425" rel="#L425">425</span>
<span id="L426" rel="#L426">426</span>
<span id="L427" rel="#L427">427</span>
<span id="L428" rel="#L428">428</span>
<span id="L429" rel="#L429">429</span>
<span id="L430" rel="#L430">430</span>
<span id="L431" rel="#L431">431</span>
<span id="L432" rel="#L432">432</span>
<span id="L433" rel="#L433">433</span>
<span id="L434" rel="#L434">434</span>
<span id="L435" rel="#L435">435</span>
<span id="L436" rel="#L436">436</span>
<span id="L437" rel="#L437">437</span>
<span id="L438" rel="#L438">438</span>
<span id="L439" rel="#L439">439</span>
<span id="L440" rel="#L440">440</span>
<span id="L441" rel="#L441">441</span>
<span id="L442" rel="#L442">442</span>
<span id="L443" rel="#L443">443</span>
<span id="L444" rel="#L444">444</span>
<span id="L445" rel="#L445">445</span>
<span id="L446" rel="#L446">446</span>
<span id="L447" rel="#L447">447</span>
<span id="L448" rel="#L448">448</span>
<span id="L449" rel="#L449">449</span>
<span id="L450" rel="#L450">450</span>
<span id="L451" rel="#L451">451</span>
<span id="L452" rel="#L452">452</span>
<span id="L453" rel="#L453">453</span>
<span id="L454" rel="#L454">454</span>
<span id="L455" rel="#L455">455</span>
<span id="L456" rel="#L456">456</span>
<span id="L457" rel="#L457">457</span>
<span id="L458" rel="#L458">458</span>
<span id="L459" rel="#L459">459</span>
<span id="L460" rel="#L460">460</span>
<span id="L461" rel="#L461">461</span>
<span id="L462" rel="#L462">462</span>
<span id="L463" rel="#L463">463</span>
<span id="L464" rel="#L464">464</span>
<span id="L465" rel="#L465">465</span>
<span id="L466" rel="#L466">466</span>
<span id="L467" rel="#L467">467</span>
<span id="L468" rel="#L468">468</span>
<span id="L469" rel="#L469">469</span>
<span id="L470" rel="#L470">470</span>
<span id="L471" rel="#L471">471</span>
<span id="L472" rel="#L472">472</span>
<span id="L473" rel="#L473">473</span>
<span id="L474" rel="#L474">474</span>
<span id="L475" rel="#L475">475</span>
<span id="L476" rel="#L476">476</span>
<span id="L477" rel="#L477">477</span>
<span id="L478" rel="#L478">478</span>
<span id="L479" rel="#L479">479</span>
<span id="L480" rel="#L480">480</span>
<span id="L481" rel="#L481">481</span>
<span id="L482" rel="#L482">482</span>
<span id="L483" rel="#L483">483</span>
<span id="L484" rel="#L484">484</span>
<span id="L485" rel="#L485">485</span>
<span id="L486" rel="#L486">486</span>
<span id="L487" rel="#L487">487</span>
<span id="L488" rel="#L488">488</span>
<span id="L489" rel="#L489">489</span>
<span id="L490" rel="#L490">490</span>
<span id="L491" rel="#L491">491</span>
<span id="L492" rel="#L492">492</span>
<span id="L493" rel="#L493">493</span>
<span id="L494" rel="#L494">494</span>
<span id="L495" rel="#L495">495</span>
<span id="L496" rel="#L496">496</span>
<span id="L497" rel="#L497">497</span>
<span id="L498" rel="#L498">498</span>
<span id="L499" rel="#L499">499</span>
<span id="L500" rel="#L500">500</span>
<span id="L501" rel="#L501">501</span>
<span id="L502" rel="#L502">502</span>
<span id="L503" rel="#L503">503</span>
<span id="L504" rel="#L504">504</span>
<span id="L505" rel="#L505">505</span>
<span id="L506" rel="#L506">506</span>
<span id="L507" rel="#L507">507</span>
<span id="L508" rel="#L508">508</span>
<span id="L509" rel="#L509">509</span>
<span id="L510" rel="#L510">510</span>
<span id="L511" rel="#L511">511</span>
<span id="L512" rel="#L512">512</span>
<span id="L513" rel="#L513">513</span>
<span id="L514" rel="#L514">514</span>
<span id="L515" rel="#L515">515</span>
<span id="L516" rel="#L516">516</span>
<span id="L517" rel="#L517">517</span>
<span id="L518" rel="#L518">518</span>
<span id="L519" rel="#L519">519</span>
<span id="L520" rel="#L520">520</span>
<span id="L521" rel="#L521">521</span>
<span id="L522" rel="#L522">522</span>
<span id="L523" rel="#L523">523</span>
<span id="L524" rel="#L524">524</span>
<span id="L525" rel="#L525">525</span>
<span id="L526" rel="#L526">526</span>
<span id="L527" rel="#L527">527</span>
<span id="L528" rel="#L528">528</span>
<span id="L529" rel="#L529">529</span>
<span id="L530" rel="#L530">530</span>
<span id="L531" rel="#L531">531</span>
<span id="L532" rel="#L532">532</span>
<span id="L533" rel="#L533">533</span>
<span id="L534" rel="#L534">534</span>
<span id="L535" rel="#L535">535</span>
<span id="L536" rel="#L536">536</span>
<span id="L537" rel="#L537">537</span>
<span id="L538" rel="#L538">538</span>
<span id="L539" rel="#L539">539</span>
<span id="L540" rel="#L540">540</span>
<span id="L541" rel="#L541">541</span>
<span id="L542" rel="#L542">542</span>
<span id="L543" rel="#L543">543</span>
<span id="L544" rel="#L544">544</span>
<span id="L545" rel="#L545">545</span>
<span id="L546" rel="#L546">546</span>
<span id="L547" rel="#L547">547</span>
<span id="L548" rel="#L548">548</span>
<span id="L549" rel="#L549">549</span>
<span id="L550" rel="#L550">550</span>
<span id="L551" rel="#L551">551</span>
<span id="L552" rel="#L552">552</span>
<span id="L553" rel="#L553">553</span>
<span id="L554" rel="#L554">554</span>
<span id="L555" rel="#L555">555</span>
<span id="L556" rel="#L556">556</span>
<span id="L557" rel="#L557">557</span>
<span id="L558" rel="#L558">558</span>
<span id="L559" rel="#L559">559</span>
<span id="L560" rel="#L560">560</span>
<span id="L561" rel="#L561">561</span>
<span id="L562" rel="#L562">562</span>
<span id="L563" rel="#L563">563</span>
<span id="L564" rel="#L564">564</span>
<span id="L565" rel="#L565">565</span>
<span id="L566" rel="#L566">566</span>
<span id="L567" rel="#L567">567</span>
<span id="L568" rel="#L568">568</span>
<span id="L569" rel="#L569">569</span>
<span id="L570" rel="#L570">570</span>
<span id="L571" rel="#L571">571</span>
<span id="L572" rel="#L572">572</span>
<span id="L573" rel="#L573">573</span>
<span id="L574" rel="#L574">574</span>
<span id="L575" rel="#L575">575</span>
<span id="L576" rel="#L576">576</span>
<span id="L577" rel="#L577">577</span>
<span id="L578" rel="#L578">578</span>
<span id="L579" rel="#L579">579</span>
<span id="L580" rel="#L580">580</span>
<span id="L581" rel="#L581">581</span>
<span id="L582" rel="#L582">582</span>
<span id="L583" rel="#L583">583</span>
<span id="L584" rel="#L584">584</span>
<span id="L585" rel="#L585">585</span>
<span id="L586" rel="#L586">586</span>
<span id="L587" rel="#L587">587</span>
<span id="L588" rel="#L588">588</span>
<span id="L589" rel="#L589">589</span>
<span id="L590" rel="#L590">590</span>
<span id="L591" rel="#L591">591</span>
<span id="L592" rel="#L592">592</span>
<span id="L593" rel="#L593">593</span>
<span id="L594" rel="#L594">594</span>
<span id="L595" rel="#L595">595</span>
<span id="L596" rel="#L596">596</span>
<span id="L597" rel="#L597">597</span>
<span id="L598" rel="#L598">598</span>
<span id="L599" rel="#L599">599</span>
<span id="L600" rel="#L600">600</span>
<span id="L601" rel="#L601">601</span>
<span id="L602" rel="#L602">602</span>
<span id="L603" rel="#L603">603</span>
<span id="L604" rel="#L604">604</span>
<span id="L605" rel="#L605">605</span>
<span id="L606" rel="#L606">606</span>
<span id="L607" rel="#L607">607</span>
<span id="L608" rel="#L608">608</span>
<span id="L609" rel="#L609">609</span>
<span id="L610" rel="#L610">610</span>
<span id="L611" rel="#L611">611</span>
<span id="L612" rel="#L612">612</span>
<span id="L613" rel="#L613">613</span>
<span id="L614" rel="#L614">614</span>
<span id="L615" rel="#L615">615</span>
<span id="L616" rel="#L616">616</span>
<span id="L617" rel="#L617">617</span>
<span id="L618" rel="#L618">618</span>
<span id="L619" rel="#L619">619</span>
<span id="L620" rel="#L620">620</span>
<span id="L621" rel="#L621">621</span>
<span id="L622" rel="#L622">622</span>
<span id="L623" rel="#L623">623</span>
<span id="L624" rel="#L624">624</span>
<span id="L625" rel="#L625">625</span>
<span id="L626" rel="#L626">626</span>
<span id="L627" rel="#L627">627</span>
<span id="L628" rel="#L628">628</span>
<span id="L629" rel="#L629">629</span>
<span id="L630" rel="#L630">630</span>
<span id="L631" rel="#L631">631</span>
<span id="L632" rel="#L632">632</span>
<span id="L633" rel="#L633">633</span>
<span id="L634" rel="#L634">634</span>
<span id="L635" rel="#L635">635</span>
<span id="L636" rel="#L636">636</span>
<span id="L637" rel="#L637">637</span>
<span id="L638" rel="#L638">638</span>
<span id="L639" rel="#L639">639</span>
<span id="L640" rel="#L640">640</span>
<span id="L641" rel="#L641">641</span>
<span id="L642" rel="#L642">642</span>
<span id="L643" rel="#L643">643</span>
<span id="L644" rel="#L644">644</span>
<span id="L645" rel="#L645">645</span>
<span id="L646" rel="#L646">646</span>
<span id="L647" rel="#L647">647</span>
<span id="L648" rel="#L648">648</span>
<span id="L649" rel="#L649">649</span>
<span id="L650" rel="#L650">650</span>
<span id="L651" rel="#L651">651</span>
<span id="L652" rel="#L652">652</span>
<span id="L653" rel="#L653">653</span>
<span id="L654" rel="#L654">654</span>
<span id="L655" rel="#L655">655</span>
<span id="L656" rel="#L656">656</span>
<span id="L657" rel="#L657">657</span>
<span id="L658" rel="#L658">658</span>
<span id="L659" rel="#L659">659</span>
<span id="L660" rel="#L660">660</span>
<span id="L661" rel="#L661">661</span>
<span id="L662" rel="#L662">662</span>
<span id="L663" rel="#L663">663</span>
<span id="L664" rel="#L664">664</span>
<span id="L665" rel="#L665">665</span>
<span id="L666" rel="#L666">666</span>
<span id="L667" rel="#L667">667</span>
<span id="L668" rel="#L668">668</span>
<span id="L669" rel="#L669">669</span>
<span id="L670" rel="#L670">670</span>
<span id="L671" rel="#L671">671</span>
<span id="L672" rel="#L672">672</span>
<span id="L673" rel="#L673">673</span>
<span id="L674" rel="#L674">674</span>
<span id="L675" rel="#L675">675</span>
<span id="L676" rel="#L676">676</span>
<span id="L677" rel="#L677">677</span>
<span id="L678" rel="#L678">678</span>
<span id="L679" rel="#L679">679</span>
<span id="L680" rel="#L680">680</span>
<span id="L681" rel="#L681">681</span>
<span id="L682" rel="#L682">682</span>
<span id="L683" rel="#L683">683</span>
<span id="L684" rel="#L684">684</span>
<span id="L685" rel="#L685">685</span>
<span id="L686" rel="#L686">686</span>
<span id="L687" rel="#L687">687</span>
<span id="L688" rel="#L688">688</span>
<span id="L689" rel="#L689">689</span>
<span id="L690" rel="#L690">690</span>
<span id="L691" rel="#L691">691</span>
<span id="L692" rel="#L692">692</span>
<span id="L693" rel="#L693">693</span>
<span id="L694" rel="#L694">694</span>
<span id="L695" rel="#L695">695</span>
<span id="L696" rel="#L696">696</span>
<span id="L697" rel="#L697">697</span>
<span id="L698" rel="#L698">698</span>
<span id="L699" rel="#L699">699</span>
<span id="L700" rel="#L700">700</span>
<span id="L701" rel="#L701">701</span>
<span id="L702" rel="#L702">702</span>
<span id="L703" rel="#L703">703</span>
<span id="L704" rel="#L704">704</span>
<span id="L705" rel="#L705">705</span>
<span id="L706" rel="#L706">706</span>
<span id="L707" rel="#L707">707</span>
<span id="L708" rel="#L708">708</span>
<span id="L709" rel="#L709">709</span>
<span id="L710" rel="#L710">710</span>
<span id="L711" rel="#L711">711</span>
<span id="L712" rel="#L712">712</span>
<span id="L713" rel="#L713">713</span>
<span id="L714" rel="#L714">714</span>
<span id="L715" rel="#L715">715</span>
<span id="L716" rel="#L716">716</span>
<span id="L717" rel="#L717">717</span>
<span id="L718" rel="#L718">718</span>
<span id="L719" rel="#L719">719</span>
<span id="L720" rel="#L720">720</span>
<span id="L721" rel="#L721">721</span>
<span id="L722" rel="#L722">722</span>
<span id="L723" rel="#L723">723</span>
<span id="L724" rel="#L724">724</span>
<span id="L725" rel="#L725">725</span>
<span id="L726" rel="#L726">726</span>
<span id="L727" rel="#L727">727</span>
<span id="L728" rel="#L728">728</span>
<span id="L729" rel="#L729">729</span>
<span id="L730" rel="#L730">730</span>
<span id="L731" rel="#L731">731</span>
<span id="L732" rel="#L732">732</span>
<span id="L733" rel="#L733">733</span>
<span id="L734" rel="#L734">734</span>
<span id="L735" rel="#L735">735</span>
<span id="L736" rel="#L736">736</span>
<span id="L737" rel="#L737">737</span>
<span id="L738" rel="#L738">738</span>
<span id="L739" rel="#L739">739</span>
<span id="L740" rel="#L740">740</span>
<span id="L741" rel="#L741">741</span>
<span id="L742" rel="#L742">742</span>
<span id="L743" rel="#L743">743</span>
<span id="L744" rel="#L744">744</span>
<span id="L745" rel="#L745">745</span>
<span id="L746" rel="#L746">746</span>
<span id="L747" rel="#L747">747</span>
<span id="L748" rel="#L748">748</span>
<span id="L749" rel="#L749">749</span>
<span id="L750" rel="#L750">750</span>
<span id="L751" rel="#L751">751</span>
<span id="L752" rel="#L752">752</span>
<span id="L753" rel="#L753">753</span>
<span id="L754" rel="#L754">754</span>
<span id="L755" rel="#L755">755</span>
<span id="L756" rel="#L756">756</span>
<span id="L757" rel="#L757">757</span>
<span id="L758" rel="#L758">758</span>
<span id="L759" rel="#L759">759</span>
<span id="L760" rel="#L760">760</span>
<span id="L761" rel="#L761">761</span>
<span id="L762" rel="#L762">762</span>
<span id="L763" rel="#L763">763</span>
<span id="L764" rel="#L764">764</span>
<span id="L765" rel="#L765">765</span>
<span id="L766" rel="#L766">766</span>
<span id="L767" rel="#L767">767</span>
<span id="L768" rel="#L768">768</span>
<span id="L769" rel="#L769">769</span>
<span id="L770" rel="#L770">770</span>
<span id="L771" rel="#L771">771</span>
<span id="L772" rel="#L772">772</span>
<span id="L773" rel="#L773">773</span>
<span id="L774" rel="#L774">774</span>
<span id="L775" rel="#L775">775</span>
<span id="L776" rel="#L776">776</span>
<span id="L777" rel="#L777">777</span>
<span id="L778" rel="#L778">778</span>
<span id="L779" rel="#L779">779</span>
<span id="L780" rel="#L780">780</span>
<span id="L781" rel="#L781">781</span>
<span id="L782" rel="#L782">782</span>
<span id="L783" rel="#L783">783</span>
<span id="L784" rel="#L784">784</span>
<span id="L785" rel="#L785">785</span>
<span id="L786" rel="#L786">786</span>
<span id="L787" rel="#L787">787</span>
<span id="L788" rel="#L788">788</span>
<span id="L789" rel="#L789">789</span>
<span id="L790" rel="#L790">790</span>
<span id="L791" rel="#L791">791</span>
<span id="L792" rel="#L792">792</span>
<span id="L793" rel="#L793">793</span>
<span id="L794" rel="#L794">794</span>
<span id="L795" rel="#L795">795</span>
<span id="L796" rel="#L796">796</span>
<span id="L797" rel="#L797">797</span>
<span id="L798" rel="#L798">798</span>
<span id="L799" rel="#L799">799</span>
<span id="L800" rel="#L800">800</span>
<span id="L801" rel="#L801">801</span>
<span id="L802" rel="#L802">802</span>
<span id="L803" rel="#L803">803</span>
<span id="L804" rel="#L804">804</span>
<span id="L805" rel="#L805">805</span>
<span id="L806" rel="#L806">806</span>
<span id="L807" rel="#L807">807</span>
<span id="L808" rel="#L808">808</span>
<span id="L809" rel="#L809">809</span>
<span id="L810" rel="#L810">810</span>
<span id="L811" rel="#L811">811</span>
<span id="L812" rel="#L812">812</span>
<span id="L813" rel="#L813">813</span>
<span id="L814" rel="#L814">814</span>
<span id="L815" rel="#L815">815</span>
<span id="L816" rel="#L816">816</span>
<span id="L817" rel="#L817">817</span>
<span id="L818" rel="#L818">818</span>
<span id="L819" rel="#L819">819</span>
<span id="L820" rel="#L820">820</span>
<span id="L821" rel="#L821">821</span>
<span id="L822" rel="#L822">822</span>
<span id="L823" rel="#L823">823</span>
<span id="L824" rel="#L824">824</span>
<span id="L825" rel="#L825">825</span>
<span id="L826" rel="#L826">826</span>
<span id="L827" rel="#L827">827</span>
<span id="L828" rel="#L828">828</span>
<span id="L829" rel="#L829">829</span>
<span id="L830" rel="#L830">830</span>
<span id="L831" rel="#L831">831</span>
<span id="L832" rel="#L832">832</span>
<span id="L833" rel="#L833">833</span>
<span id="L834" rel="#L834">834</span>
<span id="L835" rel="#L835">835</span>
<span id="L836" rel="#L836">836</span>
<span id="L837" rel="#L837">837</span>
<span id="L838" rel="#L838">838</span>
<span id="L839" rel="#L839">839</span>
<span id="L840" rel="#L840">840</span>
<span id="L841" rel="#L841">841</span>
<span id="L842" rel="#L842">842</span>
<span id="L843" rel="#L843">843</span>
<span id="L844" rel="#L844">844</span>
<span id="L845" rel="#L845">845</span>
<span id="L846" rel="#L846">846</span>
<span id="L847" rel="#L847">847</span>
<span id="L848" rel="#L848">848</span>
<span id="L849" rel="#L849">849</span>
<span id="L850" rel="#L850">850</span>
<span id="L851" rel="#L851">851</span>
<span id="L852" rel="#L852">852</span>
<span id="L853" rel="#L853">853</span>
<span id="L854" rel="#L854">854</span>
<span id="L855" rel="#L855">855</span>
<span id="L856" rel="#L856">856</span>
<span id="L857" rel="#L857">857</span>
<span id="L858" rel="#L858">858</span>
<span id="L859" rel="#L859">859</span>
<span id="L860" rel="#L860">860</span>
<span id="L861" rel="#L861">861</span>
<span id="L862" rel="#L862">862</span>
<span id="L863" rel="#L863">863</span>
<span id="L864" rel="#L864">864</span>
<span id="L865" rel="#L865">865</span>
<span id="L866" rel="#L866">866</span>
<span id="L867" rel="#L867">867</span>
<span id="L868" rel="#L868">868</span>
<span id="L869" rel="#L869">869</span>
<span id="L870" rel="#L870">870</span>
<span id="L871" rel="#L871">871</span>
<span id="L872" rel="#L872">872</span>
<span id="L873" rel="#L873">873</span>
<span id="L874" rel="#L874">874</span>
<span id="L875" rel="#L875">875</span>
<span id="L876" rel="#L876">876</span>
<span id="L877" rel="#L877">877</span>
<span id="L878" rel="#L878">878</span>
<span id="L879" rel="#L879">879</span>
<span id="L880" rel="#L880">880</span>
<span id="L881" rel="#L881">881</span>
<span id="L882" rel="#L882">882</span>
<span id="L883" rel="#L883">883</span>
<span id="L884" rel="#L884">884</span>
<span id="L885" rel="#L885">885</span>
<span id="L886" rel="#L886">886</span>
<span id="L887" rel="#L887">887</span>
<span id="L888" rel="#L888">888</span>
<span id="L889" rel="#L889">889</span>
<span id="L890" rel="#L890">890</span>
<span id="L891" rel="#L891">891</span>
<span id="L892" rel="#L892">892</span>
<span id="L893" rel="#L893">893</span>
<span id="L894" rel="#L894">894</span>
<span id="L895" rel="#L895">895</span>
<span id="L896" rel="#L896">896</span>
<span id="L897" rel="#L897">897</span>
<span id="L898" rel="#L898">898</span>
<span id="L899" rel="#L899">899</span>
<span id="L900" rel="#L900">900</span>
<span id="L901" rel="#L901">901</span>
<span id="L902" rel="#L902">902</span>
<span id="L903" rel="#L903">903</span>
<span id="L904" rel="#L904">904</span>
<span id="L905" rel="#L905">905</span>
<span id="L906" rel="#L906">906</span>
<span id="L907" rel="#L907">907</span>
<span id="L908" rel="#L908">908</span>
<span id="L909" rel="#L909">909</span>
<span id="L910" rel="#L910">910</span>
<span id="L911" rel="#L911">911</span>
<span id="L912" rel="#L912">912</span>
<span id="L913" rel="#L913">913</span>
<span id="L914" rel="#L914">914</span>
<span id="L915" rel="#L915">915</span>
<span id="L916" rel="#L916">916</span>
<span id="L917" rel="#L917">917</span>
<span id="L918" rel="#L918">918</span>
<span id="L919" rel="#L919">919</span>
<span id="L920" rel="#L920">920</span>
<span id="L921" rel="#L921">921</span>
<span id="L922" rel="#L922">922</span>
<span id="L923" rel="#L923">923</span>
<span id="L924" rel="#L924">924</span>
<span id="L925" rel="#L925">925</span>
<span id="L926" rel="#L926">926</span>
<span id="L927" rel="#L927">927</span>
<span id="L928" rel="#L928">928</span>
<span id="L929" rel="#L929">929</span>
<span id="L930" rel="#L930">930</span>
<span id="L931" rel="#L931">931</span>
<span id="L932" rel="#L932">932</span>
<span id="L933" rel="#L933">933</span>
<span id="L934" rel="#L934">934</span>
<span id="L935" rel="#L935">935</span>
<span id="L936" rel="#L936">936</span>
<span id="L937" rel="#L937">937</span>
<span id="L938" rel="#L938">938</span>
<span id="L939" rel="#L939">939</span>
<span id="L940" rel="#L940">940</span>
<span id="L941" rel="#L941">941</span>
<span id="L942" rel="#L942">942</span>
<span id="L943" rel="#L943">943</span>
<span id="L944" rel="#L944">944</span>
<span id="L945" rel="#L945">945</span>
<span id="L946" rel="#L946">946</span>
<span id="L947" rel="#L947">947</span>
<span id="L948" rel="#L948">948</span>
<span id="L949" rel="#L949">949</span>
<span id="L950" rel="#L950">950</span>
<span id="L951" rel="#L951">951</span>
<span id="L952" rel="#L952">952</span>
<span id="L953" rel="#L953">953</span>
<span id="L954" rel="#L954">954</span>
<span id="L955" rel="#L955">955</span>
<span id="L956" rel="#L956">956</span>
<span id="L957" rel="#L957">957</span>
<span id="L958" rel="#L958">958</span>
<span id="L959" rel="#L959">959</span>
<span id="L960" rel="#L960">960</span>
<span id="L961" rel="#L961">961</span>
<span id="L962" rel="#L962">962</span>
<span id="L963" rel="#L963">963</span>
<span id="L964" rel="#L964">964</span>
<span id="L965" rel="#L965">965</span>
<span id="L966" rel="#L966">966</span>
<span id="L967" rel="#L967">967</span>
<span id="L968" rel="#L968">968</span>
<span id="L969" rel="#L969">969</span>
<span id="L970" rel="#L970">970</span>
<span id="L971" rel="#L971">971</span>
<span id="L972" rel="#L972">972</span>
<span id="L973" rel="#L973">973</span>
<span id="L974" rel="#L974">974</span>
<span id="L975" rel="#L975">975</span>
<span id="L976" rel="#L976">976</span>
<span id="L977" rel="#L977">977</span>
<span id="L978" rel="#L978">978</span>
<span id="L979" rel="#L979">979</span>
<span id="L980" rel="#L980">980</span>
<span id="L981" rel="#L981">981</span>
<span id="L982" rel="#L982">982</span>
<span id="L983" rel="#L983">983</span>
<span id="L984" rel="#L984">984</span>
<span id="L985" rel="#L985">985</span>
<span id="L986" rel="#L986">986</span>
<span id="L987" rel="#L987">987</span>
<span id="L988" rel="#L988">988</span>
<span id="L989" rel="#L989">989</span>
<span id="L990" rel="#L990">990</span>
<span id="L991" rel="#L991">991</span>
<span id="L992" rel="#L992">992</span>
<span id="L993" rel="#L993">993</span>
<span id="L994" rel="#L994">994</span>
<span id="L995" rel="#L995">995</span>
<span id="L996" rel="#L996">996</span>
<span id="L997" rel="#L997">997</span>
<span id="L998" rel="#L998">998</span>
<span id="L999" rel="#L999">999</span>
<span id="L1000" rel="#L1000">1000</span>
<span id="L1001" rel="#L1001">1001</span>
<span id="L1002" rel="#L1002">1002</span>
<span id="L1003" rel="#L1003">1003</span>
<span id="L1004" rel="#L1004">1004</span>
<span id="L1005" rel="#L1005">1005</span>
<span id="L1006" rel="#L1006">1006</span>
<span id="L1007" rel="#L1007">1007</span>
<span id="L1008" rel="#L1008">1008</span>
<span id="L1009" rel="#L1009">1009</span>
<span id="L1010" rel="#L1010">1010</span>
<span id="L1011" rel="#L1011">1011</span>
<span id="L1012" rel="#L1012">1012</span>
<span id="L1013" rel="#L1013">1013</span>
<span id="L1014" rel="#L1014">1014</span>
<span id="L1015" rel="#L1015">1015</span>
<span id="L1016" rel="#L1016">1016</span>
<span id="L1017" rel="#L1017">1017</span>
<span id="L1018" rel="#L1018">1018</span>
<span id="L1019" rel="#L1019">1019</span>
<span id="L1020" rel="#L1020">1020</span>
<span id="L1021" rel="#L1021">1021</span>
<span id="L1022" rel="#L1022">1022</span>
<span id="L1023" rel="#L1023">1023</span>
<span id="L1024" rel="#L1024">1024</span>
<span id="L1025" rel="#L1025">1025</span>
<span id="L1026" rel="#L1026">1026</span>
<span id="L1027" rel="#L1027">1027</span>
<span id="L1028" rel="#L1028">1028</span>
<span id="L1029" rel="#L1029">1029</span>
<span id="L1030" rel="#L1030">1030</span>
<span id="L1031" rel="#L1031">1031</span>
<span id="L1032" rel="#L1032">1032</span>
<span id="L1033" rel="#L1033">1033</span>
<span id="L1034" rel="#L1034">1034</span>
<span id="L1035" rel="#L1035">1035</span>
<span id="L1036" rel="#L1036">1036</span>
<span id="L1037" rel="#L1037">1037</span>
<span id="L1038" rel="#L1038">1038</span>
<span id="L1039" rel="#L1039">1039</span>
<span id="L1040" rel="#L1040">1040</span>
<span id="L1041" rel="#L1041">1041</span>
<span id="L1042" rel="#L1042">1042</span>
<span id="L1043" rel="#L1043">1043</span>
<span id="L1044" rel="#L1044">1044</span>
<span id="L1045" rel="#L1045">1045</span>
<span id="L1046" rel="#L1046">1046</span>
<span id="L1047" rel="#L1047">1047</span>
<span id="L1048" rel="#L1048">1048</span>
<span id="L1049" rel="#L1049">1049</span>
<span id="L1050" rel="#L1050">1050</span>
<span id="L1051" rel="#L1051">1051</span>
<span id="L1052" rel="#L1052">1052</span>
<span id="L1053" rel="#L1053">1053</span>
<span id="L1054" rel="#L1054">1054</span>
<span id="L1055" rel="#L1055">1055</span>
<span id="L1056" rel="#L1056">1056</span>
<span id="L1057" rel="#L1057">1057</span>
<span id="L1058" rel="#L1058">1058</span>
<span id="L1059" rel="#L1059">1059</span>
<span id="L1060" rel="#L1060">1060</span>
<span id="L1061" rel="#L1061">1061</span>
<span id="L1062" rel="#L1062">1062</span>
<span id="L1063" rel="#L1063">1063</span>
<span id="L1064" rel="#L1064">1064</span>
<span id="L1065" rel="#L1065">1065</span>
<span id="L1066" rel="#L1066">1066</span>
<span id="L1067" rel="#L1067">1067</span>
<span id="L1068" rel="#L1068">1068</span>
<span id="L1069" rel="#L1069">1069</span>
<span id="L1070" rel="#L1070">1070</span>
<span id="L1071" rel="#L1071">1071</span>
<span id="L1072" rel="#L1072">1072</span>
<span id="L1073" rel="#L1073">1073</span>
<span id="L1074" rel="#L1074">1074</span>
<span id="L1075" rel="#L1075">1075</span>
<span id="L1076" rel="#L1076">1076</span>
<span id="L1077" rel="#L1077">1077</span>
<span id="L1078" rel="#L1078">1078</span>
<span id="L1079" rel="#L1079">1079</span>
<span id="L1080" rel="#L1080">1080</span>
<span id="L1081" rel="#L1081">1081</span>
<span id="L1082" rel="#L1082">1082</span>
<span id="L1083" rel="#L1083">1083</span>
<span id="L1084" rel="#L1084">1084</span>
<span id="L1085" rel="#L1085">1085</span>
<span id="L1086" rel="#L1086">1086</span>
<span id="L1087" rel="#L1087">1087</span>
<span id="L1088" rel="#L1088">1088</span>
<span id="L1089" rel="#L1089">1089</span>
<span id="L1090" rel="#L1090">1090</span>
<span id="L1091" rel="#L1091">1091</span>
<span id="L1092" rel="#L1092">1092</span>
<span id="L1093" rel="#L1093">1093</span>
<span id="L1094" rel="#L1094">1094</span>
<span id="L1095" rel="#L1095">1095</span>
<span id="L1096" rel="#L1096">1096</span>
<span id="L1097" rel="#L1097">1097</span>
<span id="L1098" rel="#L1098">1098</span>
<span id="L1099" rel="#L1099">1099</span>
<span id="L1100" rel="#L1100">1100</span>
<span id="L1101" rel="#L1101">1101</span>
<span id="L1102" rel="#L1102">1102</span>
<span id="L1103" rel="#L1103">1103</span>
<span id="L1104" rel="#L1104">1104</span>
<span id="L1105" rel="#L1105">1105</span>
<span id="L1106" rel="#L1106">1106</span>
<span id="L1107" rel="#L1107">1107</span>
<span id="L1108" rel="#L1108">1108</span>
<span id="L1109" rel="#L1109">1109</span>
<span id="L1110" rel="#L1110">1110</span>
<span id="L1111" rel="#L1111">1111</span>
<span id="L1112" rel="#L1112">1112</span>
<span id="L1113" rel="#L1113">1113</span>
<span id="L1114" rel="#L1114">1114</span>
<span id="L1115" rel="#L1115">1115</span>
<span id="L1116" rel="#L1116">1116</span>
<span id="L1117" rel="#L1117">1117</span>
<span id="L1118" rel="#L1118">1118</span>
<span id="L1119" rel="#L1119">1119</span>
<span id="L1120" rel="#L1120">1120</span>
<span id="L1121" rel="#L1121">1121</span>
<span id="L1122" rel="#L1122">1122</span>
<span id="L1123" rel="#L1123">1123</span>
<span id="L1124" rel="#L1124">1124</span>
<span id="L1125" rel="#L1125">1125</span>
<span id="L1126" rel="#L1126">1126</span>
<span id="L1127" rel="#L1127">1127</span>
<span id="L1128" rel="#L1128">1128</span>
<span id="L1129" rel="#L1129">1129</span>
<span id="L1130" rel="#L1130">1130</span>
<span id="L1131" rel="#L1131">1131</span>
<span id="L1132" rel="#L1132">1132</span>
<span id="L1133" rel="#L1133">1133</span>
<span id="L1134" rel="#L1134">1134</span>
<span id="L1135" rel="#L1135">1135</span>
<span id="L1136" rel="#L1136">1136</span>
<span id="L1137" rel="#L1137">1137</span>
<span id="L1138" rel="#L1138">1138</span>
<span id="L1139" rel="#L1139">1139</span>
<span id="L1140" rel="#L1140">1140</span>
<span id="L1141" rel="#L1141">1141</span>
<span id="L1142" rel="#L1142">1142</span>
<span id="L1143" rel="#L1143">1143</span>
<span id="L1144" rel="#L1144">1144</span>
<span id="L1145" rel="#L1145">1145</span>
<span id="L1146" rel="#L1146">1146</span>
<span id="L1147" rel="#L1147">1147</span>
<span id="L1148" rel="#L1148">1148</span>
<span id="L1149" rel="#L1149">1149</span>
<span id="L1150" rel="#L1150">1150</span>
<span id="L1151" rel="#L1151">1151</span>
<span id="L1152" rel="#L1152">1152</span>
<span id="L1153" rel="#L1153">1153</span>
<span id="L1154" rel="#L1154">1154</span>
<span id="L1155" rel="#L1155">1155</span>
<span id="L1156" rel="#L1156">1156</span>
<span id="L1157" rel="#L1157">1157</span>
<span id="L1158" rel="#L1158">1158</span>
<span id="L1159" rel="#L1159">1159</span>
<span id="L1160" rel="#L1160">1160</span>
<span id="L1161" rel="#L1161">1161</span>
<span id="L1162" rel="#L1162">1162</span>
<span id="L1163" rel="#L1163">1163</span>
<span id="L1164" rel="#L1164">1164</span>
<span id="L1165" rel="#L1165">1165</span>
<span id="L1166" rel="#L1166">1166</span>
<span id="L1167" rel="#L1167">1167</span>
<span id="L1168" rel="#L1168">1168</span>
<span id="L1169" rel="#L1169">1169</span>
<span id="L1170" rel="#L1170">1170</span>
<span id="L1171" rel="#L1171">1171</span>
<span id="L1172" rel="#L1172">1172</span>
<span id="L1173" rel="#L1173">1173</span>
<span id="L1174" rel="#L1174">1174</span>
<span id="L1175" rel="#L1175">1175</span>
<span id="L1176" rel="#L1176">1176</span>
<span id="L1177" rel="#L1177">1177</span>
<span id="L1178" rel="#L1178">1178</span>
<span id="L1179" rel="#L1179">1179</span>
<span id="L1180" rel="#L1180">1180</span>
<span id="L1181" rel="#L1181">1181</span>
<span id="L1182" rel="#L1182">1182</span>
<span id="L1183" rel="#L1183">1183</span>
<span id="L1184" rel="#L1184">1184</span>
<span id="L1185" rel="#L1185">1185</span>
<span id="L1186" rel="#L1186">1186</span>
<span id="L1187" rel="#L1187">1187</span>
<span id="L1188" rel="#L1188">1188</span>
<span id="L1189" rel="#L1189">1189</span>
<span id="L1190" rel="#L1190">1190</span>
<span id="L1191" rel="#L1191">1191</span>
<span id="L1192" rel="#L1192">1192</span>
<span id="L1193" rel="#L1193">1193</span>
<span id="L1194" rel="#L1194">1194</span>
<span id="L1195" rel="#L1195">1195</span>
<span id="L1196" rel="#L1196">1196</span>
<span id="L1197" rel="#L1197">1197</span>
<span id="L1198" rel="#L1198">1198</span>
<span id="L1199" rel="#L1199">1199</span>
<span id="L1200" rel="#L1200">1200</span>
<span id="L1201" rel="#L1201">1201</span>
<span id="L1202" rel="#L1202">1202</span>
<span id="L1203" rel="#L1203">1203</span>
<span id="L1204" rel="#L1204">1204</span>
<span id="L1205" rel="#L1205">1205</span>
<span id="L1206" rel="#L1206">1206</span>
<span id="L1207" rel="#L1207">1207</span>
<span id="L1208" rel="#L1208">1208</span>
<span id="L1209" rel="#L1209">1209</span>
<span id="L1210" rel="#L1210">1210</span>
<span id="L1211" rel="#L1211">1211</span>
<span id="L1212" rel="#L1212">1212</span>
<span id="L1213" rel="#L1213">1213</span>
<span id="L1214" rel="#L1214">1214</span>
<span id="L1215" rel="#L1215">1215</span>
<span id="L1216" rel="#L1216">1216</span>
<span id="L1217" rel="#L1217">1217</span>
<span id="L1218" rel="#L1218">1218</span>
<span id="L1219" rel="#L1219">1219</span>
<span id="L1220" rel="#L1220">1220</span>
<span id="L1221" rel="#L1221">1221</span>
<span id="L1222" rel="#L1222">1222</span>
<span id="L1223" rel="#L1223">1223</span>
<span id="L1224" rel="#L1224">1224</span>
<span id="L1225" rel="#L1225">1225</span>
<span id="L1226" rel="#L1226">1226</span>
<span id="L1227" rel="#L1227">1227</span>
<span id="L1228" rel="#L1228">1228</span>
<span id="L1229" rel="#L1229">1229</span>
<span id="L1230" rel="#L1230">1230</span>
<span id="L1231" rel="#L1231">1231</span>
<span id="L1232" rel="#L1232">1232</span>
<span id="L1233" rel="#L1233">1233</span>
<span id="L1234" rel="#L1234">1234</span>
<span id="L1235" rel="#L1235">1235</span>
<span id="L1236" rel="#L1236">1236</span>
<span id="L1237" rel="#L1237">1237</span>
<span id="L1238" rel="#L1238">1238</span>
<span id="L1239" rel="#L1239">1239</span>
<span id="L1240" rel="#L1240">1240</span>
<span id="L1241" rel="#L1241">1241</span>
<span id="L1242" rel="#L1242">1242</span>
<span id="L1243" rel="#L1243">1243</span>
<span id="L1244" rel="#L1244">1244</span>
<span id="L1245" rel="#L1245">1245</span>
<span id="L1246" rel="#L1246">1246</span>
<span id="L1247" rel="#L1247">1247</span>
<span id="L1248" rel="#L1248">1248</span>
<span id="L1249" rel="#L1249">1249</span>
<span id="L1250" rel="#L1250">1250</span>
<span id="L1251" rel="#L1251">1251</span>
<span id="L1252" rel="#L1252">1252</span>
<span id="L1253" rel="#L1253">1253</span>
<span id="L1254" rel="#L1254">1254</span>
<span id="L1255" rel="#L1255">1255</span>
<span id="L1256" rel="#L1256">1256</span>
<span id="L1257" rel="#L1257">1257</span>
<span id="L1258" rel="#L1258">1258</span>
<span id="L1259" rel="#L1259">1259</span>
<span id="L1260" rel="#L1260">1260</span>
<span id="L1261" rel="#L1261">1261</span>
<span id="L1262" rel="#L1262">1262</span>
<span id="L1263" rel="#L1263">1263</span>
<span id="L1264" rel="#L1264">1264</span>
<span id="L1265" rel="#L1265">1265</span>
<span id="L1266" rel="#L1266">1266</span>
<span id="L1267" rel="#L1267">1267</span>
<span id="L1268" rel="#L1268">1268</span>
<span id="L1269" rel="#L1269">1269</span>
<span id="L1270" rel="#L1270">1270</span>
<span id="L1271" rel="#L1271">1271</span>
<span id="L1272" rel="#L1272">1272</span>
<span id="L1273" rel="#L1273">1273</span>
<span id="L1274" rel="#L1274">1274</span>
<span id="L1275" rel="#L1275">1275</span>
<span id="L1276" rel="#L1276">1276</span>
<span id="L1277" rel="#L1277">1277</span>
<span id="L1278" rel="#L1278">1278</span>
<span id="L1279" rel="#L1279">1279</span>
<span id="L1280" rel="#L1280">1280</span>
<span id="L1281" rel="#L1281">1281</span>
<span id="L1282" rel="#L1282">1282</span>
<span id="L1283" rel="#L1283">1283</span>
<span id="L1284" rel="#L1284">1284</span>
<span id="L1285" rel="#L1285">1285</span>
<span id="L1286" rel="#L1286">1286</span>
<span id="L1287" rel="#L1287">1287</span>
<span id="L1288" rel="#L1288">1288</span>
<span id="L1289" rel="#L1289">1289</span>
<span id="L1290" rel="#L1290">1290</span>
<span id="L1291" rel="#L1291">1291</span>
<span id="L1292" rel="#L1292">1292</span>
<span id="L1293" rel="#L1293">1293</span>
<span id="L1294" rel="#L1294">1294</span>
<span id="L1295" rel="#L1295">1295</span>
<span id="L1296" rel="#L1296">1296</span>
<span id="L1297" rel="#L1297">1297</span>
<span id="L1298" rel="#L1298">1298</span>
<span id="L1299" rel="#L1299">1299</span>
<span id="L1300" rel="#L1300">1300</span>
<span id="L1301" rel="#L1301">1301</span>
<span id="L1302" rel="#L1302">1302</span>
<span id="L1303" rel="#L1303">1303</span>
<span id="L1304" rel="#L1304">1304</span>
<span id="L1305" rel="#L1305">1305</span>
<span id="L1306" rel="#L1306">1306</span>
<span id="L1307" rel="#L1307">1307</span>
<span id="L1308" rel="#L1308">1308</span>
<span id="L1309" rel="#L1309">1309</span>
<span id="L1310" rel="#L1310">1310</span>
<span id="L1311" rel="#L1311">1311</span>
<span id="L1312" rel="#L1312">1312</span>
<span id="L1313" rel="#L1313">1313</span>
<span id="L1314" rel="#L1314">1314</span>
<span id="L1315" rel="#L1315">1315</span>
<span id="L1316" rel="#L1316">1316</span>
<span id="L1317" rel="#L1317">1317</span>
<span id="L1318" rel="#L1318">1318</span>
<span id="L1319" rel="#L1319">1319</span>
<span id="L1320" rel="#L1320">1320</span>
<span id="L1321" rel="#L1321">1321</span>
<span id="L1322" rel="#L1322">1322</span>
<span id="L1323" rel="#L1323">1323</span>
<span id="L1324" rel="#L1324">1324</span>
<span id="L1325" rel="#L1325">1325</span>
<span id="L1326" rel="#L1326">1326</span>
<span id="L1327" rel="#L1327">1327</span>
<span id="L1328" rel="#L1328">1328</span>
<span id="L1329" rel="#L1329">1329</span>
<span id="L1330" rel="#L1330">1330</span>
<span id="L1331" rel="#L1331">1331</span>
<span id="L1332" rel="#L1332">1332</span>
<span id="L1333" rel="#L1333">1333</span>
<span id="L1334" rel="#L1334">1334</span>
<span id="L1335" rel="#L1335">1335</span>
<span id="L1336" rel="#L1336">1336</span>
<span id="L1337" rel="#L1337">1337</span>
<span id="L1338" rel="#L1338">1338</span>
<span id="L1339" rel="#L1339">1339</span>
<span id="L1340" rel="#L1340">1340</span>
<span id="L1341" rel="#L1341">1341</span>
<span id="L1342" rel="#L1342">1342</span>
<span id="L1343" rel="#L1343">1343</span>
<span id="L1344" rel="#L1344">1344</span>
<span id="L1345" rel="#L1345">1345</span>
<span id="L1346" rel="#L1346">1346</span>
<span id="L1347" rel="#L1347">1347</span>
<span id="L1348" rel="#L1348">1348</span>
<span id="L1349" rel="#L1349">1349</span>
<span id="L1350" rel="#L1350">1350</span>
<span id="L1351" rel="#L1351">1351</span>
<span id="L1352" rel="#L1352">1352</span>
<span id="L1353" rel="#L1353">1353</span>
<span id="L1354" rel="#L1354">1354</span>
<span id="L1355" rel="#L1355">1355</span>
<span id="L1356" rel="#L1356">1356</span>
<span id="L1357" rel="#L1357">1357</span>
<span id="L1358" rel="#L1358">1358</span>
<span id="L1359" rel="#L1359">1359</span>
<span id="L1360" rel="#L1360">1360</span>
<span id="L1361" rel="#L1361">1361</span>
<span id="L1362" rel="#L1362">1362</span>
<span id="L1363" rel="#L1363">1363</span>
<span id="L1364" rel="#L1364">1364</span>
<span id="L1365" rel="#L1365">1365</span>
<span id="L1366" rel="#L1366">1366</span>
<span id="L1367" rel="#L1367">1367</span>
<span id="L1368" rel="#L1368">1368</span>
<span id="L1369" rel="#L1369">1369</span>
<span id="L1370" rel="#L1370">1370</span>
<span id="L1371" rel="#L1371">1371</span>
<span id="L1372" rel="#L1372">1372</span>
<span id="L1373" rel="#L1373">1373</span>
<span id="L1374" rel="#L1374">1374</span>
<span id="L1375" rel="#L1375">1375</span>
<span id="L1376" rel="#L1376">1376</span>
<span id="L1377" rel="#L1377">1377</span>
<span id="L1378" rel="#L1378">1378</span>
<span id="L1379" rel="#L1379">1379</span>
<span id="L1380" rel="#L1380">1380</span>
<span id="L1381" rel="#L1381">1381</span>
<span id="L1382" rel="#L1382">1382</span>
<span id="L1383" rel="#L1383">1383</span>
<span id="L1384" rel="#L1384">1384</span>
<span id="L1385" rel="#L1385">1385</span>
<span id="L1386" rel="#L1386">1386</span>
<span id="L1387" rel="#L1387">1387</span>
<span id="L1388" rel="#L1388">1388</span>
<span id="L1389" rel="#L1389">1389</span>
<span id="L1390" rel="#L1390">1390</span>
<span id="L1391" rel="#L1391">1391</span>
<span id="L1392" rel="#L1392">1392</span>
<span id="L1393" rel="#L1393">1393</span>
<span id="L1394" rel="#L1394">1394</span>
<span id="L1395" rel="#L1395">1395</span>
<span id="L1396" rel="#L1396">1396</span>
<span id="L1397" rel="#L1397">1397</span>
<span id="L1398" rel="#L1398">1398</span>
<span id="L1399" rel="#L1399">1399</span>
<span id="L1400" rel="#L1400">1400</span>
<span id="L1401" rel="#L1401">1401</span>
<span id="L1402" rel="#L1402">1402</span>
<span id="L1403" rel="#L1403">1403</span>
<span id="L1404" rel="#L1404">1404</span>
<span id="L1405" rel="#L1405">1405</span>
<span id="L1406" rel="#L1406">1406</span>
<span id="L1407" rel="#L1407">1407</span>
<span id="L1408" rel="#L1408">1408</span>
<span id="L1409" rel="#L1409">1409</span>
<span id="L1410" rel="#L1410">1410</span>
<span id="L1411" rel="#L1411">1411</span>
<span id="L1412" rel="#L1412">1412</span>
<span id="L1413" rel="#L1413">1413</span>
<span id="L1414" rel="#L1414">1414</span>
<span id="L1415" rel="#L1415">1415</span>
<span id="L1416" rel="#L1416">1416</span>
<span id="L1417" rel="#L1417">1417</span>
<span id="L1418" rel="#L1418">1418</span>
<span id="L1419" rel="#L1419">1419</span>
<span id="L1420" rel="#L1420">1420</span>
<span id="L1421" rel="#L1421">1421</span>
<span id="L1422" rel="#L1422">1422</span>
<span id="L1423" rel="#L1423">1423</span>
<span id="L1424" rel="#L1424">1424</span>
<span id="L1425" rel="#L1425">1425</span>
<span id="L1426" rel="#L1426">1426</span>
<span id="L1427" rel="#L1427">1427</span>
<span id="L1428" rel="#L1428">1428</span>
<span id="L1429" rel="#L1429">1429</span>
<span id="L1430" rel="#L1430">1430</span>
<span id="L1431" rel="#L1431">1431</span>
<span id="L1432" rel="#L1432">1432</span>
<span id="L1433" rel="#L1433">1433</span>
<span id="L1434" rel="#L1434">1434</span>
<span id="L1435" rel="#L1435">1435</span>
<span id="L1436" rel="#L1436">1436</span>
<span id="L1437" rel="#L1437">1437</span>
<span id="L1438" rel="#L1438">1438</span>
<span id="L1439" rel="#L1439">1439</span>
<span id="L1440" rel="#L1440">1440</span>
<span id="L1441" rel="#L1441">1441</span>
<span id="L1442" rel="#L1442">1442</span>
<span id="L1443" rel="#L1443">1443</span>
<span id="L1444" rel="#L1444">1444</span>
<span id="L1445" rel="#L1445">1445</span>
<span id="L1446" rel="#L1446">1446</span>
<span id="L1447" rel="#L1447">1447</span>
<span id="L1448" rel="#L1448">1448</span>
<span id="L1449" rel="#L1449">1449</span>
<span id="L1450" rel="#L1450">1450</span>
<span id="L1451" rel="#L1451">1451</span>
<span id="L1452" rel="#L1452">1452</span>
<span id="L1453" rel="#L1453">1453</span>
<span id="L1454" rel="#L1454">1454</span>
<span id="L1455" rel="#L1455">1455</span>
<span id="L1456" rel="#L1456">1456</span>
<span id="L1457" rel="#L1457">1457</span>
<span id="L1458" rel="#L1458">1458</span>
<span id="L1459" rel="#L1459">1459</span>
<span id="L1460" rel="#L1460">1460</span>
<span id="L1461" rel="#L1461">1461</span>
<span id="L1462" rel="#L1462">1462</span>
<span id="L1463" rel="#L1463">1463</span>
<span id="L1464" rel="#L1464">1464</span>
<span id="L1465" rel="#L1465">1465</span>
<span id="L1466" rel="#L1466">1466</span>
<span id="L1467" rel="#L1467">1467</span>
<span id="L1468" rel="#L1468">1468</span>
<span id="L1469" rel="#L1469">1469</span>
<span id="L1470" rel="#L1470">1470</span>
<span id="L1471" rel="#L1471">1471</span>
<span id="L1472" rel="#L1472">1472</span>
<span id="L1473" rel="#L1473">1473</span>
<span id="L1474" rel="#L1474">1474</span>
<span id="L1475" rel="#L1475">1475</span>
<span id="L1476" rel="#L1476">1476</span>
<span id="L1477" rel="#L1477">1477</span>
<span id="L1478" rel="#L1478">1478</span>
<span id="L1479" rel="#L1479">1479</span>
<span id="L1480" rel="#L1480">1480</span>
<span id="L1481" rel="#L1481">1481</span>
<span id="L1482" rel="#L1482">1482</span>
<span id="L1483" rel="#L1483">1483</span>
<span id="L1484" rel="#L1484">1484</span>
<span id="L1485" rel="#L1485">1485</span>
<span id="L1486" rel="#L1486">1486</span>
<span id="L1487" rel="#L1487">1487</span>
<span id="L1488" rel="#L1488">1488</span>
<span id="L1489" rel="#L1489">1489</span>
<span id="L1490" rel="#L1490">1490</span>
<span id="L1491" rel="#L1491">1491</span>
<span id="L1492" rel="#L1492">1492</span>
<span id="L1493" rel="#L1493">1493</span>
<span id="L1494" rel="#L1494">1494</span>
<span id="L1495" rel="#L1495">1495</span>
<span id="L1496" rel="#L1496">1496</span>
<span id="L1497" rel="#L1497">1497</span>
<span id="L1498" rel="#L1498">1498</span>
<span id="L1499" rel="#L1499">1499</span>
<span id="L1500" rel="#L1500">1500</span>
<span id="L1501" rel="#L1501">1501</span>
<span id="L1502" rel="#L1502">1502</span>
<span id="L1503" rel="#L1503">1503</span>
<span id="L1504" rel="#L1504">1504</span>
<span id="L1505" rel="#L1505">1505</span>
<span id="L1506" rel="#L1506">1506</span>
<span id="L1507" rel="#L1507">1507</span>
<span id="L1508" rel="#L1508">1508</span>
<span id="L1509" rel="#L1509">1509</span>
<span id="L1510" rel="#L1510">1510</span>
<span id="L1511" rel="#L1511">1511</span>
<span id="L1512" rel="#L1512">1512</span>
<span id="L1513" rel="#L1513">1513</span>
<span id="L1514" rel="#L1514">1514</span>
<span id="L1515" rel="#L1515">1515</span>
<span id="L1516" rel="#L1516">1516</span>
<span id="L1517" rel="#L1517">1517</span>
<span id="L1518" rel="#L1518">1518</span>
<span id="L1519" rel="#L1519">1519</span>
<span id="L1520" rel="#L1520">1520</span>
<span id="L1521" rel="#L1521">1521</span>
<span id="L1522" rel="#L1522">1522</span>
<span id="L1523" rel="#L1523">1523</span>
<span id="L1524" rel="#L1524">1524</span>
<span id="L1525" rel="#L1525">1525</span>
<span id="L1526" rel="#L1526">1526</span>
<span id="L1527" rel="#L1527">1527</span>
<span id="L1528" rel="#L1528">1528</span>
<span id="L1529" rel="#L1529">1529</span>
<span id="L1530" rel="#L1530">1530</span>
<span id="L1531" rel="#L1531">1531</span>
<span id="L1532" rel="#L1532">1532</span>
<span id="L1533" rel="#L1533">1533</span>
<span id="L1534" rel="#L1534">1534</span>
<span id="L1535" rel="#L1535">1535</span>
<span id="L1536" rel="#L1536">1536</span>
<span id="L1537" rel="#L1537">1537</span>
<span id="L1538" rel="#L1538">1538</span>
<span id="L1539" rel="#L1539">1539</span>
<span id="L1540" rel="#L1540">1540</span>
<span id="L1541" rel="#L1541">1541</span>
<span id="L1542" rel="#L1542">1542</span>
<span id="L1543" rel="#L1543">1543</span>
<span id="L1544" rel="#L1544">1544</span>
<span id="L1545" rel="#L1545">1545</span>
<span id="L1546" rel="#L1546">1546</span>
<span id="L1547" rel="#L1547">1547</span>
<span id="L1548" rel="#L1548">1548</span>
<span id="L1549" rel="#L1549">1549</span>
<span id="L1550" rel="#L1550">1550</span>
<span id="L1551" rel="#L1551">1551</span>
<span id="L1552" rel="#L1552">1552</span>
<span id="L1553" rel="#L1553">1553</span>
<span id="L1554" rel="#L1554">1554</span>
<span id="L1555" rel="#L1555">1555</span>
<span id="L1556" rel="#L1556">1556</span>
<span id="L1557" rel="#L1557">1557</span>
<span id="L1558" rel="#L1558">1558</span>
<span id="L1559" rel="#L1559">1559</span>
<span id="L1560" rel="#L1560">1560</span>
<span id="L1561" rel="#L1561">1561</span>
<span id="L1562" rel="#L1562">1562</span>
<span id="L1563" rel="#L1563">1563</span>
<span id="L1564" rel="#L1564">1564</span>
<span id="L1565" rel="#L1565">1565</span>
<span id="L1566" rel="#L1566">1566</span>
<span id="L1567" rel="#L1567">1567</span>
<span id="L1568" rel="#L1568">1568</span>
<span id="L1569" rel="#L1569">1569</span>
<span id="L1570" rel="#L1570">1570</span>
<span id="L1571" rel="#L1571">1571</span>
<span id="L1572" rel="#L1572">1572</span>
<span id="L1573" rel="#L1573">1573</span>
<span id="L1574" rel="#L1574">1574</span>
<span id="L1575" rel="#L1575">1575</span>
<span id="L1576" rel="#L1576">1576</span>
<span id="L1577" rel="#L1577">1577</span>
<span id="L1578" rel="#L1578">1578</span>
<span id="L1579" rel="#L1579">1579</span>
<span id="L1580" rel="#L1580">1580</span>
<span id="L1581" rel="#L1581">1581</span>
<span id="L1582" rel="#L1582">1582</span>
<span id="L1583" rel="#L1583">1583</span>
<span id="L1584" rel="#L1584">1584</span>
<span id="L1585" rel="#L1585">1585</span>
<span id="L1586" rel="#L1586">1586</span>
<span id="L1587" rel="#L1587">1587</span>
<span id="L1588" rel="#L1588">1588</span>
<span id="L1589" rel="#L1589">1589</span>
<span id="L1590" rel="#L1590">1590</span>
<span id="L1591" rel="#L1591">1591</span>
<span id="L1592" rel="#L1592">1592</span>
<span id="L1593" rel="#L1593">1593</span>
<span id="L1594" rel="#L1594">1594</span>
<span id="L1595" rel="#L1595">1595</span>
<span id="L1596" rel="#L1596">1596</span>
<span id="L1597" rel="#L1597">1597</span>
<span id="L1598" rel="#L1598">1598</span>
<span id="L1599" rel="#L1599">1599</span>
<span id="L1600" rel="#L1600">1600</span>
<span id="L1601" rel="#L1601">1601</span>
<span id="L1602" rel="#L1602">1602</span>
<span id="L1603" rel="#L1603">1603</span>
<span id="L1604" rel="#L1604">1604</span>
<span id="L1605" rel="#L1605">1605</span>
<span id="L1606" rel="#L1606">1606</span>
<span id="L1607" rel="#L1607">1607</span>
<span id="L1608" rel="#L1608">1608</span>
<span id="L1609" rel="#L1609">1609</span>
<span id="L1610" rel="#L1610">1610</span>
<span id="L1611" rel="#L1611">1611</span>
<span id="L1612" rel="#L1612">1612</span>
<span id="L1613" rel="#L1613">1613</span>
<span id="L1614" rel="#L1614">1614</span>
<span id="L1615" rel="#L1615">1615</span>
<span id="L1616" rel="#L1616">1616</span>
<span id="L1617" rel="#L1617">1617</span>
<span id="L1618" rel="#L1618">1618</span>
<span id="L1619" rel="#L1619">1619</span>
<span id="L1620" rel="#L1620">1620</span>
<span id="L1621" rel="#L1621">1621</span>
<span id="L1622" rel="#L1622">1622</span>
<span id="L1623" rel="#L1623">1623</span>
<span id="L1624" rel="#L1624">1624</span>
<span id="L1625" rel="#L1625">1625</span>
<span id="L1626" rel="#L1626">1626</span>
<span id="L1627" rel="#L1627">1627</span>
<span id="L1628" rel="#L1628">1628</span>
<span id="L1629" rel="#L1629">1629</span>
<span id="L1630" rel="#L1630">1630</span>
<span id="L1631" rel="#L1631">1631</span>
<span id="L1632" rel="#L1632">1632</span>
<span id="L1633" rel="#L1633">1633</span>
<span id="L1634" rel="#L1634">1634</span>
<span id="L1635" rel="#L1635">1635</span>
<span id="L1636" rel="#L1636">1636</span>
<span id="L1637" rel="#L1637">1637</span>
<span id="L1638" rel="#L1638">1638</span>
<span id="L1639" rel="#L1639">1639</span>
<span id="L1640" rel="#L1640">1640</span>
<span id="L1641" rel="#L1641">1641</span>
<span id="L1642" rel="#L1642">1642</span>
<span id="L1643" rel="#L1643">1643</span>
<span id="L1644" rel="#L1644">1644</span>
<span id="L1645" rel="#L1645">1645</span>
<span id="L1646" rel="#L1646">1646</span>
<span id="L1647" rel="#L1647">1647</span>
<span id="L1648" rel="#L1648">1648</span>
<span id="L1649" rel="#L1649">1649</span>
<span id="L1650" rel="#L1650">1650</span>
<span id="L1651" rel="#L1651">1651</span>
<span id="L1652" rel="#L1652">1652</span>
<span id="L1653" rel="#L1653">1653</span>
<span id="L1654" rel="#L1654">1654</span>
<span id="L1655" rel="#L1655">1655</span>
<span id="L1656" rel="#L1656">1656</span>
<span id="L1657" rel="#L1657">1657</span>
<span id="L1658" rel="#L1658">1658</span>
<span id="L1659" rel="#L1659">1659</span>
<span id="L1660" rel="#L1660">1660</span>
<span id="L1661" rel="#L1661">1661</span>
<span id="L1662" rel="#L1662">1662</span>
<span id="L1663" rel="#L1663">1663</span>
<span id="L1664" rel="#L1664">1664</span>
<span id="L1665" rel="#L1665">1665</span>
<span id="L1666" rel="#L1666">1666</span>
<span id="L1667" rel="#L1667">1667</span>
<span id="L1668" rel="#L1668">1668</span>
<span id="L1669" rel="#L1669">1669</span>
<span id="L1670" rel="#L1670">1670</span>
<span id="L1671" rel="#L1671">1671</span>
<span id="L1672" rel="#L1672">1672</span>
<span id="L1673" rel="#L1673">1673</span>
<span id="L1674" rel="#L1674">1674</span>
<span id="L1675" rel="#L1675">1675</span>
<span id="L1676" rel="#L1676">1676</span>
<span id="L1677" rel="#L1677">1677</span>
<span id="L1678" rel="#L1678">1678</span>
<span id="L1679" rel="#L1679">1679</span>
<span id="L1680" rel="#L1680">1680</span>
<span id="L1681" rel="#L1681">1681</span>
<span id="L1682" rel="#L1682">1682</span>
<span id="L1683" rel="#L1683">1683</span>
<span id="L1684" rel="#L1684">1684</span>
<span id="L1685" rel="#L1685">1685</span>
<span id="L1686" rel="#L1686">1686</span>
<span id="L1687" rel="#L1687">1687</span>
<span id="L1688" rel="#L1688">1688</span>
<span id="L1689" rel="#L1689">1689</span>
<span id="L1690" rel="#L1690">1690</span>
<span id="L1691" rel="#L1691">1691</span>
<span id="L1692" rel="#L1692">1692</span>
<span id="L1693" rel="#L1693">1693</span>
<span id="L1694" rel="#L1694">1694</span>
<span id="L1695" rel="#L1695">1695</span>
<span id="L1696" rel="#L1696">1696</span>
<span id="L1697" rel="#L1697">1697</span>
<span id="L1698" rel="#L1698">1698</span>
<span id="L1699" rel="#L1699">1699</span>
<span id="L1700" rel="#L1700">1700</span>
<span id="L1701" rel="#L1701">1701</span>
<span id="L1702" rel="#L1702">1702</span>
<span id="L1703" rel="#L1703">1703</span>
<span id="L1704" rel="#L1704">1704</span>
<span id="L1705" rel="#L1705">1705</span>
<span id="L1706" rel="#L1706">1706</span>
<span id="L1707" rel="#L1707">1707</span>
<span id="L1708" rel="#L1708">1708</span>
<span id="L1709" rel="#L1709">1709</span>
<span id="L1710" rel="#L1710">1710</span>
<span id="L1711" rel="#L1711">1711</span>
<span id="L1712" rel="#L1712">1712</span>
<span id="L1713" rel="#L1713">1713</span>
<span id="L1714" rel="#L1714">1714</span>
<span id="L1715" rel="#L1715">1715</span>
<span id="L1716" rel="#L1716">1716</span>
<span id="L1717" rel="#L1717">1717</span>
<span id="L1718" rel="#L1718">1718</span>
<span id="L1719" rel="#L1719">1719</span>
<span id="L1720" rel="#L1720">1720</span>
<span id="L1721" rel="#L1721">1721</span>
<span id="L1722" rel="#L1722">1722</span>
<span id="L1723" rel="#L1723">1723</span>
<span id="L1724" rel="#L1724">1724</span>
<span id="L1725" rel="#L1725">1725</span>
<span id="L1726" rel="#L1726">1726</span>
<span id="L1727" rel="#L1727">1727</span>
<span id="L1728" rel="#L1728">1728</span>
<span id="L1729" rel="#L1729">1729</span>
<span id="L1730" rel="#L1730">1730</span>
<span id="L1731" rel="#L1731">1731</span>
<span id="L1732" rel="#L1732">1732</span>
<span id="L1733" rel="#L1733">1733</span>
<span id="L1734" rel="#L1734">1734</span>
<span id="L1735" rel="#L1735">1735</span>
<span id="L1736" rel="#L1736">1736</span>
<span id="L1737" rel="#L1737">1737</span>
<span id="L1738" rel="#L1738">1738</span>
<span id="L1739" rel="#L1739">1739</span>
<span id="L1740" rel="#L1740">1740</span>
<span id="L1741" rel="#L1741">1741</span>
<span id="L1742" rel="#L1742">1742</span>
<span id="L1743" rel="#L1743">1743</span>
<span id="L1744" rel="#L1744">1744</span>
<span id="L1745" rel="#L1745">1745</span>
<span id="L1746" rel="#L1746">1746</span>
<span id="L1747" rel="#L1747">1747</span>
<span id="L1748" rel="#L1748">1748</span>
<span id="L1749" rel="#L1749">1749</span>
<span id="L1750" rel="#L1750">1750</span>
<span id="L1751" rel="#L1751">1751</span>
<span id="L1752" rel="#L1752">1752</span>
<span id="L1753" rel="#L1753">1753</span>
<span id="L1754" rel="#L1754">1754</span>
<span id="L1755" rel="#L1755">1755</span>
<span id="L1756" rel="#L1756">1756</span>
<span id="L1757" rel="#L1757">1757</span>
<span id="L1758" rel="#L1758">1758</span>
<span id="L1759" rel="#L1759">1759</span>
<span id="L1760" rel="#L1760">1760</span>
<span id="L1761" rel="#L1761">1761</span>
<span id="L1762" rel="#L1762">1762</span>
<span id="L1763" rel="#L1763">1763</span>
<span id="L1764" rel="#L1764">1764</span>
<span id="L1765" rel="#L1765">1765</span>
<span id="L1766" rel="#L1766">1766</span>
<span id="L1767" rel="#L1767">1767</span>
<span id="L1768" rel="#L1768">1768</span>
<span id="L1769" rel="#L1769">1769</span>
<span id="L1770" rel="#L1770">1770</span>
<span id="L1771" rel="#L1771">1771</span>
<span id="L1772" rel="#L1772">1772</span>
<span id="L1773" rel="#L1773">1773</span>
<span id="L1774" rel="#L1774">1774</span>
<span id="L1775" rel="#L1775">1775</span>
<span id="L1776" rel="#L1776">1776</span>
<span id="L1777" rel="#L1777">1777</span>
<span id="L1778" rel="#L1778">1778</span>
<span id="L1779" rel="#L1779">1779</span>
<span id="L1780" rel="#L1780">1780</span>
<span id="L1781" rel="#L1781">1781</span>
<span id="L1782" rel="#L1782">1782</span>
<span id="L1783" rel="#L1783">1783</span>
<span id="L1784" rel="#L1784">1784</span>
<span id="L1785" rel="#L1785">1785</span>
<span id="L1786" rel="#L1786">1786</span>
<span id="L1787" rel="#L1787">1787</span>
<span id="L1788" rel="#L1788">1788</span>
<span id="L1789" rel="#L1789">1789</span>
<span id="L1790" rel="#L1790">1790</span>
<span id="L1791" rel="#L1791">1791</span>
<span id="L1792" rel="#L1792">1792</span>
<span id="L1793" rel="#L1793">1793</span>
<span id="L1794" rel="#L1794">1794</span>
<span id="L1795" rel="#L1795">1795</span>
<span id="L1796" rel="#L1796">1796</span>
<span id="L1797" rel="#L1797">1797</span>
<span id="L1798" rel="#L1798">1798</span>
<span id="L1799" rel="#L1799">1799</span>
<span id="L1800" rel="#L1800">1800</span>
<span id="L1801" rel="#L1801">1801</span>
<span id="L1802" rel="#L1802">1802</span>
<span id="L1803" rel="#L1803">1803</span>
<span id="L1804" rel="#L1804">1804</span>
<span id="L1805" rel="#L1805">1805</span>
<span id="L1806" rel="#L1806">1806</span>
<span id="L1807" rel="#L1807">1807</span>
<span id="L1808" rel="#L1808">1808</span>
<span id="L1809" rel="#L1809">1809</span>
<span id="L1810" rel="#L1810">1810</span>
<span id="L1811" rel="#L1811">1811</span>
<span id="L1812" rel="#L1812">1812</span>
<span id="L1813" rel="#L1813">1813</span>
<span id="L1814" rel="#L1814">1814</span>
<span id="L1815" rel="#L1815">1815</span>
<span id="L1816" rel="#L1816">1816</span>
<span id="L1817" rel="#L1817">1817</span>
<span id="L1818" rel="#L1818">1818</span>
<span id="L1819" rel="#L1819">1819</span>
<span id="L1820" rel="#L1820">1820</span>
<span id="L1821" rel="#L1821">1821</span>
<span id="L1822" rel="#L1822">1822</span>
<span id="L1823" rel="#L1823">1823</span>
<span id="L1824" rel="#L1824">1824</span>
<span id="L1825" rel="#L1825">1825</span>
<span id="L1826" rel="#L1826">1826</span>
<span id="L1827" rel="#L1827">1827</span>
<span id="L1828" rel="#L1828">1828</span>
<span id="L1829" rel="#L1829">1829</span>
<span id="L1830" rel="#L1830">1830</span>
<span id="L1831" rel="#L1831">1831</span>
<span id="L1832" rel="#L1832">1832</span>
<span id="L1833" rel="#L1833">1833</span>
<span id="L1834" rel="#L1834">1834</span>
<span id="L1835" rel="#L1835">1835</span>
<span id="L1836" rel="#L1836">1836</span>
<span id="L1837" rel="#L1837">1837</span>
<span id="L1838" rel="#L1838">1838</span>
<span id="L1839" rel="#L1839">1839</span>
<span id="L1840" rel="#L1840">1840</span>
<span id="L1841" rel="#L1841">1841</span>
<span id="L1842" rel="#L1842">1842</span>
<span id="L1843" rel="#L1843">1843</span>
<span id="L1844" rel="#L1844">1844</span>
<span id="L1845" rel="#L1845">1845</span>
<span id="L1846" rel="#L1846">1846</span>
<span id="L1847" rel="#L1847">1847</span>
<span id="L1848" rel="#L1848">1848</span>
<span id="L1849" rel="#L1849">1849</span>
<span id="L1850" rel="#L1850">1850</span>
<span id="L1851" rel="#L1851">1851</span>
<span id="L1852" rel="#L1852">1852</span>
<span id="L1853" rel="#L1853">1853</span>
<span id="L1854" rel="#L1854">1854</span>
<span id="L1855" rel="#L1855">1855</span>
<span id="L1856" rel="#L1856">1856</span>
<span id="L1857" rel="#L1857">1857</span>
<span id="L1858" rel="#L1858">1858</span>
<span id="L1859" rel="#L1859">1859</span>
<span id="L1860" rel="#L1860">1860</span>
<span id="L1861" rel="#L1861">1861</span>
<span id="L1862" rel="#L1862">1862</span>
<span id="L1863" rel="#L1863">1863</span>
<span id="L1864" rel="#L1864">1864</span>
<span id="L1865" rel="#L1865">1865</span>
<span id="L1866" rel="#L1866">1866</span>
<span id="L1867" rel="#L1867">1867</span>
<span id="L1868" rel="#L1868">1868</span>
<span id="L1869" rel="#L1869">1869</span>
<span id="L1870" rel="#L1870">1870</span>
<span id="L1871" rel="#L1871">1871</span>
<span id="L1872" rel="#L1872">1872</span>
<span id="L1873" rel="#L1873">1873</span>
<span id="L1874" rel="#L1874">1874</span>
<span id="L1875" rel="#L1875">1875</span>
<span id="L1876" rel="#L1876">1876</span>
<span id="L1877" rel="#L1877">1877</span>
<span id="L1878" rel="#L1878">1878</span>
<span id="L1879" rel="#L1879">1879</span>
<span id="L1880" rel="#L1880">1880</span>
<span id="L1881" rel="#L1881">1881</span>
<span id="L1882" rel="#L1882">1882</span>
<span id="L1883" rel="#L1883">1883</span>
<span id="L1884" rel="#L1884">1884</span>
<span id="L1885" rel="#L1885">1885</span>
<span id="L1886" rel="#L1886">1886</span>
<span id="L1887" rel="#L1887">1887</span>
<span id="L1888" rel="#L1888">1888</span>
<span id="L1889" rel="#L1889">1889</span>
<span id="L1890" rel="#L1890">1890</span>
<span id="L1891" rel="#L1891">1891</span>
<span id="L1892" rel="#L1892">1892</span>
<span id="L1893" rel="#L1893">1893</span>
<span id="L1894" rel="#L1894">1894</span>
<span id="L1895" rel="#L1895">1895</span>
<span id="L1896" rel="#L1896">1896</span>
<span id="L1897" rel="#L1897">1897</span>
<span id="L1898" rel="#L1898">1898</span>
<span id="L1899" rel="#L1899">1899</span>
<span id="L1900" rel="#L1900">1900</span>
<span id="L1901" rel="#L1901">1901</span>
<span id="L1902" rel="#L1902">1902</span>
<span id="L1903" rel="#L1903">1903</span>
<span id="L1904" rel="#L1904">1904</span>
<span id="L1905" rel="#L1905">1905</span>
<span id="L1906" rel="#L1906">1906</span>
<span id="L1907" rel="#L1907">1907</span>
<span id="L1908" rel="#L1908">1908</span>
<span id="L1909" rel="#L1909">1909</span>
<span id="L1910" rel="#L1910">1910</span>
<span id="L1911" rel="#L1911">1911</span>
<span id="L1912" rel="#L1912">1912</span>
<span id="L1913" rel="#L1913">1913</span>
<span id="L1914" rel="#L1914">1914</span>
<span id="L1915" rel="#L1915">1915</span>
<span id="L1916" rel="#L1916">1916</span>
<span id="L1917" rel="#L1917">1917</span>
<span id="L1918" rel="#L1918">1918</span>
<span id="L1919" rel="#L1919">1919</span>
<span id="L1920" rel="#L1920">1920</span>
<span id="L1921" rel="#L1921">1921</span>
<span id="L1922" rel="#L1922">1922</span>
<span id="L1923" rel="#L1923">1923</span>
<span id="L1924" rel="#L1924">1924</span>
<span id="L1925" rel="#L1925">1925</span>
<span id="L1926" rel="#L1926">1926</span>
<span id="L1927" rel="#L1927">1927</span>
<span id="L1928" rel="#L1928">1928</span>
<span id="L1929" rel="#L1929">1929</span>
<span id="L1930" rel="#L1930">1930</span>
<span id="L1931" rel="#L1931">1931</span>
<span id="L1932" rel="#L1932">1932</span>
<span id="L1933" rel="#L1933">1933</span>
<span id="L1934" rel="#L1934">1934</span>
<span id="L1935" rel="#L1935">1935</span>
<span id="L1936" rel="#L1936">1936</span>
<span id="L1937" rel="#L1937">1937</span>
<span id="L1938" rel="#L1938">1938</span>
<span id="L1939" rel="#L1939">1939</span>
<span id="L1940" rel="#L1940">1940</span>
<span id="L1941" rel="#L1941">1941</span>
<span id="L1942" rel="#L1942">1942</span>
<span id="L1943" rel="#L1943">1943</span>
<span id="L1944" rel="#L1944">1944</span>
<span id="L1945" rel="#L1945">1945</span>
<span id="L1946" rel="#L1946">1946</span>
<span id="L1947" rel="#L1947">1947</span>
<span id="L1948" rel="#L1948">1948</span>
<span id="L1949" rel="#L1949">1949</span>
<span id="L1950" rel="#L1950">1950</span>
<span id="L1951" rel="#L1951">1951</span>
<span id="L1952" rel="#L1952">1952</span>
<span id="L1953" rel="#L1953">1953</span>
<span id="L1954" rel="#L1954">1954</span>
<span id="L1955" rel="#L1955">1955</span>
<span id="L1956" rel="#L1956">1956</span>
<span id="L1957" rel="#L1957">1957</span>
<span id="L1958" rel="#L1958">1958</span>
<span id="L1959" rel="#L1959">1959</span>
<span id="L1960" rel="#L1960">1960</span>
<span id="L1961" rel="#L1961">1961</span>
<span id="L1962" rel="#L1962">1962</span>
<span id="L1963" rel="#L1963">1963</span>
<span id="L1964" rel="#L1964">1964</span>
<span id="L1965" rel="#L1965">1965</span>
<span id="L1966" rel="#L1966">1966</span>
<span id="L1967" rel="#L1967">1967</span>
<span id="L1968" rel="#L1968">1968</span>
<span id="L1969" rel="#L1969">1969</span>
<span id="L1970" rel="#L1970">1970</span>
<span id="L1971" rel="#L1971">1971</span>
<span id="L1972" rel="#L1972">1972</span>
<span id="L1973" rel="#L1973">1973</span>
<span id="L1974" rel="#L1974">1974</span>
<span id="L1975" rel="#L1975">1975</span>
<span id="L1976" rel="#L1976">1976</span>
<span id="L1977" rel="#L1977">1977</span>
<span id="L1978" rel="#L1978">1978</span>
<span id="L1979" rel="#L1979">1979</span>
<span id="L1980" rel="#L1980">1980</span>
<span id="L1981" rel="#L1981">1981</span>
<span id="L1982" rel="#L1982">1982</span>
<span id="L1983" rel="#L1983">1983</span>
<span id="L1984" rel="#L1984">1984</span>
<span id="L1985" rel="#L1985">1985</span>
<span id="L1986" rel="#L1986">1986</span>
<span id="L1987" rel="#L1987">1987</span>
<span id="L1988" rel="#L1988">1988</span>
<span id="L1989" rel="#L1989">1989</span>
<span id="L1990" rel="#L1990">1990</span>
<span id="L1991" rel="#L1991">1991</span>
<span id="L1992" rel="#L1992">1992</span>
<span id="L1993" rel="#L1993">1993</span>
<span id="L1994" rel="#L1994">1994</span>
<span id="L1995" rel="#L1995">1995</span>
<span id="L1996" rel="#L1996">1996</span>
<span id="L1997" rel="#L1997">1997</span>
<span id="L1998" rel="#L1998">1998</span>
<span id="L1999" rel="#L1999">1999</span>
<span id="L2000" rel="#L2000">2000</span>
<span id="L2001" rel="#L2001">2001</span>
<span id="L2002" rel="#L2002">2002</span>
<span id="L2003" rel="#L2003">2003</span>
<span id="L2004" rel="#L2004">2004</span>
<span id="L2005" rel="#L2005">2005</span>
<span id="L2006" rel="#L2006">2006</span>
<span id="L2007" rel="#L2007">2007</span>
<span id="L2008" rel="#L2008">2008</span>
<span id="L2009" rel="#L2009">2009</span>
<span id="L2010" rel="#L2010">2010</span>
<span id="L2011" rel="#L2011">2011</span>
<span id="L2012" rel="#L2012">2012</span>
<span id="L2013" rel="#L2013">2013</span>
<span id="L2014" rel="#L2014">2014</span>
<span id="L2015" rel="#L2015">2015</span>
<span id="L2016" rel="#L2016">2016</span>
<span id="L2017" rel="#L2017">2017</span>
<span id="L2018" rel="#L2018">2018</span>
<span id="L2019" rel="#L2019">2019</span>
<span id="L2020" rel="#L2020">2020</span>
<span id="L2021" rel="#L2021">2021</span>
<span id="L2022" rel="#L2022">2022</span>
<span id="L2023" rel="#L2023">2023</span>
<span id="L2024" rel="#L2024">2024</span>
<span id="L2025" rel="#L2025">2025</span>
<span id="L2026" rel="#L2026">2026</span>
<span id="L2027" rel="#L2027">2027</span>
<span id="L2028" rel="#L2028">2028</span>
<span id="L2029" rel="#L2029">2029</span>
<span id="L2030" rel="#L2030">2030</span>
<span id="L2031" rel="#L2031">2031</span>
<span id="L2032" rel="#L2032">2032</span>
<span id="L2033" rel="#L2033">2033</span>
<span id="L2034" rel="#L2034">2034</span>
<span id="L2035" rel="#L2035">2035</span>
<span id="L2036" rel="#L2036">2036</span>
<span id="L2037" rel="#L2037">2037</span>
<span id="L2038" rel="#L2038">2038</span>
<span id="L2039" rel="#L2039">2039</span>
<span id="L2040" rel="#L2040">2040</span>
<span id="L2041" rel="#L2041">2041</span>
<span id="L2042" rel="#L2042">2042</span>
<span id="L2043" rel="#L2043">2043</span>
<span id="L2044" rel="#L2044">2044</span>
<span id="L2045" rel="#L2045">2045</span>
<span id="L2046" rel="#L2046">2046</span>
<span id="L2047" rel="#L2047">2047</span>
<span id="L2048" rel="#L2048">2048</span>
<span id="L2049" rel="#L2049">2049</span>
<span id="L2050" rel="#L2050">2050</span>
<span id="L2051" rel="#L2051">2051</span>
<span id="L2052" rel="#L2052">2052</span>
<span id="L2053" rel="#L2053">2053</span>
<span id="L2054" rel="#L2054">2054</span>
<span id="L2055" rel="#L2055">2055</span>
<span id="L2056" rel="#L2056">2056</span>
<span id="L2057" rel="#L2057">2057</span>
<span id="L2058" rel="#L2058">2058</span>
<span id="L2059" rel="#L2059">2059</span>
<span id="L2060" rel="#L2060">2060</span>
<span id="L2061" rel="#L2061">2061</span>
<span id="L2062" rel="#L2062">2062</span>
<span id="L2063" rel="#L2063">2063</span>
<span id="L2064" rel="#L2064">2064</span>
<span id="L2065" rel="#L2065">2065</span>
<span id="L2066" rel="#L2066">2066</span>
<span id="L2067" rel="#L2067">2067</span>
<span id="L2068" rel="#L2068">2068</span>
<span id="L2069" rel="#L2069">2069</span>
<span id="L2070" rel="#L2070">2070</span>
<span id="L2071" rel="#L2071">2071</span>
<span id="L2072" rel="#L2072">2072</span>
<span id="L2073" rel="#L2073">2073</span>
<span id="L2074" rel="#L2074">2074</span>
<span id="L2075" rel="#L2075">2075</span>
<span id="L2076" rel="#L2076">2076</span>
<span id="L2077" rel="#L2077">2077</span>
<span id="L2078" rel="#L2078">2078</span>
<span id="L2079" rel="#L2079">2079</span>
<span id="L2080" rel="#L2080">2080</span>
<span id="L2081" rel="#L2081">2081</span>
<span id="L2082" rel="#L2082">2082</span>
<span id="L2083" rel="#L2083">2083</span>
<span id="L2084" rel="#L2084">2084</span>
<span id="L2085" rel="#L2085">2085</span>
<span id="L2086" rel="#L2086">2086</span>
<span id="L2087" rel="#L2087">2087</span>
<span id="L2088" rel="#L2088">2088</span>
<span id="L2089" rel="#L2089">2089</span>
<span id="L2090" rel="#L2090">2090</span>
<span id="L2091" rel="#L2091">2091</span>
<span id="L2092" rel="#L2092">2092</span>
<span id="L2093" rel="#L2093">2093</span>
<span id="L2094" rel="#L2094">2094</span>
<span id="L2095" rel="#L2095">2095</span>
<span id="L2096" rel="#L2096">2096</span>
<span id="L2097" rel="#L2097">2097</span>
<span id="L2098" rel="#L2098">2098</span>
<span id="L2099" rel="#L2099">2099</span>
<span id="L2100" rel="#L2100">2100</span>
<span id="L2101" rel="#L2101">2101</span>
<span id="L2102" rel="#L2102">2102</span>
<span id="L2103" rel="#L2103">2103</span>
<span id="L2104" rel="#L2104">2104</span>
<span id="L2105" rel="#L2105">2105</span>
<span id="L2106" rel="#L2106">2106</span>
<span id="L2107" rel="#L2107">2107</span>
<span id="L2108" rel="#L2108">2108</span>
<span id="L2109" rel="#L2109">2109</span>
<span id="L2110" rel="#L2110">2110</span>
<span id="L2111" rel="#L2111">2111</span>
<span id="L2112" rel="#L2112">2112</span>
<span id="L2113" rel="#L2113">2113</span>
<span id="L2114" rel="#L2114">2114</span>
<span id="L2115" rel="#L2115">2115</span>
<span id="L2116" rel="#L2116">2116</span>
<span id="L2117" rel="#L2117">2117</span>
<span id="L2118" rel="#L2118">2118</span>
<span id="L2119" rel="#L2119">2119</span>
<span id="L2120" rel="#L2120">2120</span>
<span id="L2121" rel="#L2121">2121</span>
<span id="L2122" rel="#L2122">2122</span>
<span id="L2123" rel="#L2123">2123</span>
<span id="L2124" rel="#L2124">2124</span>
<span id="L2125" rel="#L2125">2125</span>
<span id="L2126" rel="#L2126">2126</span>
<span id="L2127" rel="#L2127">2127</span>
<span id="L2128" rel="#L2128">2128</span>
<span id="L2129" rel="#L2129">2129</span>
<span id="L2130" rel="#L2130">2130</span>
<span id="L2131" rel="#L2131">2131</span>
<span id="L2132" rel="#L2132">2132</span>
<span id="L2133" rel="#L2133">2133</span>
<span id="L2134" rel="#L2134">2134</span>
<span id="L2135" rel="#L2135">2135</span>
<span id="L2136" rel="#L2136">2136</span>
<span id="L2137" rel="#L2137">2137</span>
<span id="L2138" rel="#L2138">2138</span>
<span id="L2139" rel="#L2139">2139</span>
<span id="L2140" rel="#L2140">2140</span>
<span id="L2141" rel="#L2141">2141</span>
<span id="L2142" rel="#L2142">2142</span>
<span id="L2143" rel="#L2143">2143</span>
<span id="L2144" rel="#L2144">2144</span>
<span id="L2145" rel="#L2145">2145</span>
<span id="L2146" rel="#L2146">2146</span>
<span id="L2147" rel="#L2147">2147</span>
<span id="L2148" rel="#L2148">2148</span>
<span id="L2149" rel="#L2149">2149</span>
<span id="L2150" rel="#L2150">2150</span>
<span id="L2151" rel="#L2151">2151</span>
<span id="L2152" rel="#L2152">2152</span>
<span id="L2153" rel="#L2153">2153</span>
<span id="L2154" rel="#L2154">2154</span>
<span id="L2155" rel="#L2155">2155</span>
<span id="L2156" rel="#L2156">2156</span>
<span id="L2157" rel="#L2157">2157</span>
<span id="L2158" rel="#L2158">2158</span>
<span id="L2159" rel="#L2159">2159</span>
<span id="L2160" rel="#L2160">2160</span>
<span id="L2161" rel="#L2161">2161</span>
<span id="L2162" rel="#L2162">2162</span>
<span id="L2163" rel="#L2163">2163</span>
<span id="L2164" rel="#L2164">2164</span>
<span id="L2165" rel="#L2165">2165</span>
<span id="L2166" rel="#L2166">2166</span>
<span id="L2167" rel="#L2167">2167</span>
<span id="L2168" rel="#L2168">2168</span>
<span id="L2169" rel="#L2169">2169</span>
<span id="L2170" rel="#L2170">2170</span>
<span id="L2171" rel="#L2171">2171</span>
<span id="L2172" rel="#L2172">2172</span>
<span id="L2173" rel="#L2173">2173</span>
<span id="L2174" rel="#L2174">2174</span>
<span id="L2175" rel="#L2175">2175</span>
<span id="L2176" rel="#L2176">2176</span>
<span id="L2177" rel="#L2177">2177</span>
<span id="L2178" rel="#L2178">2178</span>
<span id="L2179" rel="#L2179">2179</span>
<span id="L2180" rel="#L2180">2180</span>
<span id="L2181" rel="#L2181">2181</span>
<span id="L2182" rel="#L2182">2182</span>
<span id="L2183" rel="#L2183">2183</span>
<span id="L2184" rel="#L2184">2184</span>
<span id="L2185" rel="#L2185">2185</span>
<span id="L2186" rel="#L2186">2186</span>
<span id="L2187" rel="#L2187">2187</span>
<span id="L2188" rel="#L2188">2188</span>
<span id="L2189" rel="#L2189">2189</span>
<span id="L2190" rel="#L2190">2190</span>
<span id="L2191" rel="#L2191">2191</span>
<span id="L2192" rel="#L2192">2192</span>
<span id="L2193" rel="#L2193">2193</span>
<span id="L2194" rel="#L2194">2194</span>
<span id="L2195" rel="#L2195">2195</span>
<span id="L2196" rel="#L2196">2196</span>
<span id="L2197" rel="#L2197">2197</span>
<span id="L2198" rel="#L2198">2198</span>
<span id="L2199" rel="#L2199">2199</span>
<span id="L2200" rel="#L2200">2200</span>
<span id="L2201" rel="#L2201">2201</span>
<span id="L2202" rel="#L2202">2202</span>
<span id="L2203" rel="#L2203">2203</span>
<span id="L2204" rel="#L2204">2204</span>
<span id="L2205" rel="#L2205">2205</span>
<span id="L2206" rel="#L2206">2206</span>
<span id="L2207" rel="#L2207">2207</span>
<span id="L2208" rel="#L2208">2208</span>
<span id="L2209" rel="#L2209">2209</span>
<span id="L2210" rel="#L2210">2210</span>
<span id="L2211" rel="#L2211">2211</span>
<span id="L2212" rel="#L2212">2212</span>
<span id="L2213" rel="#L2213">2213</span>
<span id="L2214" rel="#L2214">2214</span>
<span id="L2215" rel="#L2215">2215</span>
<span id="L2216" rel="#L2216">2216</span>
<span id="L2217" rel="#L2217">2217</span>
<span id="L2218" rel="#L2218">2218</span>
<span id="L2219" rel="#L2219">2219</span>
<span id="L2220" rel="#L2220">2220</span>
<span id="L2221" rel="#L2221">2221</span>
<span id="L2222" rel="#L2222">2222</span>
<span id="L2223" rel="#L2223">2223</span>
<span id="L2224" rel="#L2224">2224</span>
<span id="L2225" rel="#L2225">2225</span>
<span id="L2226" rel="#L2226">2226</span>
<span id="L2227" rel="#L2227">2227</span>
<span id="L2228" rel="#L2228">2228</span>
<span id="L2229" rel="#L2229">2229</span>
<span id="L2230" rel="#L2230">2230</span>
<span id="L2231" rel="#L2231">2231</span>
<span id="L2232" rel="#L2232">2232</span>
<span id="L2233" rel="#L2233">2233</span>
<span id="L2234" rel="#L2234">2234</span>
<span id="L2235" rel="#L2235">2235</span>
<span id="L2236" rel="#L2236">2236</span>
<span id="L2237" rel="#L2237">2237</span>
<span id="L2238" rel="#L2238">2238</span>
<span id="L2239" rel="#L2239">2239</span>
<span id="L2240" rel="#L2240">2240</span>
<span id="L2241" rel="#L2241">2241</span>
<span id="L2242" rel="#L2242">2242</span>
<span id="L2243" rel="#L2243">2243</span>
<span id="L2244" rel="#L2244">2244</span>
<span id="L2245" rel="#L2245">2245</span>
<span id="L2246" rel="#L2246">2246</span>
<span id="L2247" rel="#L2247">2247</span>
<span id="L2248" rel="#L2248">2248</span>
<span id="L2249" rel="#L2249">2249</span>
<span id="L2250" rel="#L2250">2250</span>
<span id="L2251" rel="#L2251">2251</span>
<span id="L2252" rel="#L2252">2252</span>
<span id="L2253" rel="#L2253">2253</span>
<span id="L2254" rel="#L2254">2254</span>
<span id="L2255" rel="#L2255">2255</span>
<span id="L2256" rel="#L2256">2256</span>
<span id="L2257" rel="#L2257">2257</span>
<span id="L2258" rel="#L2258">2258</span>
<span id="L2259" rel="#L2259">2259</span>
<span id="L2260" rel="#L2260">2260</span>
<span id="L2261" rel="#L2261">2261</span>
<span id="L2262" rel="#L2262">2262</span>
<span id="L2263" rel="#L2263">2263</span>
<span id="L2264" rel="#L2264">2264</span>
<span id="L2265" rel="#L2265">2265</span>
<span id="L2266" rel="#L2266">2266</span>
<span id="L2267" rel="#L2267">2267</span>
<span id="L2268" rel="#L2268">2268</span>
<span id="L2269" rel="#L2269">2269</span>
<span id="L2270" rel="#L2270">2270</span>
<span id="L2271" rel="#L2271">2271</span>
<span id="L2272" rel="#L2272">2272</span>
<span id="L2273" rel="#L2273">2273</span>
<span id="L2274" rel="#L2274">2274</span>
<span id="L2275" rel="#L2275">2275</span>
<span id="L2276" rel="#L2276">2276</span>
<span id="L2277" rel="#L2277">2277</span>
<span id="L2278" rel="#L2278">2278</span>
<span id="L2279" rel="#L2279">2279</span>
<span id="L2280" rel="#L2280">2280</span>
<span id="L2281" rel="#L2281">2281</span>
<span id="L2282" rel="#L2282">2282</span>
<span id="L2283" rel="#L2283">2283</span>
<span id="L2284" rel="#L2284">2284</span>
<span id="L2285" rel="#L2285">2285</span>
<span id="L2286" rel="#L2286">2286</span>
<span id="L2287" rel="#L2287">2287</span>
<span id="L2288" rel="#L2288">2288</span>
<span id="L2289" rel="#L2289">2289</span>
<span id="L2290" rel="#L2290">2290</span>
<span id="L2291" rel="#L2291">2291</span>
<span id="L2292" rel="#L2292">2292</span>
<span id="L2293" rel="#L2293">2293</span>
<span id="L2294" rel="#L2294">2294</span>
<span id="L2295" rel="#L2295">2295</span>
<span id="L2296" rel="#L2296">2296</span>
<span id="L2297" rel="#L2297">2297</span>
<span id="L2298" rel="#L2298">2298</span>
<span id="L2299" rel="#L2299">2299</span>
<span id="L2300" rel="#L2300">2300</span>
<span id="L2301" rel="#L2301">2301</span>
<span id="L2302" rel="#L2302">2302</span>
<span id="L2303" rel="#L2303">2303</span>
<span id="L2304" rel="#L2304">2304</span>
<span id="L2305" rel="#L2305">2305</span>
<span id="L2306" rel="#L2306">2306</span>
<span id="L2307" rel="#L2307">2307</span>
<span id="L2308" rel="#L2308">2308</span>
<span id="L2309" rel="#L2309">2309</span>
<span id="L2310" rel="#L2310">2310</span>
<span id="L2311" rel="#L2311">2311</span>
<span id="L2312" rel="#L2312">2312</span>
<span id="L2313" rel="#L2313">2313</span>
<span id="L2314" rel="#L2314">2314</span>
<span id="L2315" rel="#L2315">2315</span>
<span id="L2316" rel="#L2316">2316</span>
<span id="L2317" rel="#L2317">2317</span>
<span id="L2318" rel="#L2318">2318</span>
<span id="L2319" rel="#L2319">2319</span>
<span id="L2320" rel="#L2320">2320</span>
<span id="L2321" rel="#L2321">2321</span>
<span id="L2322" rel="#L2322">2322</span>
<span id="L2323" rel="#L2323">2323</span>
<span id="L2324" rel="#L2324">2324</span>
<span id="L2325" rel="#L2325">2325</span>
<span id="L2326" rel="#L2326">2326</span>
<span id="L2327" rel="#L2327">2327</span>
<span id="L2328" rel="#L2328">2328</span>
<span id="L2329" rel="#L2329">2329</span>
<span id="L2330" rel="#L2330">2330</span>
<span id="L2331" rel="#L2331">2331</span>
<span id="L2332" rel="#L2332">2332</span>
<span id="L2333" rel="#L2333">2333</span>
<span id="L2334" rel="#L2334">2334</span>
<span id="L2335" rel="#L2335">2335</span>
<span id="L2336" rel="#L2336">2336</span>
<span id="L2337" rel="#L2337">2337</span>
<span id="L2338" rel="#L2338">2338</span>
<span id="L2339" rel="#L2339">2339</span>
<span id="L2340" rel="#L2340">2340</span>
<span id="L2341" rel="#L2341">2341</span>
<span id="L2342" rel="#L2342">2342</span>
<span id="L2343" rel="#L2343">2343</span>
<span id="L2344" rel="#L2344">2344</span>
<span id="L2345" rel="#L2345">2345</span>
<span id="L2346" rel="#L2346">2346</span>
<span id="L2347" rel="#L2347">2347</span>
<span id="L2348" rel="#L2348">2348</span>
<span id="L2349" rel="#L2349">2349</span>
<span id="L2350" rel="#L2350">2350</span>
<span id="L2351" rel="#L2351">2351</span>
<span id="L2352" rel="#L2352">2352</span>
<span id="L2353" rel="#L2353">2353</span>
<span id="L2354" rel="#L2354">2354</span>
<span id="L2355" rel="#L2355">2355</span>
<span id="L2356" rel="#L2356">2356</span>
<span id="L2357" rel="#L2357">2357</span>
<span id="L2358" rel="#L2358">2358</span>
<span id="L2359" rel="#L2359">2359</span>
<span id="L2360" rel="#L2360">2360</span>
<span id="L2361" rel="#L2361">2361</span>
<span id="L2362" rel="#L2362">2362</span>
<span id="L2363" rel="#L2363">2363</span>
<span id="L2364" rel="#L2364">2364</span>
<span id="L2365" rel="#L2365">2365</span>
<span id="L2366" rel="#L2366">2366</span>
<span id="L2367" rel="#L2367">2367</span>
<span id="L2368" rel="#L2368">2368</span>
<span id="L2369" rel="#L2369">2369</span>
<span id="L2370" rel="#L2370">2370</span>
<span id="L2371" rel="#L2371">2371</span>
<span id="L2372" rel="#L2372">2372</span>
<span id="L2373" rel="#L2373">2373</span>
<span id="L2374" rel="#L2374">2374</span>
<span id="L2375" rel="#L2375">2375</span>
<span id="L2376" rel="#L2376">2376</span>
<span id="L2377" rel="#L2377">2377</span>
<span id="L2378" rel="#L2378">2378</span>
<span id="L2379" rel="#L2379">2379</span>
<span id="L2380" rel="#L2380">2380</span>
<span id="L2381" rel="#L2381">2381</span>
<span id="L2382" rel="#L2382">2382</span>
<span id="L2383" rel="#L2383">2383</span>
<span id="L2384" rel="#L2384">2384</span>
<span id="L2385" rel="#L2385">2385</span>
<span id="L2386" rel="#L2386">2386</span>
<span id="L2387" rel="#L2387">2387</span>
<span id="L2388" rel="#L2388">2388</span>
<span id="L2389" rel="#L2389">2389</span>
<span id="L2390" rel="#L2390">2390</span>
<span id="L2391" rel="#L2391">2391</span>
<span id="L2392" rel="#L2392">2392</span>
<span id="L2393" rel="#L2393">2393</span>
<span id="L2394" rel="#L2394">2394</span>
<span id="L2395" rel="#L2395">2395</span>
<span id="L2396" rel="#L2396">2396</span>
<span id="L2397" rel="#L2397">2397</span>
<span id="L2398" rel="#L2398">2398</span>
<span id="L2399" rel="#L2399">2399</span>
<span id="L2400" rel="#L2400">2400</span>
<span id="L2401" rel="#L2401">2401</span>
<span id="L2402" rel="#L2402">2402</span>
<span id="L2403" rel="#L2403">2403</span>
<span id="L2404" rel="#L2404">2404</span>
<span id="L2405" rel="#L2405">2405</span>
<span id="L2406" rel="#L2406">2406</span>
<span id="L2407" rel="#L2407">2407</span>
<span id="L2408" rel="#L2408">2408</span>
<span id="L2409" rel="#L2409">2409</span>
<span id="L2410" rel="#L2410">2410</span>
<span id="L2411" rel="#L2411">2411</span>
<span id="L2412" rel="#L2412">2412</span>
<span id="L2413" rel="#L2413">2413</span>
<span id="L2414" rel="#L2414">2414</span>
<span id="L2415" rel="#L2415">2415</span>
<span id="L2416" rel="#L2416">2416</span>
<span id="L2417" rel="#L2417">2417</span>
<span id="L2418" rel="#L2418">2418</span>
<span id="L2419" rel="#L2419">2419</span>
<span id="L2420" rel="#L2420">2420</span>
<span id="L2421" rel="#L2421">2421</span>
<span id="L2422" rel="#L2422">2422</span>
<span id="L2423" rel="#L2423">2423</span>
<span id="L2424" rel="#L2424">2424</span>
<span id="L2425" rel="#L2425">2425</span>
<span id="L2426" rel="#L2426">2426</span>
<span id="L2427" rel="#L2427">2427</span>
<span id="L2428" rel="#L2428">2428</span>
<span id="L2429" rel="#L2429">2429</span>
<span id="L2430" rel="#L2430">2430</span>
<span id="L2431" rel="#L2431">2431</span>
<span id="L2432" rel="#L2432">2432</span>
<span id="L2433" rel="#L2433">2433</span>
<span id="L2434" rel="#L2434">2434</span>
<span id="L2435" rel="#L2435">2435</span>
<span id="L2436" rel="#L2436">2436</span>
<span id="L2437" rel="#L2437">2437</span>
<span id="L2438" rel="#L2438">2438</span>
<span id="L2439" rel="#L2439">2439</span>
<span id="L2440" rel="#L2440">2440</span>
<span id="L2441" rel="#L2441">2441</span>
<span id="L2442" rel="#L2442">2442</span>
<span id="L2443" rel="#L2443">2443</span>
<span id="L2444" rel="#L2444">2444</span>
<span id="L2445" rel="#L2445">2445</span>
<span id="L2446" rel="#L2446">2446</span>
<span id="L2447" rel="#L2447">2447</span>
<span id="L2448" rel="#L2448">2448</span>
<span id="L2449" rel="#L2449">2449</span>
<span id="L2450" rel="#L2450">2450</span>
<span id="L2451" rel="#L2451">2451</span>
<span id="L2452" rel="#L2452">2452</span>
<span id="L2453" rel="#L2453">2453</span>
<span id="L2454" rel="#L2454">2454</span>
<span id="L2455" rel="#L2455">2455</span>
<span id="L2456" rel="#L2456">2456</span>
<span id="L2457" rel="#L2457">2457</span>
<span id="L2458" rel="#L2458">2458</span>
<span id="L2459" rel="#L2459">2459</span>
<span id="L2460" rel="#L2460">2460</span>
<span id="L2461" rel="#L2461">2461</span>
<span id="L2462" rel="#L2462">2462</span>
<span id="L2463" rel="#L2463">2463</span>
<span id="L2464" rel="#L2464">2464</span>
<span id="L2465" rel="#L2465">2465</span>
<span id="L2466" rel="#L2466">2466</span>
<span id="L2467" rel="#L2467">2467</span>
<span id="L2468" rel="#L2468">2468</span>
<span id="L2469" rel="#L2469">2469</span>
<span id="L2470" rel="#L2470">2470</span>
<span id="L2471" rel="#L2471">2471</span>
<span id="L2472" rel="#L2472">2472</span>
<span id="L2473" rel="#L2473">2473</span>
<span id="L2474" rel="#L2474">2474</span>
<span id="L2475" rel="#L2475">2475</span>
<span id="L2476" rel="#L2476">2476</span>
<span id="L2477" rel="#L2477">2477</span>
<span id="L2478" rel="#L2478">2478</span>
<span id="L2479" rel="#L2479">2479</span>
<span id="L2480" rel="#L2480">2480</span>
<span id="L2481" rel="#L2481">2481</span>
<span id="L2482" rel="#L2482">2482</span>
<span id="L2483" rel="#L2483">2483</span>
<span id="L2484" rel="#L2484">2484</span>
<span id="L2485" rel="#L2485">2485</span>
<span id="L2486" rel="#L2486">2486</span>
<span id="L2487" rel="#L2487">2487</span>
<span id="L2488" rel="#L2488">2488</span>
<span id="L2489" rel="#L2489">2489</span>
<span id="L2490" rel="#L2490">2490</span>
<span id="L2491" rel="#L2491">2491</span>
<span id="L2492" rel="#L2492">2492</span>
<span id="L2493" rel="#L2493">2493</span>
<span id="L2494" rel="#L2494">2494</span>
<span id="L2495" rel="#L2495">2495</span>
<span id="L2496" rel="#L2496">2496</span>
<span id="L2497" rel="#L2497">2497</span>
<span id="L2498" rel="#L2498">2498</span>
<span id="L2499" rel="#L2499">2499</span>
<span id="L2500" rel="#L2500">2500</span>
<span id="L2501" rel="#L2501">2501</span>
<span id="L2502" rel="#L2502">2502</span>
<span id="L2503" rel="#L2503">2503</span>
<span id="L2504" rel="#L2504">2504</span>
<span id="L2505" rel="#L2505">2505</span>
<span id="L2506" rel="#L2506">2506</span>
<span id="L2507" rel="#L2507">2507</span>
<span id="L2508" rel="#L2508">2508</span>
<span id="L2509" rel="#L2509">2509</span>
<span id="L2510" rel="#L2510">2510</span>
<span id="L2511" rel="#L2511">2511</span>
<span id="L2512" rel="#L2512">2512</span>
<span id="L2513" rel="#L2513">2513</span>
<span id="L2514" rel="#L2514">2514</span>
<span id="L2515" rel="#L2515">2515</span>
<span id="L2516" rel="#L2516">2516</span>
<span id="L2517" rel="#L2517">2517</span>
<span id="L2518" rel="#L2518">2518</span>
<span id="L2519" rel="#L2519">2519</span>
<span id="L2520" rel="#L2520">2520</span>
<span id="L2521" rel="#L2521">2521</span>
<span id="L2522" rel="#L2522">2522</span>
<span id="L2523" rel="#L2523">2523</span>
<span id="L2524" rel="#L2524">2524</span>
<span id="L2525" rel="#L2525">2525</span>
<span id="L2526" rel="#L2526">2526</span>
<span id="L2527" rel="#L2527">2527</span>
<span id="L2528" rel="#L2528">2528</span>
<span id="L2529" rel="#L2529">2529</span>
<span id="L2530" rel="#L2530">2530</span>
<span id="L2531" rel="#L2531">2531</span>
<span id="L2532" rel="#L2532">2532</span>
<span id="L2533" rel="#L2533">2533</span>
<span id="L2534" rel="#L2534">2534</span>
<span id="L2535" rel="#L2535">2535</span>
<span id="L2536" rel="#L2536">2536</span>
<span id="L2537" rel="#L2537">2537</span>
<span id="L2538" rel="#L2538">2538</span>
<span id="L2539" rel="#L2539">2539</span>
<span id="L2540" rel="#L2540">2540</span>
<span id="L2541" rel="#L2541">2541</span>
<span id="L2542" rel="#L2542">2542</span>
<span id="L2543" rel="#L2543">2543</span>
<span id="L2544" rel="#L2544">2544</span>
<span id="L2545" rel="#L2545">2545</span>
<span id="L2546" rel="#L2546">2546</span>
<span id="L2547" rel="#L2547">2547</span>
<span id="L2548" rel="#L2548">2548</span>
<span id="L2549" rel="#L2549">2549</span>
<span id="L2550" rel="#L2550">2550</span>
<span id="L2551" rel="#L2551">2551</span>
<span id="L2552" rel="#L2552">2552</span>
<span id="L2553" rel="#L2553">2553</span>
<span id="L2554" rel="#L2554">2554</span>
<span id="L2555" rel="#L2555">2555</span>
<span id="L2556" rel="#L2556">2556</span>
<span id="L2557" rel="#L2557">2557</span>
<span id="L2558" rel="#L2558">2558</span>
<span id="L2559" rel="#L2559">2559</span>
<span id="L2560" rel="#L2560">2560</span>
<span id="L2561" rel="#L2561">2561</span>
<span id="L2562" rel="#L2562">2562</span>
<span id="L2563" rel="#L2563">2563</span>
<span id="L2564" rel="#L2564">2564</span>
<span id="L2565" rel="#L2565">2565</span>
<span id="L2566" rel="#L2566">2566</span>
<span id="L2567" rel="#L2567">2567</span>
<span id="L2568" rel="#L2568">2568</span>
<span id="L2569" rel="#L2569">2569</span>
<span id="L2570" rel="#L2570">2570</span>
<span id="L2571" rel="#L2571">2571</span>
<span id="L2572" rel="#L2572">2572</span>
<span id="L2573" rel="#L2573">2573</span>
<span id="L2574" rel="#L2574">2574</span>
<span id="L2575" rel="#L2575">2575</span>
<span id="L2576" rel="#L2576">2576</span>
<span id="L2577" rel="#L2577">2577</span>
<span id="L2578" rel="#L2578">2578</span>
<span id="L2579" rel="#L2579">2579</span>
<span id="L2580" rel="#L2580">2580</span>
<span id="L2581" rel="#L2581">2581</span>
<span id="L2582" rel="#L2582">2582</span>
<span id="L2583" rel="#L2583">2583</span>
<span id="L2584" rel="#L2584">2584</span>
<span id="L2585" rel="#L2585">2585</span>
<span id="L2586" rel="#L2586">2586</span>
<span id="L2587" rel="#L2587">2587</span>
<span id="L2588" rel="#L2588">2588</span>
<span id="L2589" rel="#L2589">2589</span>
<span id="L2590" rel="#L2590">2590</span>
<span id="L2591" rel="#L2591">2591</span>
<span id="L2592" rel="#L2592">2592</span>
<span id="L2593" rel="#L2593">2593</span>
<span id="L2594" rel="#L2594">2594</span>
<span id="L2595" rel="#L2595">2595</span>
<span id="L2596" rel="#L2596">2596</span>
<span id="L2597" rel="#L2597">2597</span>
<span id="L2598" rel="#L2598">2598</span>
<span id="L2599" rel="#L2599">2599</span>
<span id="L2600" rel="#L2600">2600</span>
<span id="L2601" rel="#L2601">2601</span>
<span id="L2602" rel="#L2602">2602</span>
<span id="L2603" rel="#L2603">2603</span>
<span id="L2604" rel="#L2604">2604</span>
<span id="L2605" rel="#L2605">2605</span>
<span id="L2606" rel="#L2606">2606</span>
<span id="L2607" rel="#L2607">2607</span>
<span id="L2608" rel="#L2608">2608</span>
<span id="L2609" rel="#L2609">2609</span>
<span id="L2610" rel="#L2610">2610</span>
<span id="L2611" rel="#L2611">2611</span>
<span id="L2612" rel="#L2612">2612</span>
<span id="L2613" rel="#L2613">2613</span>
<span id="L2614" rel="#L2614">2614</span>
<span id="L2615" rel="#L2615">2615</span>
<span id="L2616" rel="#L2616">2616</span>
<span id="L2617" rel="#L2617">2617</span>
<span id="L2618" rel="#L2618">2618</span>
<span id="L2619" rel="#L2619">2619</span>
<span id="L2620" rel="#L2620">2620</span>
<span id="L2621" rel="#L2621">2621</span>
<span id="L2622" rel="#L2622">2622</span>
<span id="L2623" rel="#L2623">2623</span>
<span id="L2624" rel="#L2624">2624</span>
<span id="L2625" rel="#L2625">2625</span>
<span id="L2626" rel="#L2626">2626</span>
<span id="L2627" rel="#L2627">2627</span>
<span id="L2628" rel="#L2628">2628</span>
<span id="L2629" rel="#L2629">2629</span>
<span id="L2630" rel="#L2630">2630</span>
<span id="L2631" rel="#L2631">2631</span>
<span id="L2632" rel="#L2632">2632</span>
<span id="L2633" rel="#L2633">2633</span>
<span id="L2634" rel="#L2634">2634</span>
<span id="L2635" rel="#L2635">2635</span>
<span id="L2636" rel="#L2636">2636</span>
<span id="L2637" rel="#L2637">2637</span>
<span id="L2638" rel="#L2638">2638</span>
<span id="L2639" rel="#L2639">2639</span>
<span id="L2640" rel="#L2640">2640</span>
<span id="L2641" rel="#L2641">2641</span>
<span id="L2642" rel="#L2642">2642</span>
<span id="L2643" rel="#L2643">2643</span>
<span id="L2644" rel="#L2644">2644</span>
<span id="L2645" rel="#L2645">2645</span>
<span id="L2646" rel="#L2646">2646</span>
<span id="L2647" rel="#L2647">2647</span>
<span id="L2648" rel="#L2648">2648</span>
<span id="L2649" rel="#L2649">2649</span>
<span id="L2650" rel="#L2650">2650</span>
<span id="L2651" rel="#L2651">2651</span>
<span id="L2652" rel="#L2652">2652</span>
<span id="L2653" rel="#L2653">2653</span>
<span id="L2654" rel="#L2654">2654</span>
<span id="L2655" rel="#L2655">2655</span>
<span id="L2656" rel="#L2656">2656</span>
<span id="L2657" rel="#L2657">2657</span>

            </td>
            <td class="blob-line-code">
                    <div class="code-body highlight"><pre><div class='line' id='LC1'><span class="c"># bash/zsh completion support for core Git.</span></div><div class='line' id='LC2'><span class="c">#</span></div><div class='line' id='LC3'><span class="c"># Copyright (C) 2006,2007 Shawn O. Pearce &lt;spearce@spearce.org&gt;</span></div><div class='line' id='LC4'><span class="c"># Conceptually based on gitcompletion (http://gitweb.hawaga.org.uk/).</span></div><div class='line' id='LC5'><span class="c"># Distributed under the GNU General Public License, version 2.0.</span></div><div class='line' id='LC6'><span class="c">#</span></div><div class='line' id='LC7'><span class="c"># The contained completion routines provide support for completing:</span></div><div class='line' id='LC8'><span class="c">#</span></div><div class='line' id='LC9'><span class="c">#    *) local and remote branch names</span></div><div class='line' id='LC10'><span class="c">#    *) local and remote tag names</span></div><div class='line' id='LC11'><span class="c">#    *) .git/remotes file names</span></div><div class='line' id='LC12'><span class="c">#    *) git &#39;subcommands&#39;</span></div><div class='line' id='LC13'><span class="c">#    *) tree paths within &#39;ref:path/to/file&#39; expressions</span></div><div class='line' id='LC14'><span class="c">#    *) file paths within current working directory and index</span></div><div class='line' id='LC15'><span class="c">#    *) common --long-options</span></div><div class='line' id='LC16'><span class="c">#</span></div><div class='line' id='LC17'><span class="c"># To use these routines:</span></div><div class='line' id='LC18'><span class="c">#</span></div><div class='line' id='LC19'><span class="c">#    1) Copy this file to somewhere (e.g. ~/.git-completion.sh).</span></div><div class='line' id='LC20'><span class="c">#    2) Add the following line to your .bashrc/.zshrc:</span></div><div class='line' id='LC21'><span class="c">#        source ~/.git-completion.sh</span></div><div class='line' id='LC22'><span class="c">#    3) Consider changing your PS1 to also show the current branch,</span></div><div class='line' id='LC23'><span class="c">#       see git-prompt.sh for details.</span></div><div class='line' id='LC24'><br/></div><div class='line' id='LC25'><span class="k">case</span> <span class="s2">&quot;$COMP_WORDBREAKS&quot;</span> in</div><div class='line' id='LC26'>*:*<span class="o">)</span> : great <span class="p">;;</span></div><div class='line' id='LC27'>*<span class="o">)</span>   <span class="nv">COMP_WORDBREAKS</span><span class="o">=</span><span class="s2">&quot;$COMP_WORDBREAKS:&quot;</span></div><div class='line' id='LC28'><span class="k">esac</span></div><div class='line' id='LC29'><br/></div><div class='line' id='LC30'><span class="c"># __gitdir accepts 0 or 1 arguments (i.e., location)</span></div><div class='line' id='LC31'><span class="c"># returns location of .git repo</span></div><div class='line' id='LC32'>__gitdir <span class="o">()</span></div><div class='line' id='LC33'><span class="o">{</span></div><div class='line' id='LC34'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;${1-}&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC35'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> -n <span class="s2">&quot;${__git_dir-}&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC36'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$__git_dir&quot;</span></div><div class='line' id='LC37'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">elif</span> <span class="o">[</span> -n <span class="s2">&quot;${GIT_DIR-}&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC38'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">test</span> -d <span class="s2">&quot;${GIT_DIR-}&quot;</span> <span class="o">||</span> <span class="k">return </span>1</div><div class='line' id='LC39'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;$GIT_DIR&quot;</span></div><div class='line' id='LC40'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">elif</span> <span class="o">[</span> -d .git <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC41'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> .git</div><div class='line' id='LC42'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC43'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git rev-parse --git-dir 2&gt;/dev/null</div><div class='line' id='LC44'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC45'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;elif</span> <span class="o">[</span> -d <span class="s2">&quot;$1/.git&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC46'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$1/.git&quot;</span></div><div class='line' id='LC47'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC48'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$1&quot;</span></div><div class='line' id='LC49'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC50'><span class="o">}</span></div><div class='line' id='LC51'><br/></div><div class='line' id='LC52'><span class="c"># The following function is based on code from:</span></div><div class='line' id='LC53'><span class="c">#</span></div><div class='line' id='LC54'><span class="c">#   bash_completion - programmable completion functions for bash 3.2+</span></div><div class='line' id='LC55'><span class="c">#</span></div><div class='line' id='LC56'><span class="c">#   Copyright © 2006-2008, Ian Macdonald &lt;ian@caliban.org&gt;</span></div><div class='line' id='LC57'><span class="c">#             © 2009-2010, Bash Completion Maintainers</span></div><div class='line' id='LC58'><span class="c">#                     &lt;bash-completion-devel@lists.alioth.debian.org&gt;</span></div><div class='line' id='LC59'><span class="c">#</span></div><div class='line' id='LC60'><span class="c">#   This program is free software; you can redistribute it and/or modify</span></div><div class='line' id='LC61'><span class="c">#   it under the terms of the GNU General Public License as published by</span></div><div class='line' id='LC62'><span class="c">#   the Free Software Foundation; either version 2, or (at your option)</span></div><div class='line' id='LC63'><span class="c">#   any later version.</span></div><div class='line' id='LC64'><span class="c">#</span></div><div class='line' id='LC65'><span class="c">#   This program is distributed in the hope that it will be useful,</span></div><div class='line' id='LC66'><span class="c">#   but WITHOUT ANY WARRANTY; without even the implied warranty of</span></div><div class='line' id='LC67'><span class="c">#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the</span></div><div class='line' id='LC68'><span class="c">#   GNU General Public License for more details.</span></div><div class='line' id='LC69'><span class="c">#</span></div><div class='line' id='LC70'><span class="c">#   You should have received a copy of the GNU General Public License</span></div><div class='line' id='LC71'><span class="c">#   along with this program; if not, write to the Free Software Foundation,</span></div><div class='line' id='LC72'><span class="c">#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.</span></div><div class='line' id='LC73'><span class="c">#</span></div><div class='line' id='LC74'><span class="c">#   The latest version of this software can be obtained here:</span></div><div class='line' id='LC75'><span class="c">#</span></div><div class='line' id='LC76'><span class="c">#   http://bash-completion.alioth.debian.org/</span></div><div class='line' id='LC77'><span class="c">#</span></div><div class='line' id='LC78'><span class="c">#   RELEASE: 2.x</span></div><div class='line' id='LC79'><br/></div><div class='line' id='LC80'><span class="c"># This function can be used to access a tokenized list of words</span></div><div class='line' id='LC81'><span class="c"># on the command line:</span></div><div class='line' id='LC82'><span class="c">#</span></div><div class='line' id='LC83'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_reassemble_comp_words_by_ref &#39;=:&#39;</span></div><div class='line' id='LC84'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if test &quot;${words_[cword_-1]}&quot; = -w</span></div><div class='line' id='LC85'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;then</span></div><div class='line' id='LC86'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;...</span></div><div class='line' id='LC87'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC88'><span class="c">#</span></div><div class='line' id='LC89'><span class="c"># The argument should be a collection of characters from the list of</span></div><div class='line' id='LC90'><span class="c"># word completion separators (COMP_WORDBREAKS) to treat as ordinary</span></div><div class='line' id='LC91'><span class="c"># characters.</span></div><div class='line' id='LC92'><span class="c">#</span></div><div class='line' id='LC93'><span class="c"># This is roughly equivalent to going back in time and setting</span></div><div class='line' id='LC94'><span class="c"># COMP_WORDBREAKS to exclude those characters.  The intent is to</span></div><div class='line' id='LC95'><span class="c"># make option types like --date=&lt;type&gt; and &lt;rev&gt;:&lt;path&gt; easy to</span></div><div class='line' id='LC96'><span class="c"># recognize by treating each shell word as a single token.</span></div><div class='line' id='LC97'><span class="c">#</span></div><div class='line' id='LC98'><span class="c"># It is best not to set COMP_WORDBREAKS directly because the value is</span></div><div class='line' id='LC99'><span class="c"># shared with other completion scripts.  By the time the completion</span></div><div class='line' id='LC100'><span class="c"># function gets called, COMP_WORDS has already been populated so local</span></div><div class='line' id='LC101'><span class="c"># changes to COMP_WORDBREAKS have no effect.</span></div><div class='line' id='LC102'><span class="c">#</span></div><div class='line' id='LC103'><span class="c"># Output: words_, cword_, cur_.</span></div><div class='line' id='LC104'><br/></div><div class='line' id='LC105'>__git_reassemble_comp_words_by_ref<span class="o">()</span></div><div class='line' id='LC106'><span class="o">{</span></div><div class='line' id='LC107'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>exclude i j first</div><div class='line' id='LC108'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Which word separators to exclude?</span></div><div class='line' id='LC109'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">exclude</span><span class="o">=</span><span class="s2">&quot;${1//[^$COMP_WORDBREAKS]}&quot;</span></div><div class='line' id='LC110'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cword_</span><span class="o">=</span><span class="nv">$COMP_CWORD</span></div><div class='line' id='LC111'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$exclude&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC112'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">words_</span><span class="o">=(</span><span class="s2">&quot;${COMP_WORDS[@]}&quot;</span><span class="o">)</span></div><div class='line' id='LC113'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC114'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC115'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># List of word completion separators has shrunk;</span></div><div class='line' id='LC116'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># re-assemble words to complete.</span></div><div class='line' id='LC117'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for</span> <span class="o">((</span><span class="nv">i</span><span class="o">=</span>0, <span class="nv">j</span><span class="o">=</span>0<span class="p">;</span> i &lt; <span class="k">${#</span><span class="nv">COMP_WORDS</span><span class="p">[@]</span><span class="k">}</span><span class="p">;</span> i++, j++<span class="o">))</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC118'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Append each nonempty word consisting of just</span></div><div class='line' id='LC119'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># word separator characters to the current word.</span></div><div class='line' id='LC120'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">first</span><span class="o">=</span>t</div><div class='line' id='LC121'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span></div><div class='line' id='LC122'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">[</span> <span class="nv">$i</span> -gt 0 <span class="o">]</span> <span class="o">&amp;&amp;</span></div><div class='line' id='LC123'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">[</span> -n <span class="s2">&quot;${COMP_WORDS[$i]}&quot;</span> <span class="o">]</span> <span class="o">&amp;&amp;</span></div><div class='line' id='LC124'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># word consists of excluded word separators</span></div><div class='line' id='LC125'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">[</span> <span class="s2">&quot;${COMP_WORDS[$i]//[^$exclude]}&quot;</span> <span class="o">=</span> <span class="s2">&quot;${COMP_WORDS[$i]}&quot;</span> <span class="o">]</span></div><div class='line' id='LC126'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">do</span></div><div class='line' id='LC127'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Attach to the previous token,</span></div><div class='line' id='LC128'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># unless the previous token is the command name.</span></div><div class='line' id='LC129'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$j</span> -ge 2 <span class="o">]</span> <span class="o">&amp;&amp;</span> <span class="o">[</span> -n <span class="s2">&quot;$first&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC130'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>j--<span class="o">))</span></div><div class='line' id='LC131'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC132'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">first</span><span class="o">=</span></div><div class='line' id='LC133'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;words_<span class="o">[</span><span class="nv">$j</span><span class="o">]=</span><span class="k">${</span><span class="nv">words_</span><span class="p">[j]</span><span class="k">}${</span><span class="nv">COMP_WORDS</span><span class="p">[i]</span><span class="k">}</span></div><div class='line' id='LC134'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$i</span> <span class="o">=</span> <span class="nv">$COMP_CWORD</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC135'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">cword_</span><span class="o">=</span><span class="nv">$j</span></div><div class='line' id='LC136'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC137'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">((</span><span class="nv">$i</span> &lt; <span class="k">${#</span><span class="nv">COMP_WORDS</span><span class="p">[@]</span><span class="k">}</span> - 1<span class="o">))</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC138'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>i++<span class="o">))</span></div><div class='line' id='LC139'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC140'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Done.</span></div><div class='line' id='LC141'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC142'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC143'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC144'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>words_<span class="o">[</span><span class="nv">$j</span><span class="o">]=</span><span class="k">${</span><span class="nv">words_</span><span class="p">[j]</span><span class="k">}${</span><span class="nv">COMP_WORDS</span><span class="p">[i]</span><span class="k">}</span></div><div class='line' id='LC145'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$i</span> <span class="o">=</span> <span class="nv">$COMP_CWORD</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC146'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">cword_</span><span class="o">=</span><span class="nv">$j</span></div><div class='line' id='LC147'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC148'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC149'><span class="o">}</span></div><div class='line' id='LC150'><br/></div><div class='line' id='LC151'><span class="k">if</span> ! <span class="nb">type </span>_get_comp_words_by_ref &gt;/dev/null 2&gt;<span class="p">&amp;</span>1<span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC152'>_get_comp_words_by_ref <span class="o">()</span></div><div class='line' id='LC153'><span class="o">{</span></div><div class='line' id='LC154'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>exclude cur_ words_ cword_</div><div class='line' id='LC155'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="s2">&quot;$1&quot;</span> <span class="o">=</span> <span class="s2">&quot;-n&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC156'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">exclude</span><span class="o">=</span><span class="nv">$2</span></div><div class='line' id='LC157'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">shift </span>2</div><div class='line' id='LC158'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC159'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_reassemble_comp_words_by_ref <span class="s2">&quot;$exclude&quot;</span></div><div class='line' id='LC160'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="k">${</span><span class="nv">words_</span><span class="p">[cword_]</span><span class="k">}</span></div><div class='line' id='LC161'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$# </span>-gt 0 <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC162'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$1&quot;</span> in</div><div class='line' id='LC163'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cur<span class="o">)</span></div><div class='line' id='LC164'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur</span><span class="o">=</span><span class="nv">$cur_</span></div><div class='line' id='LC165'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC166'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prev<span class="o">)</span></div><div class='line' id='LC167'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">prev</span><span class="o">=</span><span class="k">${</span><span class="nv">words_</span><span class="p">[</span><span class="nv">$cword_</span><span class="p">-1]</span><span class="k">}</span></div><div class='line' id='LC168'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC169'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;words<span class="o">)</span></div><div class='line' id='LC170'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">words</span><span class="o">=(</span><span class="s2">&quot;${words_[@]}&quot;</span><span class="o">)</span></div><div class='line' id='LC171'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC172'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cword<span class="o">)</span></div><div class='line' id='LC173'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cword</span><span class="o">=</span><span class="nv">$cword_</span></div><div class='line' id='LC174'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC175'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC176'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">shift</span></div><div class='line' id='LC177'><span class="nb">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="k">done</span></div><div class='line' id='LC178'><span class="o">}</span></div><div class='line' id='LC179'><span class="k">fi</span></div><div class='line' id='LC180'><br/></div><div class='line' id='LC181'>__gitcompadd <span class="o">()</span></div><div class='line' id='LC182'><span class="o">{</span></div><div class='line' id='LC183'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">i</span><span class="o">=</span>0</div><div class='line' id='LC184'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>x in <span class="nv">$1</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC185'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[[</span> <span class="s2">&quot;$x&quot;</span> <span class="o">==</span> <span class="s2">&quot;$3&quot;</span>* <span class="o">]]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC186'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>COMPREPLY<span class="o">[</span>i++<span class="o">]=</span><span class="s2">&quot;$2$x$4&quot;</span></div><div class='line' id='LC187'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC188'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC189'><span class="o">}</span></div><div class='line' id='LC190'><br/></div><div class='line' id='LC191'><span class="c"># Generates completion reply, appending a space to possible completion words,</span></div><div class='line' id='LC192'><span class="c"># if necessary.</span></div><div class='line' id='LC193'><span class="c"># It accepts 1 to 4 arguments:</span></div><div class='line' id='LC194'><span class="c"># 1: List of possible completion words.</span></div><div class='line' id='LC195'><span class="c"># 2: A prefix to be added to each possible completion word (optional).</span></div><div class='line' id='LC196'><span class="c"># 3: Generate possible completion matches for this word (optional).</span></div><div class='line' id='LC197'><span class="c"># 4: A suffix to be appended to each possible completion word (optional).</span></div><div class='line' id='LC198'>__gitcomp <span class="o">()</span></div><div class='line' id='LC199'><span class="o">{</span></div><div class='line' id='LC200'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${3-$cur}&quot;</span></div><div class='line' id='LC201'><br/></div><div class='line' id='LC202'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC203'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">=)</span></div><div class='line' id='LC204'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC205'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC206'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>c <span class="nv">i</span><span class="o">=</span>0 <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39; \t\n&#39;</span></div><div class='line' id='LC207'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>c in <span class="nv">$1</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC208'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">c</span><span class="o">=</span><span class="s2">&quot;$c${4-}&quot;</span></div><div class='line' id='LC209'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[[</span> <span class="nv">$c</span> <span class="o">==</span> <span class="s2">&quot;$cur_&quot;</span>* <span class="o">]]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC210'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="nv">$c</span> in</div><div class='line' id='LC211'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">=</span>*<span class="p">|</span>*.<span class="o">)</span> <span class="p">;;</span></div><div class='line' id='LC212'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nv">c</span><span class="o">=</span><span class="s2">&quot;$c &quot;</span> <span class="p">;;</span></div><div class='line' id='LC213'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC214'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>COMPREPLY<span class="o">[</span>i++<span class="o">]=</span><span class="s2">&quot;${2-}$c&quot;</span></div><div class='line' id='LC215'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC216'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC217'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC218'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC219'><span class="o">}</span></div><div class='line' id='LC220'><br/></div><div class='line' id='LC221'><span class="c"># Generates completion reply from newline-separated possible completion words</span></div><div class='line' id='LC222'><span class="c"># by appending a space to all of them.</span></div><div class='line' id='LC223'><span class="c"># It accepts 1 to 4 arguments:</span></div><div class='line' id='LC224'><span class="c"># 1: List of possible completion words, separated by a single newline.</span></div><div class='line' id='LC225'><span class="c"># 2: A prefix to be added to each possible completion word (optional).</span></div><div class='line' id='LC226'><span class="c"># 3: Generate possible completion matches for this word (optional).</span></div><div class='line' id='LC227'><span class="c"># 4: A suffix to be appended to each possible completion word instead of</span></div><div class='line' id='LC228'><span class="c">#    the default space (optional).  If specified but empty, nothing is</span></div><div class='line' id='LC229'><span class="c">#    appended.</span></div><div class='line' id='LC230'>__gitcomp_nl <span class="o">()</span></div><div class='line' id='LC231'><span class="o">{</span></div><div class='line' id='LC232'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC233'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcompadd <span class="s2">&quot;$1&quot;</span> <span class="s2">&quot;${2-}&quot;</span> <span class="s2">&quot;${3-$cur}&quot;</span> <span class="s2">&quot;${4- }&quot;</span></div><div class='line' id='LC234'><span class="o">}</span></div><div class='line' id='LC235'><br/></div><div class='line' id='LC236'><span class="c"># Generates completion reply with compgen from newline-separated possible</span></div><div class='line' id='LC237'><span class="c"># completion filenames.</span></div><div class='line' id='LC238'><span class="c"># It accepts 1 to 3 arguments:</span></div><div class='line' id='LC239'><span class="c"># 1: List of possible completion filenames, separated by a single newline.</span></div><div class='line' id='LC240'><span class="c"># 2: A directory prefix to be added to each possible completion filename</span></div><div class='line' id='LC241'><span class="c">#    (optional).</span></div><div class='line' id='LC242'><span class="c"># 3: Generate possible completion matches for this word (optional).</span></div><div class='line' id='LC243'>__gitcomp_file <span class="o">()</span></div><div class='line' id='LC244'><span class="o">{</span></div><div class='line' id='LC245'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC246'><br/></div><div class='line' id='LC247'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># XXX does not work when the directory prefix contains a tilde,</span></div><div class='line' id='LC248'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># since tilde expansion is not applied.</span></div><div class='line' id='LC249'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># This means that COMPREPLY will be empty and Bash default</span></div><div class='line' id='LC250'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># completion will be used.</span></div><div class='line' id='LC251'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcompadd <span class="s2">&quot;$1&quot;</span> <span class="s2">&quot;${2-}&quot;</span> <span class="s2">&quot;${3-$cur}&quot;</span> <span class="s2">&quot;&quot;</span></div><div class='line' id='LC252'><br/></div><div class='line' id='LC253'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># use a hack to enable file mode in bash &lt; 4</span></div><div class='line' id='LC254'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compopt -o filenames +o nospace 2&gt;/dev/null <span class="o">||</span></div><div class='line' id='LC255'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">compgen</span> -f /non-existing-dir/ &gt; /dev/null</div><div class='line' id='LC256'><span class="o">}</span></div><div class='line' id='LC257'><br/></div><div class='line' id='LC258'><span class="c"># Execute &#39;git ls-files&#39;, unless the --committable option is specified, in</span></div><div class='line' id='LC259'><span class="c"># which case it runs &#39;git diff-index&#39; to find out the files that can be</span></div><div class='line' id='LC260'><span class="c"># committed.  It return paths relative to the directory specified in the first</span></div><div class='line' id='LC261'><span class="c"># argument, and using the options specified in the second argument.</span></div><div class='line' id='LC262'>__git_ls_files_helper <span class="o">()</span></div><div class='line' id='LC263'><span class="o">{</span></div><div class='line' id='LC264'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">(</span></div><div class='line' id='LC265'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">test</span> -n <span class="s2">&quot;${CDPATH+set}&quot;</span> <span class="o">&amp;&amp;</span> <span class="nb">unset </span>CDPATH</div><div class='line' id='LC266'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">cd</span> <span class="s2">&quot;$1&quot;</span></div><div class='line' id='LC267'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="s2">&quot;$2&quot;</span> <span class="o">==</span> <span class="s2">&quot;--committable&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC268'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git diff-index --name-only --relative HEAD</div><div class='line' id='LC269'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC270'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># NOTE: $2 is not quoted in order to support multiple options</span></div><div class='line' id='LC271'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git ls-files --exclude-standard <span class="nv">$2</span></div><div class='line' id='LC272'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC273'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">)</span> 2&gt;/dev/null</div><div class='line' id='LC274'><span class="o">}</span></div><div class='line' id='LC275'><br/></div><div class='line' id='LC276'><br/></div><div class='line' id='LC277'><span class="c"># __git_index_files accepts 1 or 2 arguments:</span></div><div class='line' id='LC278'><span class="c"># 1: Options to pass to ls-files (required).</span></div><div class='line' id='LC279'><span class="c"># 2: A directory path (optional).</span></div><div class='line' id='LC280'><span class="c">#    If provided, only files within the specified directory are listed.</span></div><div class='line' id='LC281'><span class="c">#    Sub directories are never recursed.  Path must have a trailing</span></div><div class='line' id='LC282'><span class="c">#    slash.</span></div><div class='line' id='LC283'>__git_index_files <span class="o">()</span></div><div class='line' id='LC284'><span class="o">{</span></div><div class='line' id='LC285'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> <span class="nv">root</span><span class="o">=</span><span class="s2">&quot;${2-.}&quot;</span> file</div><div class='line' id='LC286'><br/></div><div class='line' id='LC287'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC288'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_ls_files_helper <span class="s2">&quot;$root&quot;</span> <span class="s2">&quot;$1&quot;</span> <span class="p">|</span></div><div class='line' id='LC289'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while </span><span class="nb">read</span> -r file<span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC290'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$file&quot;</span> in</div><div class='line' id='LC291'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;?*/*<span class="o">)</span> <span class="nb">echo</span> <span class="s2">&quot;${file%%/*}&quot;</span> <span class="p">;;</span></div><div class='line' id='LC292'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nb">echo</span> <span class="s2">&quot;$file&quot;</span> <span class="p">;;</span></div><div class='line' id='LC293'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC294'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span> <span class="p">|</span> sort <span class="p">|</span> uniq</div><div class='line' id='LC295'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC296'><span class="o">}</span></div><div class='line' id='LC297'><br/></div><div class='line' id='LC298'>__git_heads <span class="o">()</span></div><div class='line' id='LC299'><span class="o">{</span></div><div class='line' id='LC300'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC301'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC302'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$dir&quot;</span> <span class="k">for</span>-each-ref --format<span class="o">=</span><span class="s1">&#39;%(refname:short)&#39;</span> <span class="se">\</span></div><div class='line' id='LC303'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refs/heads</div><div class='line' id='LC304'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC305'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC306'><span class="o">}</span></div><div class='line' id='LC307'><br/></div><div class='line' id='LC308'>__git_tags <span class="o">()</span></div><div class='line' id='LC309'><span class="o">{</span></div><div class='line' id='LC310'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC311'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC312'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$dir&quot;</span> <span class="k">for</span>-each-ref --format<span class="o">=</span><span class="s1">&#39;%(refname:short)&#39;</span> <span class="se">\</span></div><div class='line' id='LC313'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refs/tags</div><div class='line' id='LC314'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC315'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC316'><span class="o">}</span></div><div class='line' id='LC317'><br/></div><div class='line' id='LC318'><span class="c"># __git_refs accepts 0, 1 (to pass to __gitdir), or 2 arguments</span></div><div class='line' id='LC319'><span class="c"># presence of 2nd argument means use the guess heuristic employed</span></div><div class='line' id='LC320'><span class="c"># by checkout for tracking branches</span></div><div class='line' id='LC321'>__git_refs <span class="o">()</span></div><div class='line' id='LC322'><span class="o">{</span></div><div class='line' id='LC323'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nb">hash </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir &quot;</span><span class="k">${</span><span class="nv">1</span><span class="p">-</span><span class="k">}</span><span class="s2">&quot;)&quot;</span> <span class="nv">track</span><span class="o">=</span><span class="s2">&quot;${2-}&quot;</span></div><div class='line' id='LC324'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>format refs</div><div class='line' id='LC325'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC326'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC327'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refs<span class="p">|</span>refs/*<span class="o">)</span></div><div class='line' id='LC328'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">format</span><span class="o">=</span><span class="s2">&quot;refname&quot;</span></div><div class='line' id='LC329'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">refs</span><span class="o">=</span><span class="s2">&quot;${cur%/*}&quot;</span></div><div class='line' id='LC330'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">track</span><span class="o">=</span><span class="s2">&quot;&quot;</span></div><div class='line' id='LC331'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC332'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC333'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD<span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC334'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> -e <span class="s2">&quot;$dir/$i&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then </span><span class="nb">echo</span> <span class="nv">$i</span><span class="p">;</span> <span class="k">fi</span></div><div class='line' id='LC335'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC336'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">format</span><span class="o">=</span><span class="s2">&quot;refname:short&quot;</span></div><div class='line' id='LC337'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">refs</span><span class="o">=</span><span class="s2">&quot;refs/tags refs/heads refs/remotes&quot;</span></div><div class='line' id='LC338'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC339'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC340'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$dir&quot;</span> <span class="k">for</span>-each-ref --format<span class="o">=</span><span class="s2">&quot;%($format)&quot;</span> <span class="se">\</span></div><div class='line' id='LC341'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">$refs</span></div><div class='line' id='LC342'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -n <span class="s2">&quot;$track&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC343'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># employ the heuristic used by git checkout</span></div><div class='line' id='LC344'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Try to find a remote branch that matches the completion word</span></div><div class='line' id='LC345'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># but only output if the branch name is unique</span></div><div class='line' id='LC346'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>ref entry</div><div class='line' id='LC347'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git --git-dir<span class="o">=</span><span class="s2">&quot;$dir&quot;</span> <span class="k">for</span>-each-ref --shell --format<span class="o">=</span><span class="s2">&quot;ref=%(refname:short)&quot;</span> <span class="se">\</span></div><div class='line' id='LC348'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;refs/remotes/&quot;</span> <span class="p">|</span> <span class="se">\</span></div><div class='line' id='LC349'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while </span><span class="nb">read</span> -r entry<span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC350'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">eval</span> <span class="s2">&quot;$entry&quot;</span></div><div class='line' id='LC351'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">ref</span><span class="o">=</span><span class="s2">&quot;${ref#*/}&quot;</span></div><div class='line' id='LC352'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[[</span> <span class="s2">&quot;$ref&quot;</span> <span class="o">==</span> <span class="s2">&quot;$cur&quot;</span>* <span class="o">]]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC353'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$ref&quot;</span></div><div class='line' id='LC354'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC355'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span> <span class="p">|</span> sort <span class="p">|</span> uniq -u</div><div class='line' id='LC356'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC357'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return</span></div><div class='line' id='LC358'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC359'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC360'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refs<span class="p">|</span>refs/*<span class="o">)</span></div><div class='line' id='LC361'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git ls-remote <span class="s2">&quot;$dir&quot;</span> <span class="s2">&quot;$cur*&quot;</span> 2&gt;/dev/null <span class="p">|</span> <span class="se">\</span></div><div class='line' id='LC362'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while </span><span class="nb">read</span> -r <span class="nb">hash </span>i<span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC363'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC364'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*^<span class="o">{})</span> <span class="p">;;</span></div><div class='line' id='LC365'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nb">echo</span> <span class="s2">&quot;$i&quot;</span> <span class="p">;;</span></div><div class='line' id='LC366'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC367'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC368'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC369'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC370'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;HEAD&quot;</span></div><div class='line' id='LC371'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git <span class="k">for</span>-each-ref --format<span class="o">=</span><span class="s2">&quot;%(refname:short)&quot;</span> -- <span class="s2">&quot;refs/remotes/$dir/&quot;</span> <span class="p">|</span> sed -e <span class="s2">&quot;s#^$dir/##&quot;</span></div><div class='line' id='LC372'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC373'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC374'><span class="o">}</span></div><div class='line' id='LC375'><br/></div><div class='line' id='LC376'><span class="c"># __git_refs2 requires 1 argument (to pass to __git_refs)</span></div><div class='line' id='LC377'>__git_refs2 <span class="o">()</span></div><div class='line' id='LC378'><span class="o">{</span></div><div class='line' id='LC379'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i</div><div class='line' id='LC380'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>__git_refs <span class="s2">&quot;$1&quot;</span><span class="k">)</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC381'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$i:$i&quot;</span></div><div class='line' id='LC382'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC383'><span class="o">}</span></div><div class='line' id='LC384'><br/></div><div class='line' id='LC385'><span class="c"># __git_refs_remotes requires 1 argument (to pass to ls-remote)</span></div><div class='line' id='LC386'>__git_refs_remotes <span class="o">()</span></div><div class='line' id='LC387'><span class="o">{</span></div><div class='line' id='LC388'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nb">hash</span></div><div class='line' id='LC389'><span class="nb">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git ls-remote <span class="s2">&quot;$1&quot;</span> <span class="s1">&#39;refs/heads/*&#39;</span> 2&gt;/dev/null <span class="p">|</span> <span class="se">\</span></div><div class='line' id='LC390'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while </span><span class="nb">read</span> -r <span class="nb">hash </span>i<span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC391'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$i:refs/remotes/$1/${i#refs/heads/}&quot;</span></div><div class='line' id='LC392'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC393'><span class="o">}</span></div><div class='line' id='LC394'><br/></div><div class='line' id='LC395'>__git_remotes <span class="o">()</span></div><div class='line' id='LC396'><span class="o">{</span></div><div class='line' id='LC397'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span> <span class="nv">d</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC398'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">test</span> -d <span class="s2">&quot;$d/remotes&quot;</span> <span class="o">&amp;&amp;</span> ls -1 <span class="s2">&quot;$d/remotes&quot;</span></div><div class='line' id='LC399'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$d&quot;</span> config --get-regexp <span class="s1">&#39;remote\..*\.url&#39;</span> 2&gt;/dev/null<span class="k">)</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC400'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${i#remote.}&quot;</span></div><div class='line' id='LC401'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;${i/.url*/}&quot;</span></div><div class='line' id='LC402'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC403'><span class="o">}</span></div><div class='line' id='LC404'><br/></div><div class='line' id='LC405'>__git_list_merge_strategies <span class="o">()</span></div><div class='line' id='LC406'><span class="o">{</span></div><div class='line' id='LC407'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git merge -s <span class="nb">help </span>2&gt;<span class="p">&amp;</span>1 <span class="p">|</span></div><div class='line' id='LC408'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sed -n -e <span class="s1">&#39;/[Aa]vailable strategies are: /,/^$/{</span></div><div class='line' id='LC409'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;s/\.$//</span></div><div class='line' id='LC410'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;s/.*://</span></div><div class='line' id='LC411'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;s/^[ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]*//</span></div><div class='line' id='LC412'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;s/[ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]*$//</span></div><div class='line' id='LC413'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;p</span></div><div class='line' id='LC414'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}&#39;</span></div><div class='line' id='LC415'><span class="o">}</span></div><div class='line' id='LC416'><br/></div><div class='line' id='LC417'><span class="nv">__git_merge_strategies</span><span class="o">=</span></div><div class='line' id='LC418'><span class="c"># &#39;git merge -s help&#39; (and thus detection of the merge strategy</span></div><div class='line' id='LC419'><span class="c"># list) fails, unfortunately, if run outside of any git working</span></div><div class='line' id='LC420'><span class="c"># tree.  __git_merge_strategies is set to the empty string in</span></div><div class='line' id='LC421'><span class="c"># that case, and the detection will be repeated the next time it</span></div><div class='line' id='LC422'><span class="c"># is needed.</span></div><div class='line' id='LC423'>__git_compute_merge_strategies <span class="o">()</span></div><div class='line' id='LC424'><span class="o">{</span></div><div class='line' id='LC425'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">test</span> -n <span class="s2">&quot;$__git_merge_strategies&quot;</span> <span class="o">||</span></div><div class='line' id='LC426'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">__git_merge_strategies</span><span class="o">=</span><span class="k">$(</span>__git_list_merge_strategies<span class="k">)</span></div><div class='line' id='LC427'><span class="o">}</span></div><div class='line' id='LC428'><br/></div><div class='line' id='LC429'>__git_complete_revlist_file <span class="o">()</span></div><div class='line' id='LC430'><span class="o">{</span></div><div class='line' id='LC431'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>pfx ls ref <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;$cur&quot;</span></div><div class='line' id='LC432'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC433'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*..?*:*<span class="o">)</span></div><div class='line' id='LC434'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC435'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC436'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;?*:*<span class="o">)</span></div><div class='line' id='LC437'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">ref</span><span class="o">=</span><span class="s2">&quot;${cur_%%:*}&quot;</span></div><div class='line' id='LC438'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_#*:}&quot;</span></div><div class='line' id='LC439'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC440'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;?*/*<span class="o">)</span></div><div class='line' id='LC441'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur_%/*}&quot;</span></div><div class='line' id='LC442'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_##*/}&quot;</span></div><div class='line' id='LC443'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">ls</span><span class="o">=</span><span class="s2">&quot;$ref:$pfx&quot;</span></div><div class='line' id='LC444'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;$pfx/&quot;</span></div><div class='line' id='LC445'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC446'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC447'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">ls</span><span class="o">=</span><span class="s2">&quot;$ref&quot;</span></div><div class='line' id='LC448'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC449'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC450'><br/></div><div class='line' id='LC451'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$COMP_WORDBREAKS&quot;</span> in</div><div class='line' id='LC452'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*:*<span class="o">)</span> : great <span class="p">;;</span></div><div class='line' id='LC453'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span>   <span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;$ref:$pfx&quot;</span> <span class="p">;;</span></div><div class='line' id='LC454'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC455'><br/></div><div class='line' id='LC456'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(git --git-dir=&quot;</span><span class="k">$(</span>__gitdir<span class="k">)</span><span class="s2">&quot; ls-tree &quot;</span><span class="nv">$ls</span><span class="s2">&quot; 2&gt;/dev/null \</span></div><div class='line' id='LC457'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| sed &#39;/^100... blob /{</span></div><div class='line' id='LC458'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,^.*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;,,</span></div><div class='line' id='LC459'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,$, ,</span></div><div class='line' id='LC460'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       }</span></div><div class='line' id='LC461'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       /^120000 blob /{</span></div><div class='line' id='LC462'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,^.*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;,,</span></div><div class='line' id='LC463'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,$, ,</span></div><div class='line' id='LC464'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       }</span></div><div class='line' id='LC465'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       /^040000 tree /{</span></div><div class='line' id='LC466'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,^.*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;,,</span></div><div class='line' id='LC467'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;           s,$,/,</span></div><div class='line' id='LC468'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       }</span></div><div class='line' id='LC469'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       s/^.*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;//&#39;)&quot;</span> <span class="se">\</span></div><div class='line' id='LC470'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span> <span class="s2">&quot;&quot;</span></div><div class='line' id='LC471'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC472'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*...*<span class="o">)</span></div><div class='line' id='LC473'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur_%...*}...&quot;</span></div><div class='line' id='LC474'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_#*...}&quot;</span></div><div class='line' id='LC475'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC476'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC477'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*..*<span class="o">)</span></div><div class='line' id='LC478'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur_%..*}..&quot;</span></div><div class='line' id='LC479'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_#*..}&quot;</span></div><div class='line' id='LC480'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC481'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC482'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC483'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC484'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC485'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC486'><span class="o">}</span></div><div class='line' id='LC487'><br/></div><div class='line' id='LC488'><br/></div><div class='line' id='LC489'><span class="c"># __git_complete_index_file requires 1 argument:</span></div><div class='line' id='LC490'><span class="c"># 1: the options to pass to ls-file</span></div><div class='line' id='LC491'><span class="c">#</span></div><div class='line' id='LC492'><span class="c"># The exception is --committable, which finds the files appropriate commit.</span></div><div class='line' id='LC493'>__git_complete_index_file <span class="o">()</span></div><div class='line' id='LC494'><span class="o">{</span></div><div class='line' id='LC495'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;$cur&quot;</span></div><div class='line' id='LC496'><br/></div><div class='line' id='LC497'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC498'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;?*/*<span class="o">)</span></div><div class='line' id='LC499'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur_%/*}&quot;</span></div><div class='line' id='LC500'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_##*/}&quot;</span></div><div class='line' id='LC501'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${pfx}/&quot;</span></div><div class='line' id='LC502'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC503'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC504'><br/></div><div class='line' id='LC505'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_file <span class="s2">&quot;$(__git_index_files &quot;</span><span class="nv">$1</span><span class="s2">&quot; &quot;</span><span class="nv">$pfx</span><span class="s2">&quot;)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC506'><span class="o">}</span></div><div class='line' id='LC507'><br/></div><div class='line' id='LC508'>__git_complete_file <span class="o">()</span></div><div class='line' id='LC509'><span class="o">{</span></div><div class='line' id='LC510'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_revlist_file</div><div class='line' id='LC511'><span class="o">}</span></div><div class='line' id='LC512'><br/></div><div class='line' id='LC513'>__git_complete_revlist <span class="o">()</span></div><div class='line' id='LC514'><span class="o">{</span></div><div class='line' id='LC515'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_revlist_file</div><div class='line' id='LC516'><span class="o">}</span></div><div class='line' id='LC517'><br/></div><div class='line' id='LC518'>__git_complete_remote_or_refspec <span class="o">()</span></div><div class='line' id='LC519'><span class="o">{</span></div><div class='line' id='LC520'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;$cur&quot;</span> <span class="nv">cmd</span><span class="o">=</span><span class="s2">&quot;${words[1]}&quot;</span></div><div class='line' id='LC521'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">c</span><span class="o">=</span>2 <span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;&quot;</span> <span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;&quot;</span> <span class="nv">lhs</span><span class="o">=</span>1 <span class="nv">no_complete_refspec</span><span class="o">=</span>0</div><div class='line' id='LC522'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="s2">&quot;$cmd&quot;</span> <span class="o">=</span> <span class="s2">&quot;remote&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC523'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC524'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC525'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC526'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC527'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC528'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--mirror<span class="o">)</span> <span class="o">[</span> <span class="s2">&quot;$cmd&quot;</span> <span class="o">=</span> <span class="s2">&quot;push&quot;</span> <span class="o">]</span> <span class="o">&amp;&amp;</span> <span class="nv">no_complete_refspec</span><span class="o">=</span>1 <span class="p">;;</span></div><div class='line' id='LC529'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all<span class="o">)</span></div><div class='line' id='LC530'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cmd&quot;</span> in</div><div class='line' id='LC531'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;push<span class="o">)</span> <span class="nv">no_complete_refspec</span><span class="o">=</span>1 <span class="p">;;</span></div><div class='line' id='LC532'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch<span class="o">)</span></div><div class='line' id='LC533'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC534'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC535'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="p">;;</span></div><div class='line' id='LC536'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC537'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC538'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-*<span class="o">)</span> <span class="p">;;</span></div><div class='line' id='LC539'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;$i&quot;</span><span class="p">;</span> <span class="nb">break</span> <span class="p">;;</span></div><div class='line' id='LC540'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC541'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC542'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC543'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> -z <span class="s2">&quot;$remote&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC544'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC545'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC546'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC547'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> <span class="nv">$no_complete_refspec</span> <span class="o">=</span> 1 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC548'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return</span></div><div class='line' id='LC549'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC550'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">[</span> <span class="s2">&quot;$remote&quot;</span> <span class="o">=</span> <span class="s2">&quot;.&quot;</span> <span class="o">]</span> <span class="o">&amp;&amp;</span> <span class="nv">remote</span><span class="o">=</span></div><div class='line' id='LC551'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC552'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*:*<span class="o">)</span></div><div class='line' id='LC553'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$COMP_WORDBREAKS&quot;</span> in</div><div class='line' id='LC554'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*:*<span class="o">)</span> : great <span class="p">;;</span></div><div class='line' id='LC555'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span>   <span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur_%%:*}:&quot;</span> <span class="p">;;</span></div><div class='line' id='LC556'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC557'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_#*:}&quot;</span></div><div class='line' id='LC558'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">lhs</span><span class="o">=</span>0</div><div class='line' id='LC559'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC560'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+*<span class="o">)</span></div><div class='line' id='LC561'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;+&quot;</span></div><div class='line' id='LC562'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur_#+}&quot;</span></div><div class='line' id='LC563'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC564'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC565'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cmd&quot;</span> in</div><div class='line' id='LC566'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch<span class="o">)</span></div><div class='line' id='LC567'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$lhs</span> <span class="o">=</span> 1 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC568'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs2 &quot;</span><span class="nv">$remote</span><span class="s2">&quot;)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC569'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC570'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC571'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC572'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC573'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pull<span class="p">|</span>remote<span class="o">)</span></div><div class='line' id='LC574'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$lhs</span> <span class="o">=</span> 1 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC575'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs &quot;</span><span class="nv">$remote</span><span class="s2">&quot;)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC576'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC577'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC578'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC579'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC580'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;push<span class="o">)</span></div><div class='line' id='LC581'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$lhs</span> <span class="o">=</span> 1 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC582'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC583'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC584'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs &quot;</span><span class="nv">$remote</span><span class="s2">&quot;)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC585'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC586'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC587'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC588'><span class="o">}</span></div><div class='line' id='LC589'><br/></div><div class='line' id='LC590'>__git_complete_strategy <span class="o">()</span></div><div class='line' id='LC591'><span class="o">{</span></div><div class='line' id='LC592'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_compute_merge_strategies</div><div class='line' id='LC593'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC594'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-s<span class="p">|</span>--strategy<span class="o">)</span></div><div class='line' id='LC595'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_merge_strategies&quot;</span></div><div class='line' id='LC596'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return </span>0</div><div class='line' id='LC597'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC598'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC599'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--strategy<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC600'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_merge_strategies&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--strategy=}&quot;</span></div><div class='line' id='LC601'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return </span>0</div><div class='line' id='LC602'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC603'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC604'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return </span>1</div><div class='line' id='LC605'><span class="o">}</span></div><div class='line' id='LC606'><br/></div><div class='line' id='LC607'>__git_commands <span class="o">()</span> <span class="o">{</span></div><div class='line' id='LC608'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if </span><span class="nb">test</span> -n <span class="s2">&quot;${GIT_TESTING_COMMAND_COMPLETION:-}&quot;</span></div><div class='line' id='LC609'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">then</span></div><div class='line' id='LC610'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">printf</span> <span class="s2">&quot;%s&quot;</span> <span class="s2">&quot;${GIT_TESTING_COMMAND_COMPLETION}&quot;</span></div><div class='line' id='LC611'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC612'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git <span class="nb">help</span> -a<span class="p">|</span>egrep <span class="s1">&#39;^  [a-zA-Z0-9]&#39;</span></div><div class='line' id='LC613'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC614'><span class="o">}</span></div><div class='line' id='LC615'><br/></div><div class='line' id='LC616'>__git_list_all_commands <span class="o">()</span></div><div class='line' id='LC617'><span class="o">{</span></div><div class='line' id='LC618'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">IFS</span><span class="o">=</span><span class="s2">&quot; &quot;</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC619'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>__git_commands<span class="k">)</span></div><div class='line' id='LC620'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">do</span></div><div class='line' id='LC621'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="nv">$i</span> in</div><div class='line' id='LC622'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*--*<span class="o">)</span>             : helper pattern<span class="p">;;</span></div><div class='line' id='LC623'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nb">echo</span> <span class="nv">$i</span><span class="p">;;</span></div><div class='line' id='LC624'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC625'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC626'><span class="o">}</span></div><div class='line' id='LC627'><br/></div><div class='line' id='LC628'><span class="nv">__git_all_commands</span><span class="o">=</span></div><div class='line' id='LC629'>__git_compute_all_commands <span class="o">()</span></div><div class='line' id='LC630'><span class="o">{</span></div><div class='line' id='LC631'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">test</span> -n <span class="s2">&quot;$__git_all_commands&quot;</span> <span class="o">||</span></div><div class='line' id='LC632'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">__git_all_commands</span><span class="o">=</span><span class="k">$(</span>__git_list_all_commands<span class="k">)</span></div><div class='line' id='LC633'><span class="o">}</span></div><div class='line' id='LC634'><br/></div><div class='line' id='LC635'>__git_list_porcelain_commands <span class="o">()</span></div><div class='line' id='LC636'><span class="o">{</span></div><div class='line' id='LC637'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">IFS</span><span class="o">=</span><span class="s2">&quot; &quot;</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC638'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_compute_all_commands</div><div class='line' id='LC639'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="nv">$__git_all_commands</span></div><div class='line' id='LC640'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">do</span></div><div class='line' id='LC641'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="nv">$i</span> in</div><div class='line' id='LC642'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*--*<span class="o">)</span>             : helper pattern<span class="p">;;</span></div><div class='line' id='LC643'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;applymbox<span class="o">)</span>        : ask gittus<span class="p">;;</span></div><div class='line' id='LC644'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;applypatch<span class="o">)</span>       : ask gittus<span class="p">;;</span></div><div class='line' id='LC645'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;archimport<span class="o">)</span>       : import<span class="p">;;</span></div><div class='line' id='LC646'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cat-file<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC647'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;check-attr<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC648'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;check-ignore<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC649'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;check-mailmap<span class="o">)</span>    : plumbing<span class="p">;;</span></div><div class='line' id='LC650'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;check-ref-format<span class="o">)</span> : plumbing<span class="p">;;</span></div><div class='line' id='LC651'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;checkout-index<span class="o">)</span>   : plumbing<span class="p">;;</span></div><div class='line' id='LC652'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commit-tree<span class="o">)</span>      : plumbing<span class="p">;;</span></div><div class='line' id='LC653'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;count-objects<span class="o">)</span>    : infrequent<span class="p">;;</span></div><div class='line' id='LC654'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;credential-cache<span class="o">)</span> : credentials helper<span class="p">;;</span></div><div class='line' id='LC655'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;credential-store<span class="o">)</span> : credentials helper<span class="p">;;</span></div><div class='line' id='LC656'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cvsexportcommit<span class="o">)</span>  : <span class="nb">export</span><span class="p">;;</span></div><div class='line' id='LC657'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cvsimport<span class="o">)</span>        : import<span class="p">;;</span></div><div class='line' id='LC658'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cvsserver<span class="o">)</span>        : daemon<span class="p">;;</span></div><div class='line' id='LC659'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;daemon<span class="o">)</span>           : daemon<span class="p">;;</span></div><div class='line' id='LC660'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff-files<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC661'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff-index<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC662'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff-tree<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC663'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fast-import<span class="o">)</span>      : import<span class="p">;;</span></div><div class='line' id='LC664'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fast-export<span class="o">)</span>      : <span class="nb">export</span><span class="p">;;</span></div><div class='line' id='LC665'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fsck-objects<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC666'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch-pack<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC667'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fmt-merge-msg<span class="o">)</span>    : plumbing<span class="p">;;</span></div><div class='line' id='LC668'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for</span>-each-ref<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC669'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">hash</span>-object<span class="o">)</span>      : plumbing<span class="p">;;</span></div><div class='line' id='LC670'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http-*<span class="o">)</span>           : transport<span class="p">;;</span></div><div class='line' id='LC671'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;index-pack<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC672'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;init-db<span class="o">)</span>          : deprecated<span class="p">;;</span></div><div class='line' id='LC673'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local</span>-fetch<span class="o">)</span>      : plumbing<span class="p">;;</span></div><div class='line' id='LC674'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ls-files<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC675'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ls-remote<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC676'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ls-tree<span class="o">)</span>          : plumbing<span class="p">;;</span></div><div class='line' id='LC677'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mailinfo<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC678'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mailsplit<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC679'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge-*<span class="o">)</span>          : plumbing<span class="p">;;</span></div><div class='line' id='LC680'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mktree<span class="o">)</span>           : plumbing<span class="p">;;</span></div><div class='line' id='LC681'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mktag<span class="o">)</span>            : plumbing<span class="p">;;</span></div><div class='line' id='LC682'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack-objects<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC683'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack-redundant<span class="o">)</span>   : plumbing<span class="p">;;</span></div><div class='line' id='LC684'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack-refs<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC685'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;parse-remote<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC686'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;patch-id<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC687'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prune<span class="o">)</span>            : plumbing<span class="p">;;</span></div><div class='line' id='LC688'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prune-packed<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC689'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;quiltimport<span class="o">)</span>      : import<span class="p">;;</span></div><div class='line' id='LC690'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">read</span>-tree<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC691'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive-pack<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC692'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote-*<span class="o">)</span>         : transport<span class="p">;;</span></div><div class='line' id='LC693'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rerere<span class="o">)</span>           : plumbing<span class="p">;;</span></div><div class='line' id='LC694'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rev-list<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC695'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rev-parse<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC696'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;runstatus<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC697'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sh-setup<span class="o">)</span>         : internal<span class="p">;;</span></div><div class='line' id='LC698'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;shell<span class="o">)</span>            : daemon<span class="p">;;</span></div><div class='line' id='LC699'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show-ref<span class="o">)</span>         : plumbing<span class="p">;;</span></div><div class='line' id='LC700'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;send-pack<span class="o">)</span>        : plumbing<span class="p">;;</span></div><div class='line' id='LC701'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show-index<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC702'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ssh-*<span class="o">)</span>            : transport<span class="p">;;</span></div><div class='line' id='LC703'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;stripspace<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC704'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbolic-ref<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC705'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unpack-file<span class="o">)</span>      : plumbing<span class="p">;;</span></div><div class='line' id='LC706'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unpack-objects<span class="o">)</span>   : plumbing<span class="p">;;</span></div><div class='line' id='LC707'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;update-index<span class="o">)</span>     : plumbing<span class="p">;;</span></div><div class='line' id='LC708'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;update-ref<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC709'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;update-server-info<span class="o">)</span> : daemon<span class="p">;;</span></div><div class='line' id='LC710'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;upload-archive<span class="o">)</span>   : plumbing<span class="p">;;</span></div><div class='line' id='LC711'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;upload-pack<span class="o">)</span>      : plumbing<span class="p">;;</span></div><div class='line' id='LC712'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;write-tree<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC713'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var<span class="o">)</span>              : infrequent<span class="p">;;</span></div><div class='line' id='LC714'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;verify-pack<span class="o">)</span>      : infrequent<span class="p">;;</span></div><div class='line' id='LC715'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;verify-tag<span class="o">)</span>       : plumbing<span class="p">;;</span></div><div class='line' id='LC716'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nb">echo</span> <span class="nv">$i</span><span class="p">;;</span></div><div class='line' id='LC717'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC718'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC719'><span class="o">}</span></div><div class='line' id='LC720'><br/></div><div class='line' id='LC721'><span class="nv">__git_porcelain_commands</span><span class="o">=</span></div><div class='line' id='LC722'>__git_compute_porcelain_commands <span class="o">()</span></div><div class='line' id='LC723'><span class="o">{</span></div><div class='line' id='LC724'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_compute_all_commands</div><div class='line' id='LC725'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">test</span> -n <span class="s2">&quot;$__git_porcelain_commands&quot;</span> <span class="o">||</span></div><div class='line' id='LC726'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">__git_porcelain_commands</span><span class="o">=</span><span class="k">$(</span>__git_list_porcelain_commands<span class="k">)</span></div><div class='line' id='LC727'><span class="o">}</span></div><div class='line' id='LC728'><br/></div><div class='line' id='LC729'>__git_pretty_aliases <span class="o">()</span></div><div class='line' id='LC730'><span class="o">{</span></div><div class='line' id='LC731'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC732'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> config --get-regexp <span class="s2">&quot;pretty\..*&quot;</span> 2&gt;/dev/null<span class="k">)</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC733'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC734'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pretty.*<span class="o">)</span></div><div class='line' id='LC735'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${i#pretty.}&quot;</span></div><div class='line' id='LC736'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;${i/ */}&quot;</span></div><div class='line' id='LC737'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC738'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC739'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC740'><span class="o">}</span></div><div class='line' id='LC741'><br/></div><div class='line' id='LC742'>__git_aliases <span class="o">()</span></div><div class='line' id='LC743'><span class="o">{</span></div><div class='line' id='LC744'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC745'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> config --get-regexp <span class="s2">&quot;alias\..*&quot;</span> 2&gt;/dev/null<span class="k">)</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC746'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC747'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;alias.*<span class="o">)</span></div><div class='line' id='LC748'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${i#alias.}&quot;</span></div><div class='line' id='LC749'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;${i/ */}&quot;</span></div><div class='line' id='LC750'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC751'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC752'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC753'><span class="o">}</span></div><div class='line' id='LC754'><br/></div><div class='line' id='LC755'><span class="c"># __git_aliased_command requires 1 argument</span></div><div class='line' id='LC756'>__git_aliased_command <span class="o">()</span></div><div class='line' id='LC757'><span class="o">{</span></div><div class='line' id='LC758'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>word <span class="nv">cmdline</span><span class="o">=</span><span class="k">$(</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> <span class="se">\</span></div><div class='line' id='LC759'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;config --get <span class="s2">&quot;alias.$1&quot;</span><span class="k">)</span></div><div class='line' id='LC760'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>word in <span class="nv">$cmdline</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC761'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$word&quot;</span> in</div><div class='line' id='LC762'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="se">\!</span>gitk<span class="p">|</span>gitk<span class="o">)</span></div><div class='line' id='LC763'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;gitk&quot;</span></div><div class='line' id='LC764'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC765'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC766'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="se">\!</span>*<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: shell <span class="nb">command alias</span> <span class="p">;;</span></div><div class='line' id='LC767'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-*<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: option <span class="p">;;</span></div><div class='line' id='LC768'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">=</span>*<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: setting env <span class="p">;;</span></div><div class='line' id='LC769'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: git itself <span class="p">;;</span></div><div class='line' id='LC770'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC771'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;$word&quot;</span></div><div class='line' id='LC772'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC773'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC774'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC775'><span class="o">}</span></div><div class='line' id='LC776'><br/></div><div class='line' id='LC777'><span class="c"># __git_find_on_cmdline requires 1 argument</span></div><div class='line' id='LC778'>__git_find_on_cmdline <span class="o">()</span></div><div class='line' id='LC779'><span class="o">{</span></div><div class='line' id='LC780'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>word subcommand <span class="nv">c</span><span class="o">=</span>1</div><div class='line' id='LC781'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC782'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">word</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC783'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>subcommand in <span class="nv">$1</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC784'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> <span class="s2">&quot;$subcommand&quot;</span> <span class="o">=</span> <span class="s2">&quot;$word&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC785'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;$subcommand&quot;</span></div><div class='line' id='LC786'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC787'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC788'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC789'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC790'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC791'><span class="o">}</span></div><div class='line' id='LC792'><br/></div><div class='line' id='LC793'>__git_has_doubledash <span class="o">()</span></div><div class='line' id='LC794'><span class="o">{</span></div><div class='line' id='LC795'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">c</span><span class="o">=</span>1</div><div class='line' id='LC796'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC797'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> <span class="s2">&quot;--&quot;</span> <span class="o">=</span> <span class="s2">&quot;${words[c]}&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC798'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return </span>0</div><div class='line' id='LC799'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC800'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC801'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC802'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return </span>1</div><div class='line' id='LC803'><span class="o">}</span></div><div class='line' id='LC804'><br/></div><div class='line' id='LC805'><span class="c"># Try to count non option arguments passed on the command line for the</span></div><div class='line' id='LC806'><span class="c"># specified git command.</span></div><div class='line' id='LC807'><span class="c"># When options are used, it is necessary to use the special -- option to</span></div><div class='line' id='LC808'><span class="c"># tell the implementation were non option arguments begin.</span></div><div class='line' id='LC809'><span class="c"># XXX this can not be improved, since options can appear everywhere, as</span></div><div class='line' id='LC810'><span class="c"># an example:</span></div><div class='line' id='LC811'><span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;git mv x -n y</span></div><div class='line' id='LC812'><span class="c">#</span></div><div class='line' id='LC813'><span class="c"># __git_count_arguments requires 1 argument: the git command executed.</span></div><div class='line' id='LC814'>__git_count_arguments <span class="o">()</span></div><div class='line' id='LC815'><span class="o">{</span></div><div class='line' id='LC816'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>word i <span class="nv">c</span><span class="o">=</span>0</div><div class='line' id='LC817'><br/></div><div class='line' id='LC818'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Skip &quot;git&quot; (first argument)</span></div><div class='line' id='LC819'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for</span> <span class="o">((</span><span class="nv">i</span><span class="o">=</span>1<span class="p">;</span> i &lt; <span class="k">${#</span><span class="nv">words</span><span class="p">[@]</span><span class="k">}</span><span class="p">;</span> i++<span class="o">))</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC820'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">word</span><span class="o">=</span><span class="s2">&quot;${words[i]}&quot;</span></div><div class='line' id='LC821'><br/></div><div class='line' id='LC822'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$word&quot;</span> in</div><div class='line' id='LC823'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--<span class="o">)</span></div><div class='line' id='LC824'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Good; we can assume that the following are only non</span></div><div class='line' id='LC825'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># option arguments.</span></div><div class='line' id='LC826'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span><span class="nv">c</span> <span class="o">=</span> 0<span class="o">))</span></div><div class='line' id='LC827'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC828'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;$1&quot;</span><span class="o">)</span></div><div class='line' id='LC829'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># Skip the specified git command and discard git</span></div><div class='line' id='LC830'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># main options</span></div><div class='line' id='LC831'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span><span class="nv">c</span> <span class="o">=</span> 0<span class="o">))</span></div><div class='line' id='LC832'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC833'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;?*<span class="o">)</span></div><div class='line' id='LC834'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC835'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC836'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC837'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC838'><br/></div><div class='line' id='LC839'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">printf</span> <span class="s2">&quot;%d&quot;</span> <span class="nv">$c</span></div><div class='line' id='LC840'><span class="o">}</span></div><div class='line' id='LC841'><br/></div><div class='line' id='LC842'><span class="nv">__git_whitespacelist</span><span class="o">=</span><span class="s2">&quot;nowarn warn error error-all fix&quot;</span></div><div class='line' id='LC843'><br/></div><div class='line' id='LC844'>_git_am <span class="o">()</span></div><div class='line' id='LC845'><span class="o">{</span></div><div class='line' id='LC846'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC847'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span>/rebase-apply <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC848'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;--skip --continue --resolved --abort&quot;</span></div><div class='line' id='LC849'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC850'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC851'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC852'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--whitespace<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC853'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_whitespacelist&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--whitespace=}&quot;</span></div><div class='line' id='LC854'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC855'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC856'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC857'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC858'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--3way --committer-date-is-author-date --ignore-date</span></div><div class='line' id='LC859'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-whitespace --ignore-space-change</span></div><div class='line' id='LC860'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--interactive --keep --no-utf8 --signoff --utf8</span></div><div class='line' id='LC861'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--whitespace= --scissors</span></div><div class='line' id='LC862'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC863'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC864'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC865'><span class="o">}</span></div><div class='line' id='LC866'><br/></div><div class='line' id='LC867'>_git_apply <span class="o">()</span></div><div class='line' id='LC868'><span class="o">{</span></div><div class='line' id='LC869'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC870'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--whitespace<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC871'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_whitespacelist&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--whitespace=}&quot;</span></div><div class='line' id='LC872'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC873'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC874'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC875'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC876'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--stat --numstat --summary --check --index</span></div><div class='line' id='LC877'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--cached --index-info --reverse --reject --unidiff-zero</span></div><div class='line' id='LC878'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--apply --no-add --exclude=</span></div><div class='line' id='LC879'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-whitespace --ignore-space-change</span></div><div class='line' id='LC880'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--whitespace= --inaccurate-eof --verbose</span></div><div class='line' id='LC881'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC882'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC883'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC884'><span class="o">}</span></div><div class='line' id='LC885'><br/></div><div class='line' id='LC886'>_git_add <span class="o">()</span></div><div class='line' id='LC887'><span class="o">{</span></div><div class='line' id='LC888'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC889'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC890'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC891'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--interactive --refresh --patch --update --dry-run</span></div><div class='line' id='LC892'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-errors --intent-to-add</span></div><div class='line' id='LC893'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC894'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC895'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC896'><br/></div><div class='line' id='LC897'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># XXX should we check for --update and --all options ?</span></div><div class='line' id='LC898'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_index_file <span class="s2">&quot;--others --modified --directory --no-empty-directory&quot;</span></div><div class='line' id='LC899'><span class="o">}</span></div><div class='line' id='LC900'><br/></div><div class='line' id='LC901'>_git_archive <span class="o">()</span></div><div class='line' id='LC902'><span class="o">{</span></div><div class='line' id='LC903'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC904'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--format<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC905'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$(git archive --list)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--format=}&quot;</span></div><div class='line' id='LC906'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC907'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC908'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--remote<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC909'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--remote=}&quot;</span></div><div class='line' id='LC910'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC911'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC912'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC913'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC914'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--format= --list --verbose</span></div><div class='line' id='LC915'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--prefix= --remote= --exec=</span></div><div class='line' id='LC916'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC917'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC918'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC919'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC920'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_file</div><div class='line' id='LC921'><span class="o">}</span></div><div class='line' id='LC922'><br/></div><div class='line' id='LC923'>_git_bisect <span class="o">()</span></div><div class='line' id='LC924'><span class="o">{</span></div><div class='line' id='LC925'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC926'><br/></div><div class='line' id='LC927'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s2">&quot;start bad good skip reset visualize replay log run&quot;</span></div><div class='line' id='LC928'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC929'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$subcommand&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC930'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> -f <span class="s2">&quot;$(__gitdir)&quot;</span>/BISECT_START <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC931'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC932'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC933'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;replay start&quot;</span></div><div class='line' id='LC934'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC935'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return</span></div><div class='line' id='LC936'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC937'><br/></div><div class='line' id='LC938'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$subcommand&quot;</span> in</div><div class='line' id='LC939'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bad<span class="p">|</span>good<span class="p">|</span>reset<span class="p">|</span>skip<span class="p">|</span>start<span class="o">)</span></div><div class='line' id='LC940'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC941'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC942'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC943'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC944'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC945'><span class="o">}</span></div><div class='line' id='LC946'><br/></div><div class='line' id='LC947'>_git_branch <span class="o">()</span></div><div class='line' id='LC948'><span class="o">{</span></div><div class='line' id='LC949'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">c</span><span class="o">=</span>1 <span class="nv">only_local_ref</span><span class="o">=</span><span class="s2">&quot;n&quot;</span> <span class="nv">has_r</span><span class="o">=</span><span class="s2">&quot;n&quot;</span></div><div class='line' id='LC950'><br/></div><div class='line' id='LC951'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC952'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC953'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC954'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-d<span class="p">|</span>-m<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">only_local_ref</span><span class="o">=</span><span class="s2">&quot;y&quot;</span> <span class="p">;;</span></div><div class='line' id='LC955'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-r<span class="o">)</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">has_r</span><span class="o">=</span><span class="s2">&quot;y&quot;</span> <span class="p">;;</span></div><div class='line' id='LC956'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC957'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC958'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC959'><br/></div><div class='line' id='LC960'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC961'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--set-upstream-to<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC962'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--set-upstream-to=}&quot;</span></div><div class='line' id='LC963'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC964'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC965'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC966'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--color --no-color --verbose --abbrev= --no-abbrev</span></div><div class='line' id='LC967'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--track --no-track --contains --merged --no-merged</span></div><div class='line' id='LC968'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--set-upstream-to= --edit-description --list</span></div><div class='line' id='LC969'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--unset-upstream</span></div><div class='line' id='LC970'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC971'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC972'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC973'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$only_local_ref</span> <span class="o">=</span> <span class="s2">&quot;y&quot;</span> -a <span class="nv">$has_r</span> <span class="o">=</span> <span class="s2">&quot;n&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC974'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_heads)&quot;</span></div><div class='line' id='LC975'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC976'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC977'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC978'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC979'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC980'><span class="o">}</span></div><div class='line' id='LC981'><br/></div><div class='line' id='LC982'>_git_bundle <span class="o">()</span></div><div class='line' id='LC983'><span class="o">{</span></div><div class='line' id='LC984'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">cmd</span><span class="o">=</span><span class="s2">&quot;${words[2]}&quot;</span></div><div class='line' id='LC985'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cword&quot;</span> in</div><div class='line' id='LC986'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2<span class="o">)</span></div><div class='line' id='LC987'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;create list-heads verify unbundle&quot;</span></div><div class='line' id='LC988'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC989'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3<span class="o">)</span></div><div class='line' id='LC990'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># looking for a file</span></div><div class='line' id='LC991'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC992'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC993'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cmd&quot;</span> in</div><div class='line' id='LC994'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;create<span class="o">)</span></div><div class='line' id='LC995'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_revlist</div><div class='line' id='LC996'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC997'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC998'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC999'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1000'><span class="o">}</span></div><div class='line' id='LC1001'><br/></div><div class='line' id='LC1002'>_git_checkout <span class="o">()</span></div><div class='line' id='LC1003'><span class="o">{</span></div><div class='line' id='LC1004'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1005'><br/></div><div class='line' id='LC1006'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1007'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--conflict<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1008'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;diff3 merge&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--conflict=}&quot;</span></div><div class='line' id='LC1009'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1010'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1011'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1012'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--quiet --ours --theirs --track --no-track --merge</span></div><div class='line' id='LC1013'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--conflict= --orphan --patch</span></div><div class='line' id='LC1014'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1015'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1016'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC1017'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># check if --track, --no-track, or --no-guess was specified</span></div><div class='line' id='LC1018'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># if so, disable DWIM mode</span></div><div class='line' id='LC1019'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">flags</span><span class="o">=</span><span class="s2">&quot;--track --no-track --no-guess&quot;</span> <span class="nv">track</span><span class="o">=</span>1</div><div class='line' id='LC1020'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -n <span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$flags</span><span class="s2">&quot;)&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1021'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">track</span><span class="o">=</span><span class="s1">&#39;&#39;</span></div><div class='line' id='LC1022'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC1023'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs &#39;&#39; $track)&quot;</span></div><div class='line' id='LC1024'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1025'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1026'><span class="o">}</span></div><div class='line' id='LC1027'><br/></div><div class='line' id='LC1028'>_git_cherry <span class="o">()</span></div><div class='line' id='LC1029'><span class="o">{</span></div><div class='line' id='LC1030'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1031'><span class="o">}</span></div><div class='line' id='LC1032'><br/></div><div class='line' id='LC1033'>_git_cherry_pick <span class="o">()</span></div><div class='line' id='LC1034'><span class="o">{</span></div><div class='line' id='LC1035'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC1036'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -f <span class="s2">&quot;$dir&quot;</span>/CHERRY_PICK_HEAD <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1037'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;--continue --quit --abort&quot;</span></div><div class='line' id='LC1038'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1039'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC1040'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1041'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1042'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--edit --no-commit --signoff --strategy= --mainline&quot;</span></div><div class='line' id='LC1043'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1044'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC1045'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1046'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1047'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1048'><span class="o">}</span></div><div class='line' id='LC1049'><br/></div><div class='line' id='LC1050'>_git_clean <span class="o">()</span></div><div class='line' id='LC1051'><span class="o">{</span></div><div class='line' id='LC1052'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1053'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1054'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--dry-run --quiet&quot;</span></div><div class='line' id='LC1055'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1056'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1057'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1058'><br/></div><div class='line' id='LC1059'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># XXX should we check for -x option ?</span></div><div class='line' id='LC1060'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_index_file <span class="s2">&quot;--others --directory&quot;</span></div><div class='line' id='LC1061'><span class="o">}</span></div><div class='line' id='LC1062'><br/></div><div class='line' id='LC1063'>_git_clone <span class="o">()</span></div><div class='line' id='LC1064'><span class="o">{</span></div><div class='line' id='LC1065'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1066'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1067'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1068'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--local</span></div><div class='line' id='LC1069'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-hardlinks</span></div><div class='line' id='LC1070'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--shared</span></div><div class='line' id='LC1071'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--reference</span></div><div class='line' id='LC1072'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--quiet</span></div><div class='line' id='LC1073'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-checkout</span></div><div class='line' id='LC1074'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--bare</span></div><div class='line' id='LC1075'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--mirror</span></div><div class='line' id='LC1076'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--origin</span></div><div class='line' id='LC1077'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--upload-pack</span></div><div class='line' id='LC1078'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--template=</span></div><div class='line' id='LC1079'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--depth</span></div><div class='line' id='LC1080'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--single-branch</span></div><div class='line' id='LC1081'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--branch</span></div><div class='line' id='LC1082'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1083'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1084'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1085'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1086'><span class="o">}</span></div><div class='line' id='LC1087'><br/></div><div class='line' id='LC1088'>_git_commit <span class="o">()</span></div><div class='line' id='LC1089'><span class="o">{</span></div><div class='line' id='LC1090'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC1091'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-c<span class="p">|</span>-C<span class="o">)</span></div><div class='line' id='LC1092'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur}&quot;</span></div><div class='line' id='LC1093'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1094'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1095'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1096'><br/></div><div class='line' id='LC1097'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1098'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--cleanup<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1099'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;default strip verbatim whitespace</span></div><div class='line' id='LC1100'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--cleanup=}&quot;</span></div><div class='line' id='LC1101'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1102'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1103'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--reuse-message<span class="o">=</span>*<span class="p">|</span>--reedit-message<span class="o">=</span>*<span class="p">|</span><span class="se">\</span></div><div class='line' id='LC1104'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--fixup<span class="o">=</span>*<span class="p">|</span>--squash<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1105'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur#*=}&quot;</span></div><div class='line' id='LC1106'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1107'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1108'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--untracked-files<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1109'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;all no normal&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--untracked-files=}&quot;</span></div><div class='line' id='LC1110'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1111'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1112'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1113'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1114'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all --author= --signoff --verify --no-verify</span></div><div class='line' id='LC1115'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--edit --no-edit</span></div><div class='line' id='LC1116'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--amend --include --only --interactive</span></div><div class='line' id='LC1117'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--dry-run --reuse-message= --reedit-message=</span></div><div class='line' id='LC1118'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--reset-author --file= --message= --template=</span></div><div class='line' id='LC1119'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--cleanup= --untracked-files --untracked-files=</span></div><div class='line' id='LC1120'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--verbose --quiet --fixup= --squash=</span></div><div class='line' id='LC1121'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1122'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1123'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC1124'><br/></div><div class='line' id='LC1125'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if </span>git rev-parse --verify --quiet HEAD &gt;/dev/null<span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1126'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_index_file <span class="s2">&quot;--committable&quot;</span></div><div class='line' id='LC1127'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC1128'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># This is the first commit</span></div><div class='line' id='LC1129'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_index_file <span class="s2">&quot;--cached&quot;</span></div><div class='line' id='LC1130'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC1131'><span class="o">}</span></div><div class='line' id='LC1132'><br/></div><div class='line' id='LC1133'>_git_describe <span class="o">()</span></div><div class='line' id='LC1134'><span class="o">{</span></div><div class='line' id='LC1135'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1136'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1137'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1138'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all --tags --contains --abbrev= --candidates=</span></div><div class='line' id='LC1139'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--exact-match --debug --long --match --always</span></div><div class='line' id='LC1140'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1141'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1142'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC1143'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1144'><span class="o">}</span></div><div class='line' id='LC1145'><br/></div><div class='line' id='LC1146'><span class="nv">__git_diff_algorithms</span><span class="o">=</span><span class="s2">&quot;myers minimal patience histogram&quot;</span></div><div class='line' id='LC1147'><br/></div><div class='line' id='LC1148'><span class="nv">__git_diff_common_options</span><span class="o">=</span><span class="s2">&quot;--stat --numstat --shortstat --summary</span></div><div class='line' id='LC1149'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--patch-with-stat --name-only --name-status --color</span></div><div class='line' id='LC1150'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-color --color-words --no-renames --check</span></div><div class='line' id='LC1151'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--full-index --binary --abbrev --diff-filter=</span></div><div class='line' id='LC1152'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--find-copies-harder</span></div><div class='line' id='LC1153'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--text --ignore-space-at-eol --ignore-space-change</span></div><div class='line' id='LC1154'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-all-space --exit-code --quiet --ext-diff</span></div><div class='line' id='LC1155'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-ext-diff</span></div><div class='line' id='LC1156'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-prefix --src-prefix= --dst-prefix=</span></div><div class='line' id='LC1157'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--inter-hunk-context=</span></div><div class='line' id='LC1158'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--patience --histogram --minimal</span></div><div class='line' id='LC1159'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--raw --word-diff</span></div><div class='line' id='LC1160'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--dirstat --dirstat= --dirstat-by-file</span></div><div class='line' id='LC1161'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--dirstat-by-file= --cumulative</span></div><div class='line' id='LC1162'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--diff-algorithm=</span></div><div class='line' id='LC1163'><span class="s2">&quot;</span></div><div class='line' id='LC1164'><br/></div><div class='line' id='LC1165'>_git_diff <span class="o">()</span></div><div class='line' id='LC1166'><span class="o">{</span></div><div class='line' id='LC1167'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1168'><br/></div><div class='line' id='LC1169'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1170'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--diff-algorithm<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1171'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_diff_algorithms&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--diff-algorithm=}&quot;</span></div><div class='line' id='LC1172'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1173'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1174'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1175'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--cached --staged --pickaxe-all --pickaxe-regex</span></div><div class='line' id='LC1176'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--base --ours --theirs --no-index</span></div><div class='line' id='LC1177'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_diff_common_options</span></div><div class='line' id='LC1178'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1179'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1180'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1181'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1182'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist_file</div><div class='line' id='LC1183'><span class="o">}</span></div><div class='line' id='LC1184'><br/></div><div class='line' id='LC1185'><span class="nv">__git_mergetools_common</span><span class="o">=</span><span class="s2">&quot;diffuse diffmerge ecmerge emerge kdiff3 meld opendiff</span></div><div class='line' id='LC1186'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tkdiff vimdiff gvimdiff xxdiff araxis p4merge bc3 codecompare</span></div><div class='line' id='LC1187'><span class="s2">&quot;</span></div><div class='line' id='LC1188'><br/></div><div class='line' id='LC1189'>_git_difftool <span class="o">()</span></div><div class='line' id='LC1190'><span class="o">{</span></div><div class='line' id='LC1191'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1192'><br/></div><div class='line' id='LC1193'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1194'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--tool<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1195'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_mergetools_common kompare&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--tool=}&quot;</span></div><div class='line' id='LC1196'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1197'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1198'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1199'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--cached --staged --pickaxe-all --pickaxe-regex</span></div><div class='line' id='LC1200'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--base --ours --theirs</span></div><div class='line' id='LC1201'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-renames --diff-filter= --find-copies-harder</span></div><div class='line' id='LC1202'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--relative --ignore-submodules</span></div><div class='line' id='LC1203'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--tool=&quot;</span></div><div class='line' id='LC1204'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1205'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1206'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1207'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist_file</div><div class='line' id='LC1208'><span class="o">}</span></div><div class='line' id='LC1209'><br/></div><div class='line' id='LC1210'><span class="nv">__git_fetch_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1211'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--quiet --verbose --append --upload-pack --force --keep --depth=</span></div><div class='line' id='LC1212'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--tags --no-tags --all --prune --dry-run</span></div><div class='line' id='LC1213'><span class="s2">&quot;</span></div><div class='line' id='LC1214'><br/></div><div class='line' id='LC1215'>_git_fetch <span class="o">()</span></div><div class='line' id='LC1216'><span class="o">{</span></div><div class='line' id='LC1217'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1218'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1219'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_fetch_options&quot;</span></div><div class='line' id='LC1220'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1221'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1222'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1223'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_remote_or_refspec</div><div class='line' id='LC1224'><span class="o">}</span></div><div class='line' id='LC1225'><br/></div><div class='line' id='LC1226'><span class="nv">__git_format_patch_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1227'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--stdout --attach --no-attach --thread --thread= --no-thread</span></div><div class='line' id='LC1228'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--numbered --start-number --numbered-files --keep-subject --signoff</span></div><div class='line' id='LC1229'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--signature --no-signature --in-reply-to= --cc= --full-index --binary</span></div><div class='line' id='LC1230'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--not --all --cover-letter --no-prefix --src-prefix= --dst-prefix=</span></div><div class='line' id='LC1231'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--inline --suffix= --ignore-if-in-upstream --subject-prefix=</span></div><div class='line' id='LC1232'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--output-directory --reroll-count --to= --quiet --notes</span></div><div class='line' id='LC1233'><span class="s2">&quot;</span></div><div class='line' id='LC1234'><br/></div><div class='line' id='LC1235'>_git_format_patch <span class="o">()</span></div><div class='line' id='LC1236'><span class="o">{</span></div><div class='line' id='LC1237'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1238'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--thread<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1239'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1240'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;deep shallow</span></div><div class='line' id='LC1241'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--thread=}&quot;</span></div><div class='line' id='LC1242'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1243'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1244'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1245'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_format_patch_options&quot;</span></div><div class='line' id='LC1246'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1247'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1248'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1249'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC1250'><span class="o">}</span></div><div class='line' id='LC1251'><br/></div><div class='line' id='LC1252'>_git_fsck <span class="o">()</span></div><div class='line' id='LC1253'><span class="o">{</span></div><div class='line' id='LC1254'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1255'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1256'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1257'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--tags --root --unreachable --cache --no-reflogs --full</span></div><div class='line' id='LC1258'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--strict --verbose --lost-found</span></div><div class='line' id='LC1259'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1260'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1261'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1262'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1263'><span class="o">}</span></div><div class='line' id='LC1264'><br/></div><div class='line' id='LC1265'>_git_gc <span class="o">()</span></div><div class='line' id='LC1266'><span class="o">{</span></div><div class='line' id='LC1267'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1268'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1269'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--prune --aggressive&quot;</span></div><div class='line' id='LC1270'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1271'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1272'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1273'><span class="o">}</span></div><div class='line' id='LC1274'><br/></div><div class='line' id='LC1275'>_git_gitk <span class="o">()</span></div><div class='line' id='LC1276'><span class="o">{</span></div><div class='line' id='LC1277'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_gitk</div><div class='line' id='LC1278'><span class="o">}</span></div><div class='line' id='LC1279'><br/></div><div class='line' id='LC1280'>__git_match_ctag<span class="o">()</span> <span class="o">{</span></div><div class='line' id='LC1281'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;awk <span class="s2">&quot;/^${1////\\/}/ { print \$1 }&quot;</span> <span class="s2">&quot;$2&quot;</span></div><div class='line' id='LC1282'><span class="o">}</span></div><div class='line' id='LC1283'><br/></div><div class='line' id='LC1284'>_git_grep <span class="o">()</span></div><div class='line' id='LC1285'><span class="o">{</span></div><div class='line' id='LC1286'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1287'><br/></div><div class='line' id='LC1288'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1289'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1290'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1291'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--cached</span></div><div class='line' id='LC1292'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--text --ignore-case --word-regexp --invert-match</span></div><div class='line' id='LC1293'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--full-name --line-number</span></div><div class='line' id='LC1294'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--extended-regexp --basic-regexp --fixed-strings</span></div><div class='line' id='LC1295'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--perl-regexp</span></div><div class='line' id='LC1296'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--files-with-matches --name-only</span></div><div class='line' id='LC1297'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--files-without-match</span></div><div class='line' id='LC1298'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--max-depth</span></div><div class='line' id='LC1299'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--count</span></div><div class='line' id='LC1300'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--and --or --not --all-match</span></div><div class='line' id='LC1301'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1302'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1303'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1304'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1305'><br/></div><div class='line' id='LC1306'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cword,$prev&quot;</span> in</div><div class='line' id='LC1307'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2,*<span class="p">|</span>*,-*<span class="o">)</span></div><div class='line' id='LC1308'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if </span><span class="nb">test</span> -r tags<span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1309'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_match_ctag &quot;</span><span class="nv">$cur</span><span class="s2">&quot; tags)&quot;</span></div><div class='line' id='LC1310'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1311'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC1312'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1313'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1314'><br/></div><div class='line' id='LC1315'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1316'><span class="o">}</span></div><div class='line' id='LC1317'><br/></div><div class='line' id='LC1318'>_git_help <span class="o">()</span></div><div class='line' id='LC1319'><span class="o">{</span></div><div class='line' id='LC1320'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1321'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1322'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--all --info --man --web&quot;</span></div><div class='line' id='LC1323'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1324'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1325'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1326'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_compute_all_commands</div><div class='line' id='LC1327'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_all_commands $(__git_aliases)</span></div><div class='line' id='LC1328'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;attributes cli core-tutorial cvs-migration</span></div><div class='line' id='LC1329'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diffcore gitk glossary hooks ignore modules</span></div><div class='line' id='LC1330'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;namespaces repository-layout tutorial tutorial-2</span></div><div class='line' id='LC1331'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;workflows</span></div><div class='line' id='LC1332'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1333'><span class="o">}</span></div><div class='line' id='LC1334'><br/></div><div class='line' id='LC1335'>_git_init <span class="o">()</span></div><div class='line' id='LC1336'><span class="o">{</span></div><div class='line' id='LC1337'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1338'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--shared<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1339'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1340'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;false true umask group all world everybody</span></div><div class='line' id='LC1341'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--shared=}&quot;</span></div><div class='line' id='LC1342'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1343'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1344'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1345'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--quiet --bare --template= --shared --shared=&quot;</span></div><div class='line' id='LC1346'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1347'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1348'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1349'><span class="o">}</span></div><div class='line' id='LC1350'><br/></div><div class='line' id='LC1351'>_git_ls_files <span class="o">()</span></div><div class='line' id='LC1352'><span class="o">{</span></div><div class='line' id='LC1353'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1354'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1355'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--cached --deleted --modified --others --ignored</span></div><div class='line' id='LC1356'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--stage --directory --no-empty-directory --unmerged</span></div><div class='line' id='LC1357'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--killed --exclude= --exclude-from=</span></div><div class='line' id='LC1358'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--exclude-per-directory= --exclude-standard</span></div><div class='line' id='LC1359'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--error-unmatch --with-tree= --full-name</span></div><div class='line' id='LC1360'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--abbrev --ignored --exclude-per-directory</span></div><div class='line' id='LC1361'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1362'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1363'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1364'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1365'><br/></div><div class='line' id='LC1366'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># XXX ignore options like --modified and always suggest all cached</span></div><div class='line' id='LC1367'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># files.</span></div><div class='line' id='LC1368'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_index_file <span class="s2">&quot;--cached&quot;</span></div><div class='line' id='LC1369'><span class="o">}</span></div><div class='line' id='LC1370'><br/></div><div class='line' id='LC1371'>_git_ls_remote <span class="o">()</span></div><div class='line' id='LC1372'><span class="o">{</span></div><div class='line' id='LC1373'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC1374'><span class="o">}</span></div><div class='line' id='LC1375'><br/></div><div class='line' id='LC1376'>_git_ls_tree <span class="o">()</span></div><div class='line' id='LC1377'><span class="o">{</span></div><div class='line' id='LC1378'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_file</div><div class='line' id='LC1379'><span class="o">}</span></div><div class='line' id='LC1380'><br/></div><div class='line' id='LC1381'><span class="c"># Options that go well for log, shortlog and gitk</span></div><div class='line' id='LC1382'><span class="nv">__git_log_common_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1383'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--not --all</span></div><div class='line' id='LC1384'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--branches --tags --remotes</span></div><div class='line' id='LC1385'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--first-parent --merges --no-merges</span></div><div class='line' id='LC1386'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--max-count=</span></div><div class='line' id='LC1387'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--max-age= --since= --after=</span></div><div class='line' id='LC1388'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--min-age= --until= --before=</span></div><div class='line' id='LC1389'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--min-parents= --max-parents=</span></div><div class='line' id='LC1390'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-min-parents --no-max-parents</span></div><div class='line' id='LC1391'><span class="s2">&quot;</span></div><div class='line' id='LC1392'><span class="c"># Options that go well for log and gitk (not shortlog)</span></div><div class='line' id='LC1393'><span class="nv">__git_log_gitk_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1394'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--dense --sparse --full-history</span></div><div class='line' id='LC1395'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--simplify-merges --simplify-by-decoration</span></div><div class='line' id='LC1396'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--left-right --notes --no-notes</span></div><div class='line' id='LC1397'><span class="s2">&quot;</span></div><div class='line' id='LC1398'><span class="c"># Options that go well for log and shortlog (not gitk)</span></div><div class='line' id='LC1399'><span class="nv">__git_log_shortlog_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1400'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--author= --committer= --grep=</span></div><div class='line' id='LC1401'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all-match</span></div><div class='line' id='LC1402'><span class="s2">&quot;</span></div><div class='line' id='LC1403'><br/></div><div class='line' id='LC1404'><span class="nv">__git_log_pretty_formats</span><span class="o">=</span><span class="s2">&quot;oneline short medium full fuller email raw format:&quot;</span></div><div class='line' id='LC1405'><span class="nv">__git_log_date_formats</span><span class="o">=</span><span class="s2">&quot;relative iso8601 rfc2822 short local default raw&quot;</span></div><div class='line' id='LC1406'><br/></div><div class='line' id='LC1407'>_git_log <span class="o">()</span></div><div class='line' id='LC1408'><span class="o">{</span></div><div class='line' id='LC1409'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1410'><br/></div><div class='line' id='LC1411'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">g</span><span class="o">=</span><span class="s2">&quot;$(git rev-parse --git-dir 2&gt;/dev/null)&quot;</span></div><div class='line' id='LC1412'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">merge</span><span class="o">=</span><span class="s2">&quot;&quot;</span></div><div class='line' id='LC1413'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -f <span class="s2">&quot;$g/MERGE_HEAD&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1414'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">merge</span><span class="o">=</span><span class="s2">&quot;--merge&quot;</span></div><div class='line' id='LC1415'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC1416'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1417'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--pretty<span class="o">=</span>*<span class="p">|</span>--format<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1418'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_log_pretty_formats $(__git_pretty_aliases)</span></div><div class='line' id='LC1419'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur#*=}&quot;</span></div><div class='line' id='LC1420'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1421'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1422'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--date<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1423'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_log_date_formats&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--date=}&quot;</span></div><div class='line' id='LC1424'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1425'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1426'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--decorate<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1427'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;long short&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--decorate=}&quot;</span></div><div class='line' id='LC1428'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1429'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1430'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1431'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1432'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_common_options</span></div><div class='line' id='LC1433'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_shortlog_options</span></div><div class='line' id='LC1434'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_gitk_options</span></div><div class='line' id='LC1435'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--root --topo-order --date-order --reverse</span></div><div class='line' id='LC1436'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--follow --full-diff</span></div><div class='line' id='LC1437'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--abbrev-commit --abbrev=</span></div><div class='line' id='LC1438'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--relative-date --date=</span></div><div class='line' id='LC1439'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--pretty= --format= --oneline</span></div><div class='line' id='LC1440'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--cherry-pick</span></div><div class='line' id='LC1441'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--graph</span></div><div class='line' id='LC1442'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--decorate --decorate=</span></div><div class='line' id='LC1443'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--walk-reflogs</span></div><div class='line' id='LC1444'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--parents --children</span></div><div class='line' id='LC1445'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$merge</span></div><div class='line' id='LC1446'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_diff_common_options</span></div><div class='line' id='LC1447'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--pickaxe-all --pickaxe-regex</span></div><div class='line' id='LC1448'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1449'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1450'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1451'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1452'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC1453'><span class="o">}</span></div><div class='line' id='LC1454'><br/></div><div class='line' id='LC1455'><span class="nv">__git_merge_options</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC1456'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-commit --no-stat --log --no-log --squash --strategy</span></div><div class='line' id='LC1457'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--commit --stat --no-squash --ff --no-ff --ff-only --edit --no-edit</span></div><div class='line' id='LC1458'><span class="s2">&quot;</span></div><div class='line' id='LC1459'><br/></div><div class='line' id='LC1460'>_git_merge <span class="o">()</span></div><div class='line' id='LC1461'><span class="o">{</span></div><div class='line' id='LC1462'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_strategy <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1463'><br/></div><div class='line' id='LC1464'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1465'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1466'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_merge_options&quot;</span></div><div class='line' id='LC1467'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1468'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC1469'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1470'><span class="o">}</span></div><div class='line' id='LC1471'><br/></div><div class='line' id='LC1472'>_git_mergetool <span class="o">()</span></div><div class='line' id='LC1473'><span class="o">{</span></div><div class='line' id='LC1474'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1475'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--tool<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1476'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_mergetools_common tortoisemerge&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--tool=}&quot;</span></div><div class='line' id='LC1477'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1478'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1479'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1480'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--tool=&quot;</span></div><div class='line' id='LC1481'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1482'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1483'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1484'><span class="o">}</span></div><div class='line' id='LC1485'><br/></div><div class='line' id='LC1486'>_git_merge_base <span class="o">()</span></div><div class='line' id='LC1487'><span class="o">{</span></div><div class='line' id='LC1488'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1489'><span class="o">}</span></div><div class='line' id='LC1490'><br/></div><div class='line' id='LC1491'>_git_mv <span class="o">()</span></div><div class='line' id='LC1492'><span class="o">{</span></div><div class='line' id='LC1493'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1494'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1495'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--dry-run&quot;</span></div><div class='line' id='LC1496'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1497'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1498'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1499'><br/></div><div class='line' id='LC1500'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> <span class="k">$(</span>__git_count_arguments <span class="s2">&quot;mv&quot;</span><span class="k">)</span> -gt 0 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1501'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># We need to show both cached and untracked files (including</span></div><div class='line' id='LC1502'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># empty directories) since this may not be the last argument.</span></div><div class='line' id='LC1503'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_index_file <span class="s2">&quot;--cached --others --directory&quot;</span></div><div class='line' id='LC1504'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC1505'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_index_file <span class="s2">&quot;--cached&quot;</span></div><div class='line' id='LC1506'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC1507'><span class="o">}</span></div><div class='line' id='LC1508'><br/></div><div class='line' id='LC1509'>_git_name_rev <span class="o">()</span></div><div class='line' id='LC1510'><span class="o">{</span></div><div class='line' id='LC1511'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--tags --all --stdin&quot;</span></div><div class='line' id='LC1512'><span class="o">}</span></div><div class='line' id='LC1513'><br/></div><div class='line' id='LC1514'>_git_notes <span class="o">()</span></div><div class='line' id='LC1515'><span class="o">{</span></div><div class='line' id='LC1516'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s1">&#39;add append copy edit list prune remove show&#39;</span></div><div class='line' id='LC1517'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC1518'><br/></div><div class='line' id='LC1519'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$subcommand,$cur&quot;</span> in</div><div class='line' id='LC1520'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;,--*<span class="o">)</span></div><div class='line' id='LC1521'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s1">&#39;--ref&#39;</span></div><div class='line' id='LC1522'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1523'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;,*<span class="o">)</span></div><div class='line' id='LC1524'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC1525'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ref<span class="o">)</span></div><div class='line' id='LC1526'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1527'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1528'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC1529'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$subcommands --ref&quot;</span></div><div class='line' id='LC1530'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1531'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1532'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1533'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add,--reuse-message<span class="o">=</span>*<span class="p">|</span>append,--reuse-message<span class="o">=</span>*<span class="p">|</span><span class="se">\</span></div><div class='line' id='LC1534'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add,--reedit-message<span class="o">=</span>*<span class="p">|</span>append,--reedit-message<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1535'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur#*=}&quot;</span></div><div class='line' id='LC1536'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1537'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add,--*<span class="p">|</span>append,--*<span class="o">)</span></div><div class='line' id='LC1538'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s1">&#39;--file= --message= --reedit-message=</span></div><div class='line' id='LC1539'><span class="s1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--reuse-message=&#39;</span></div><div class='line' id='LC1540'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1541'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;copy,--*<span class="o">)</span></div><div class='line' id='LC1542'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s1">&#39;--stdin&#39;</span></div><div class='line' id='LC1543'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1544'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prune,--*<span class="o">)</span></div><div class='line' id='LC1545'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s1">&#39;--dry-run --verbose&#39;</span></div><div class='line' id='LC1546'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1547'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prune,*<span class="o">)</span></div><div class='line' id='LC1548'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1549'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC1550'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC1551'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-m<span class="p">|</span>-F<span class="o">)</span></div><div class='line' id='LC1552'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1553'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC1554'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1555'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1556'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1557'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1558'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1559'><span class="o">}</span></div><div class='line' id='LC1560'><br/></div><div class='line' id='LC1561'>_git_pull <span class="o">()</span></div><div class='line' id='LC1562'><span class="o">{</span></div><div class='line' id='LC1563'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_strategy <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1564'><br/></div><div class='line' id='LC1565'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1566'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1567'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1568'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--rebase --no-rebase</span></div><div class='line' id='LC1569'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_merge_options</span></div><div class='line' id='LC1570'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_fetch_options</span></div><div class='line' id='LC1571'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1572'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1573'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1574'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1575'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_remote_or_refspec</div><div class='line' id='LC1576'><span class="o">}</span></div><div class='line' id='LC1577'><br/></div><div class='line' id='LC1578'>_git_push <span class="o">()</span></div><div class='line' id='LC1579'><span class="o">{</span></div><div class='line' id='LC1580'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC1581'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--repo<span class="o">)</span></div><div class='line' id='LC1582'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC1583'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1584'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC1585'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1586'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--repo<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1587'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--repo=}&quot;</span></div><div class='line' id='LC1588'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1589'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1590'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1591'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1592'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all --mirror --tags --dry-run --force --verbose</span></div><div class='line' id='LC1593'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--receive-pack= --repo= --set-upstream</span></div><div class='line' id='LC1594'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1595'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1596'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1597'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1598'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_remote_or_refspec</div><div class='line' id='LC1599'><span class="o">}</span></div><div class='line' id='LC1600'><br/></div><div class='line' id='LC1601'>_git_rebase <span class="o">()</span></div><div class='line' id='LC1602'><span class="o">{</span></div><div class='line' id='LC1603'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">dir</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC1604'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span>/rebase-apply <span class="o">]</span> <span class="o">||</span> <span class="o">[</span> -d <span class="s2">&quot;$dir&quot;</span>/rebase-merge <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1605'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;--continue --skip --abort&quot;</span></div><div class='line' id='LC1606'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1607'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC1608'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_strategy <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC1609'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1610'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--whitespace<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1611'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_whitespacelist&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--whitespace=}&quot;</span></div><div class='line' id='LC1612'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1613'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1614'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1615'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1616'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--onto --merge --strategy --interactive</span></div><div class='line' id='LC1617'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--preserve-merges --stat --no-stat</span></div><div class='line' id='LC1618'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--committer-date-is-author-date --ignore-date</span></div><div class='line' id='LC1619'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-whitespace --whitespace=</span></div><div class='line' id='LC1620'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--autosquash</span></div><div class='line' id='LC1621'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1622'><br/></div><div class='line' id='LC1623'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1624'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;esac</span></div><div class='line' id='LC1625'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1626'><span class="o">}</span></div><div class='line' id='LC1627'><br/></div><div class='line' id='LC1628'>_git_reflog <span class="o">()</span></div><div class='line' id='LC1629'><span class="o">{</span></div><div class='line' id='LC1630'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s2">&quot;show delete expire&quot;</span></div><div class='line' id='LC1631'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC1632'><br/></div><div class='line' id='LC1633'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$subcommand&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1634'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC1635'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC1636'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1637'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC1638'><span class="o">}</span></div><div class='line' id='LC1639'><br/></div><div class='line' id='LC1640'><span class="nv">__git_send_email_confirm_options</span><span class="o">=</span><span class="s2">&quot;always never auto cc compose&quot;</span></div><div class='line' id='LC1641'><span class="nv">__git_send_email_suppresscc_options</span><span class="o">=</span><span class="s2">&quot;author self cc bodycc sob cccmd body all&quot;</span></div><div class='line' id='LC1642'><br/></div><div class='line' id='LC1643'>_git_send_email <span class="o">()</span></div><div class='line' id='LC1644'><span class="o">{</span></div><div class='line' id='LC1645'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1646'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--confirm<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1647'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1648'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_send_email_confirm_options</span></div><div class='line' id='LC1649'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--confirm=}&quot;</span></div><div class='line' id='LC1650'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1651'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1652'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--suppress-cc<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1653'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1654'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_send_email_suppresscc_options</span></div><div class='line' id='LC1655'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--suppress-cc=}&quot;</span></div><div class='line' id='LC1656'><br/></div><div class='line' id='LC1657'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1658'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1659'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--smtp-encryption<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1660'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;ssl tls&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--smtp-encryption=}&quot;</span></div><div class='line' id='LC1661'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1662'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1663'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--thread<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1664'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1665'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;deep shallow</span></div><div class='line' id='LC1666'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--thread=}&quot;</span></div><div class='line' id='LC1667'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1668'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1669'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1670'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--annotate --bcc --cc --cc-cmd --chain-reply-to</span></div><div class='line' id='LC1671'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--compose --confirm= --dry-run --envelope-sender</span></div><div class='line' id='LC1672'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--from --identity</span></div><div class='line' id='LC1673'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--in-reply-to --no-chain-reply-to --no-signed-off-by-cc</span></div><div class='line' id='LC1674'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-suppress-from --no-thread --quiet</span></div><div class='line' id='LC1675'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--signed-off-by-cc --smtp-pass --smtp-server</span></div><div class='line' id='LC1676'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--smtp-server-port --smtp-encryption= --smtp-user</span></div><div class='line' id='LC1677'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--subject --suppress-cc= --suppress-from --thread --to</span></div><div class='line' id='LC1678'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--validate --no-validate</span></div><div class='line' id='LC1679'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_format_patch_options&quot;</span></div><div class='line' id='LC1680'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1681'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1682'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1683'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC1684'><span class="o">}</span></div><div class='line' id='LC1685'><br/></div><div class='line' id='LC1686'>_git_stage <span class="o">()</span></div><div class='line' id='LC1687'><span class="o">{</span></div><div class='line' id='LC1688'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_git_add</div><div class='line' id='LC1689'><span class="o">}</span></div><div class='line' id='LC1690'><br/></div><div class='line' id='LC1691'>__git_config_get_set_variables <span class="o">()</span></div><div class='line' id='LC1692'><span class="o">{</span></div><div class='line' id='LC1693'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>prevword word <span class="nv">config_file</span><span class="o">=</span> <span class="nv">c</span><span class="o">=</span><span class="nv">$cword</span></div><div class='line' id='LC1694'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -gt 1 <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC1695'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">word</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC1696'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$word&quot;</span> in</div><div class='line' id='LC1697'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--system<span class="p">|</span>--global<span class="p">|</span>--local<span class="p">|</span>--file<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1698'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">config_file</span><span class="o">=</span><span class="s2">&quot;$word&quot;</span></div><div class='line' id='LC1699'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">break</span></div><div class='line' id='LC1700'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1701'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-f<span class="p">|</span>--file<span class="o">)</span></div><div class='line' id='LC1702'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">config_file</span><span class="o">=</span><span class="s2">&quot;$word $prevword&quot;</span></div><div class='line' id='LC1703'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">break</span></div><div class='line' id='LC1704'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1705'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1706'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">prevword</span><span class="o">=</span><span class="nv">$word</span></div><div class='line' id='LC1707'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">c</span><span class="o">=</span><span class="k">$((</span><span class="o">--</span>c<span class="k">))</span></div><div class='line' id='LC1708'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC1709'><br/></div><div class='line' id='LC1710'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> config <span class="nv">$config_file</span> --list 2&gt;/dev/null <span class="p">|</span></div><div class='line' id='LC1711'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while </span><span class="nb">read</span> -r line</div><div class='line' id='LC1712'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">do</span></div><div class='line' id='LC1713'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$line&quot;</span> in</div><div class='line' id='LC1714'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*.*<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC1715'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">echo</span> <span class="s2">&quot;${line/=*/}&quot;</span></div><div class='line' id='LC1716'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1717'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1718'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;done</span></div><div class='line' id='LC1719'><span class="o">}</span></div><div class='line' id='LC1720'><br/></div><div class='line' id='LC1721'>_git_config <span class="o">()</span></div><div class='line' id='LC1722'><span class="o">{</span></div><div class='line' id='LC1723'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC1724'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.*.remote<span class="p">|</span>branch.*.pushremote<span class="o">)</span></div><div class='line' id='LC1725'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC1726'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1727'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1728'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.*.merge<span class="o">)</span></div><div class='line' id='LC1729'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC1730'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1731'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1732'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.*.rebase<span class="o">)</span></div><div class='line' id='LC1733'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;false true&quot;</span></div><div class='line' id='LC1734'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1735'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1736'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.pushdefault<span class="o">)</span></div><div class='line' id='LC1737'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC1738'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1739'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1740'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.*.fetch<span class="o">)</span></div><div class='line' id='LC1741'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;${prev#remote.}&quot;</span></div><div class='line' id='LC1742'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;${remote%.fetch}&quot;</span></div><div class='line' id='LC1743'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$cur&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC1744'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;refs/heads/&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;&quot;</span></div><div class='line' id='LC1745'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1746'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC1747'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs_remotes &quot;</span><span class="nv">$remote</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC1748'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1749'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1750'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.*.push<span class="o">)</span></div><div class='line' id='LC1751'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;${prev#remote.}&quot;</span></div><div class='line' id='LC1752'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">remote</span><span class="o">=</span><span class="s2">&quot;${remote%.push}&quot;</span></div><div class='line' id='LC1753'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(git --git-dir=&quot;</span><span class="k">$(</span>__gitdir<span class="k">)</span><span class="s2">&quot; \</span></div><div class='line' id='LC1754'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;for-each-ref --format=&#39;%(refname):%(refname)&#39; \</span></div><div class='line' id='LC1755'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refs/heads)&quot;</span></div><div class='line' id='LC1756'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1757'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1758'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pull.twohead<span class="p">|</span>pull.octopus<span class="o">)</span></div><div class='line' id='LC1759'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_compute_merge_strategies</div><div class='line' id='LC1760'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_merge_strategies&quot;</span></div><div class='line' id='LC1761'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1762'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1763'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch<span class="p">|</span>color.diff<span class="p">|</span>color.interactive<span class="p">|</span><span class="se">\</span></div><div class='line' id='LC1764'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.showbranch<span class="p">|</span>color.status<span class="p">|</span>color.ui<span class="o">)</span></div><div class='line' id='LC1765'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;always never auto&quot;</span></div><div class='line' id='LC1766'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1767'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1768'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.pager<span class="o">)</span></div><div class='line' id='LC1769'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;false true&quot;</span></div><div class='line' id='LC1770'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1771'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1772'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.*.*<span class="o">)</span></div><div class='line' id='LC1773'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1774'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;normal black red green yellow blue magenta cyan white</span></div><div class='line' id='LC1775'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bold dim ul blink reverse</span></div><div class='line' id='LC1776'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1777'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1778'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1779'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.submodule<span class="o">)</span></div><div class='line' id='LC1780'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;log short&quot;</span></div><div class='line' id='LC1781'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1782'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1783'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;help.format<span class="o">)</span></div><div class='line' id='LC1784'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;man info web html&quot;</span></div><div class='line' id='LC1785'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1786'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1787'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;log.date<span class="o">)</span></div><div class='line' id='LC1788'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_log_date_formats&quot;</span></div><div class='line' id='LC1789'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1790'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1791'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.aliasesfiletype<span class="o">)</span></div><div class='line' id='LC1792'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;mutt mailrc pine elm gnus&quot;</span></div><div class='line' id='LC1793'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1794'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1795'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.confirm<span class="o">)</span></div><div class='line' id='LC1796'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_send_email_confirm_options&quot;</span></div><div class='line' id='LC1797'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1798'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1799'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.suppresscc<span class="o">)</span></div><div class='line' id='LC1800'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_send_email_suppresscc_options&quot;</span></div><div class='line' id='LC1801'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1802'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1803'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--get<span class="p">|</span>--get-all<span class="p">|</span>--unset<span class="p">|</span>--unset-all<span class="o">)</span></div><div class='line' id='LC1804'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_config_get_set_variables)&quot;</span></div><div class='line' id='LC1805'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1806'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1807'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*.*<span class="o">)</span></div><div class='line' id='LC1808'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1809'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1810'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1811'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC1812'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC1813'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1814'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--system --global --local --file=</span></div><div class='line' id='LC1815'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--list --replace-all</span></div><div class='line' id='LC1816'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--get --get-all --get-regexp</span></div><div class='line' id='LC1817'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--add --unset --unset-all</span></div><div class='line' id='LC1818'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--remove-section --rename-section</span></div><div class='line' id='LC1819'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC1820'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1821'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1822'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.*.*<span class="o">)</span></div><div class='line' id='LC1823'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1824'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;remote pushremote merge mergeoptions rebase&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1825'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1826'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1827'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.*<span class="o">)</span></div><div class='line' id='LC1828'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur#*.}&quot;</span></div><div class='line' id='LC1829'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_heads)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span> <span class="s2">&quot;.&quot;</span></div><div class='line' id='LC1830'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1831'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1832'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;guitool.*.*<span class="o">)</span></div><div class='line' id='LC1833'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1834'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1835'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;argprompt cmd confirm needsfile noconsole norescan</span></div><div class='line' id='LC1836'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;prompt revprompt revunmerged title</span></div><div class='line' id='LC1837'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1838'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1839'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1840'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;difftool.*.*<span class="o">)</span></div><div class='line' id='LC1841'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1842'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;cmd path&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1843'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1844'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1845'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;man.*.*<span class="o">)</span></div><div class='line' id='LC1846'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1847'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;cmd path&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1848'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1849'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1850'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mergetool.*.*<span class="o">)</span></div><div class='line' id='LC1851'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1852'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;cmd path trustExitCode&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1853'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1854'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1855'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pager.*<span class="o">)</span></div><div class='line' id='LC1856'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur#*.}&quot;</span></div><div class='line' id='LC1857'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_compute_all_commands</div><div class='line' id='LC1858'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$__git_all_commands&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1859'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1860'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1861'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.*.*<span class="o">)</span></div><div class='line' id='LC1862'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1863'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1864'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;url proxy fetch push mirror skipDefaultUpdate</span></div><div class='line' id='LC1865'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receivepack uploadpack tagopt pushurl</span></div><div class='line' id='LC1866'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1867'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1868'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1869'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.*<span class="o">)</span></div><div class='line' id='LC1870'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur#*.}&quot;</span></div><div class='line' id='LC1871'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span> <span class="s2">&quot;.&quot;</span></div><div class='line' id='LC1872'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1873'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1874'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;url.*.*<span class="o">)</span></div><div class='line' id='LC1875'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">pfx</span><span class="o">=</span><span class="s2">&quot;${cur%.*}.&quot;</span> <span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${cur##*.}&quot;</span></div><div class='line' id='LC1876'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;insteadOf pushInsteadOf&quot;</span> <span class="s2">&quot;$pfx&quot;</span> <span class="s2">&quot;$cur_&quot;</span></div><div class='line' id='LC1877'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC1878'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC1879'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC1880'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC1881'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add.ignoreErrors</span></div><div class='line' id='LC1882'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.commitBeforeMerge</span></div><div class='line' id='LC1883'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.detachedHead</span></div><div class='line' id='LC1884'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.implicitIdentity</span></div><div class='line' id='LC1885'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.pushNonFastForward</span></div><div class='line' id='LC1886'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.resolveConflict</span></div><div class='line' id='LC1887'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;advice.statusHints</span></div><div class='line' id='LC1888'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;alias.</span></div><div class='line' id='LC1889'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;am.keepcr</span></div><div class='line' id='LC1890'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;apply.ignorewhitespace</span></div><div class='line' id='LC1891'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;apply.whitespace</span></div><div class='line' id='LC1892'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.autosetupmerge</span></div><div class='line' id='LC1893'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch.autosetuprebase</span></div><div class='line' id='LC1894'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;browser.</span></div><div class='line' id='LC1895'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;clean.requireForce</span></div><div class='line' id='LC1896'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch</span></div><div class='line' id='LC1897'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch.current</span></div><div class='line' id='LC1898'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch.local</span></div><div class='line' id='LC1899'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch.plain</span></div><div class='line' id='LC1900'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.branch.remote</span></div><div class='line' id='LC1901'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.decorate.HEAD</span></div><div class='line' id='LC1902'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.decorate.branch</span></div><div class='line' id='LC1903'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.decorate.remoteBranch</span></div><div class='line' id='LC1904'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.decorate.stash</span></div><div class='line' id='LC1905'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.decorate.tag</span></div><div class='line' id='LC1906'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff</span></div><div class='line' id='LC1907'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.commit</span></div><div class='line' id='LC1908'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.frag</span></div><div class='line' id='LC1909'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.func</span></div><div class='line' id='LC1910'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.meta</span></div><div class='line' id='LC1911'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.new</span></div><div class='line' id='LC1912'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.old</span></div><div class='line' id='LC1913'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.plain</span></div><div class='line' id='LC1914'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.diff.whitespace</span></div><div class='line' id='LC1915'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep</span></div><div class='line' id='LC1916'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.context</span></div><div class='line' id='LC1917'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.filename</span></div><div class='line' id='LC1918'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.function</span></div><div class='line' id='LC1919'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.linenumber</span></div><div class='line' id='LC1920'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.match</span></div><div class='line' id='LC1921'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.selected</span></div><div class='line' id='LC1922'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.grep.separator</span></div><div class='line' id='LC1923'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.interactive</span></div><div class='line' id='LC1924'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.interactive.error</span></div><div class='line' id='LC1925'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.interactive.header</span></div><div class='line' id='LC1926'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.interactive.help</span></div><div class='line' id='LC1927'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.interactive.prompt</span></div><div class='line' id='LC1928'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.pager</span></div><div class='line' id='LC1929'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.showbranch</span></div><div class='line' id='LC1930'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status</span></div><div class='line' id='LC1931'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.added</span></div><div class='line' id='LC1932'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.changed</span></div><div class='line' id='LC1933'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.header</span></div><div class='line' id='LC1934'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.nobranch</span></div><div class='line' id='LC1935'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.untracked</span></div><div class='line' id='LC1936'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.status.updated</span></div><div class='line' id='LC1937'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color.ui</span></div><div class='line' id='LC1938'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commit.status</span></div><div class='line' id='LC1939'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commit.template</span></div><div class='line' id='LC1940'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.abbrev</span></div><div class='line' id='LC1941'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.askpass</span></div><div class='line' id='LC1942'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.attributesfile</span></div><div class='line' id='LC1943'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.autocrlf</span></div><div class='line' id='LC1944'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.bare</span></div><div class='line' id='LC1945'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.bigFileThreshold</span></div><div class='line' id='LC1946'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.compression</span></div><div class='line' id='LC1947'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.createObject</span></div><div class='line' id='LC1948'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.deltaBaseCacheLimit</span></div><div class='line' id='LC1949'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.editor</span></div><div class='line' id='LC1950'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.eol</span></div><div class='line' id='LC1951'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.excludesfile</span></div><div class='line' id='LC1952'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.fileMode</span></div><div class='line' id='LC1953'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.fsyncobjectfiles</span></div><div class='line' id='LC1954'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.gitProxy</span></div><div class='line' id='LC1955'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.ignoreStat</span></div><div class='line' id='LC1956'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.ignorecase</span></div><div class='line' id='LC1957'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.logAllRefUpdates</span></div><div class='line' id='LC1958'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.loosecompression</span></div><div class='line' id='LC1959'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.notesRef</span></div><div class='line' id='LC1960'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.packedGitLimit</span></div><div class='line' id='LC1961'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.packedGitWindowSize</span></div><div class='line' id='LC1962'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.pager</span></div><div class='line' id='LC1963'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.preferSymlinkRefs</span></div><div class='line' id='LC1964'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.preloadindex</span></div><div class='line' id='LC1965'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.quotepath</span></div><div class='line' id='LC1966'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.repositoryFormatVersion</span></div><div class='line' id='LC1967'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.safecrlf</span></div><div class='line' id='LC1968'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.sharedRepository</span></div><div class='line' id='LC1969'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.sparseCheckout</span></div><div class='line' id='LC1970'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.symlinks</span></div><div class='line' id='LC1971'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.trustctime</span></div><div class='line' id='LC1972'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.warnAmbiguousRefs</span></div><div class='line' id='LC1973'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.whitespace</span></div><div class='line' id='LC1974'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;core.worktree</span></div><div class='line' id='LC1975'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.autorefreshindex</span></div><div class='line' id='LC1976'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.external</span></div><div class='line' id='LC1977'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.ignoreSubmodules</span></div><div class='line' id='LC1978'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.mnemonicprefix</span></div><div class='line' id='LC1979'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.noprefix</span></div><div class='line' id='LC1980'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.renameLimit</span></div><div class='line' id='LC1981'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.renames</span></div><div class='line' id='LC1982'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.statGraphWidth</span></div><div class='line' id='LC1983'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.submodule</span></div><div class='line' id='LC1984'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.suppressBlankEmpty</span></div><div class='line' id='LC1985'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.tool</span></div><div class='line' id='LC1986'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.wordRegex</span></div><div class='line' id='LC1987'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;diff.algorithm</span></div><div class='line' id='LC1988'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;difftool.</span></div><div class='line' id='LC1989'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;difftool.prompt</span></div><div class='line' id='LC1990'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch.recurseSubmodules</span></div><div class='line' id='LC1991'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch.unpackLimit</span></div><div class='line' id='LC1992'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.attach</span></div><div class='line' id='LC1993'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.cc</span></div><div class='line' id='LC1994'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.headers</span></div><div class='line' id='LC1995'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.numbered</span></div><div class='line' id='LC1996'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.pretty</span></div><div class='line' id='LC1997'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.signature</span></div><div class='line' id='LC1998'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.signoff</span></div><div class='line' id='LC1999'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.subjectprefix</span></div><div class='line' id='LC2000'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.suffix</span></div><div class='line' id='LC2001'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.thread</span></div><div class='line' id='LC2002'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format.to</span></div><div class='line' id='LC2003'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.</span></div><div class='line' id='LC2004'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.aggressiveWindow</span></div><div class='line' id='LC2005'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.auto</span></div><div class='line' id='LC2006'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.autopacklimit</span></div><div class='line' id='LC2007'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.packrefs</span></div><div class='line' id='LC2008'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.pruneexpire</span></div><div class='line' id='LC2009'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.reflogexpire</span></div><div class='line' id='LC2010'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.reflogexpireunreachable</span></div><div class='line' id='LC2011'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.rerereresolved</span></div><div class='line' id='LC2012'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gc.rerereunresolved</span></div><div class='line' id='LC2013'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.allbinary</span></div><div class='line' id='LC2014'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.commitmsgannotation</span></div><div class='line' id='LC2015'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.dbTableNamePrefix</span></div><div class='line' id='LC2016'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.dbdriver</span></div><div class='line' id='LC2017'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.dbname</span></div><div class='line' id='LC2018'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.dbpass</span></div><div class='line' id='LC2019'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.dbuser</span></div><div class='line' id='LC2020'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.enabled</span></div><div class='line' id='LC2021'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.logfile</span></div><div class='line' id='LC2022'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gitcvs.usecrlfattr</span></div><div class='line' id='LC2023'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;guitool.</span></div><div class='line' id='LC2024'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.blamehistoryctx</span></div><div class='line' id='LC2025'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.commitmsgwidth</span></div><div class='line' id='LC2026'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.copyblamethreshold</span></div><div class='line' id='LC2027'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.diffcontext</span></div><div class='line' id='LC2028'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.encoding</span></div><div class='line' id='LC2029'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.fastcopyblame</span></div><div class='line' id='LC2030'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.matchtrackingbranch</span></div><div class='line' id='LC2031'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.newbranchtemplate</span></div><div class='line' id='LC2032'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.pruneduringfetch</span></div><div class='line' id='LC2033'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.spellingdictionary</span></div><div class='line' id='LC2034'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gui.trustmtime</span></div><div class='line' id='LC2035'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;help.autocorrect</span></div><div class='line' id='LC2036'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;help.browser</span></div><div class='line' id='LC2037'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;help.format</span></div><div class='line' id='LC2038'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.lowSpeedLimit</span></div><div class='line' id='LC2039'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.lowSpeedTime</span></div><div class='line' id='LC2040'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.maxRequests</span></div><div class='line' id='LC2041'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.minSessions</span></div><div class='line' id='LC2042'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.noEPSV</span></div><div class='line' id='LC2043'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.postBuffer</span></div><div class='line' id='LC2044'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.proxy</span></div><div class='line' id='LC2045'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslCAInfo</span></div><div class='line' id='LC2046'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslCAPath</span></div><div class='line' id='LC2047'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslCert</span></div><div class='line' id='LC2048'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslCertPasswordProtected</span></div><div class='line' id='LC2049'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslKey</span></div><div class='line' id='LC2050'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.sslVerify</span></div><div class='line' id='LC2051'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http.useragent</span></div><div class='line' id='LC2052'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;i18n.commitEncoding</span></div><div class='line' id='LC2053'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;i18n.logOutputEncoding</span></div><div class='line' id='LC2054'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.authMethod</span></div><div class='line' id='LC2055'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.folder</span></div><div class='line' id='LC2056'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.host</span></div><div class='line' id='LC2057'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.pass</span></div><div class='line' id='LC2058'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.port</span></div><div class='line' id='LC2059'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.preformattedHTML</span></div><div class='line' id='LC2060'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.sslverify</span></div><div class='line' id='LC2061'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.tunnel</span></div><div class='line' id='LC2062'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imap.user</span></div><div class='line' id='LC2063'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;init.templatedir</span></div><div class='line' id='LC2064'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instaweb.browser</span></div><div class='line' id='LC2065'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instaweb.httpd</span></div><div class='line' id='LC2066'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instaweb.local</span></div><div class='line' id='LC2067'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instaweb.modulepath</span></div><div class='line' id='LC2068'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instaweb.port</span></div><div class='line' id='LC2069'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;interactive.singlekey</span></div><div class='line' id='LC2070'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;log.date</span></div><div class='line' id='LC2071'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;log.decorate</span></div><div class='line' id='LC2072'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;log.showroot</span></div><div class='line' id='LC2073'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mailmap.file</span></div><div class='line' id='LC2074'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;man.</span></div><div class='line' id='LC2075'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;man.viewer</span></div><div class='line' id='LC2076'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.</span></div><div class='line' id='LC2077'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.conflictstyle</span></div><div class='line' id='LC2078'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.log</span></div><div class='line' id='LC2079'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.renameLimit</span></div><div class='line' id='LC2080'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.renormalize</span></div><div class='line' id='LC2081'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.stat</span></div><div class='line' id='LC2082'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.tool</span></div><div class='line' id='LC2083'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;merge.verbosity</span></div><div class='line' id='LC2084'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mergetool.</span></div><div class='line' id='LC2085'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mergetool.keepBackup</span></div><div class='line' id='LC2086'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mergetool.keepTemporaries</span></div><div class='line' id='LC2087'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mergetool.prompt</span></div><div class='line' id='LC2088'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.displayRef</span></div><div class='line' id='LC2089'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.rewrite.</span></div><div class='line' id='LC2090'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.rewrite.amend</span></div><div class='line' id='LC2091'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.rewrite.rebase</span></div><div class='line' id='LC2092'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.rewriteMode</span></div><div class='line' id='LC2093'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notes.rewriteRef</span></div><div class='line' id='LC2094'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.compression</span></div><div class='line' id='LC2095'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.deltaCacheLimit</span></div><div class='line' id='LC2096'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.deltaCacheSize</span></div><div class='line' id='LC2097'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.depth</span></div><div class='line' id='LC2098'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.indexVersion</span></div><div class='line' id='LC2099'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.packSizeLimit</span></div><div class='line' id='LC2100'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.threads</span></div><div class='line' id='LC2101'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.window</span></div><div class='line' id='LC2102'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pack.windowMemory</span></div><div class='line' id='LC2103'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pager.</span></div><div class='line' id='LC2104'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pretty.</span></div><div class='line' id='LC2105'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pull.octopus</span></div><div class='line' id='LC2106'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pull.twohead</span></div><div class='line' id='LC2107'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;push.default</span></div><div class='line' id='LC2108'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rebase.autosquash</span></div><div class='line' id='LC2109'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rebase.stat</span></div><div class='line' id='LC2110'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.autogc</span></div><div class='line' id='LC2111'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.denyCurrentBranch</span></div><div class='line' id='LC2112'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.denyDeleteCurrent</span></div><div class='line' id='LC2113'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.denyDeletes</span></div><div class='line' id='LC2114'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.denyNonFastForwards</span></div><div class='line' id='LC2115'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.fsckObjects</span></div><div class='line' id='LC2116'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.unpackLimit</span></div><div class='line' id='LC2117'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;receive.updateserverinfo</span></div><div class='line' id='LC2118'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remote.pushdefault</span></div><div class='line' id='LC2119'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;remotes.</span></div><div class='line' id='LC2120'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;repack.usedeltabaseoffset</span></div><div class='line' id='LC2121'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rerere.autoupdate</span></div><div class='line' id='LC2122'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rerere.enabled</span></div><div class='line' id='LC2123'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.</span></div><div class='line' id='LC2124'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.aliasesfile</span></div><div class='line' id='LC2125'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.aliasfiletype</span></div><div class='line' id='LC2126'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.bcc</span></div><div class='line' id='LC2127'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.cc</span></div><div class='line' id='LC2128'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.cccmd</span></div><div class='line' id='LC2129'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.chainreplyto</span></div><div class='line' id='LC2130'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.confirm</span></div><div class='line' id='LC2131'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.envelopesender</span></div><div class='line' id='LC2132'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.from</span></div><div class='line' id='LC2133'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.identity</span></div><div class='line' id='LC2134'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.multiedit</span></div><div class='line' id='LC2135'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.signedoffbycc</span></div><div class='line' id='LC2136'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpdomain</span></div><div class='line' id='LC2137'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpencryption</span></div><div class='line' id='LC2138'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtppass</span></div><div class='line' id='LC2139'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpserver</span></div><div class='line' id='LC2140'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpserveroption</span></div><div class='line' id='LC2141'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpserverport</span></div><div class='line' id='LC2142'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.smtpuser</span></div><div class='line' id='LC2143'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.suppresscc</span></div><div class='line' id='LC2144'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.suppressfrom</span></div><div class='line' id='LC2145'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.thread</span></div><div class='line' id='LC2146'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.to</span></div><div class='line' id='LC2147'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sendemail.validate</span></div><div class='line' id='LC2148'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;showbranch.default</span></div><div class='line' id='LC2149'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;status.relativePaths</span></div><div class='line' id='LC2150'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;status.showUntrackedFiles</span></div><div class='line' id='LC2151'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;status.submodulesummary</span></div><div class='line' id='LC2152'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;submodule.</span></div><div class='line' id='LC2153'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tar.umask</span></div><div class='line' id='LC2154'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;transfer.unpackLimit</span></div><div class='line' id='LC2155'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;url.</span></div><div class='line' id='LC2156'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;user.email</span></div><div class='line' id='LC2157'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;user.name</span></div><div class='line' id='LC2158'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;user.signingkey</span></div><div class='line' id='LC2159'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;web.browser</span></div><div class='line' id='LC2160'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch. remote.</span></div><div class='line' id='LC2161'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2162'><span class="o">}</span></div><div class='line' id='LC2163'><br/></div><div class='line' id='LC2164'>_git_remote <span class="o">()</span></div><div class='line' id='LC2165'><span class="o">{</span></div><div class='line' id='LC2166'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s2">&quot;add rename remove set-head set-branches set-url show prune update&quot;</span></div><div class='line' id='LC2167'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC2168'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$subcommand&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2169'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC2170'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2171'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC2172'><br/></div><div class='line' id='LC2173'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$subcommand&quot;</span> in</div><div class='line' id='LC2174'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rename<span class="p">|</span>remove<span class="p">|</span><span class="nb">set</span>-url<span class="p">|</span>show<span class="p">|</span>prune<span class="o">)</span></div><div class='line' id='LC2175'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_remotes)&quot;</span></div><div class='line' id='LC2176'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2177'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">set</span>-head<span class="p">|</span><span class="nb">set</span>-branches<span class="o">)</span></div><div class='line' id='LC2178'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_complete_remote_or_refspec</div><div class='line' id='LC2179'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2180'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;update<span class="o">)</span></div><div class='line' id='LC2181'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">c</span><span class="o">=</span><span class="s1">&#39;&#39;</span> <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC2182'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>i in <span class="k">$(</span>git --git-dir<span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span> config --get-regexp <span class="s2">&quot;remotes\..*&quot;</span> 2&gt;/dev/null<span class="k">)</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC2183'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${i#remotes.}&quot;</span></div><div class='line' id='LC2184'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">c</span><span class="o">=</span><span class="s2">&quot;$c ${i/ */}&quot;</span></div><div class='line' id='LC2185'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC2186'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$c&quot;</span></div><div class='line' id='LC2187'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2188'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2189'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2190'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2191'><span class="o">}</span></div><div class='line' id='LC2192'><br/></div><div class='line' id='LC2193'>_git_replace <span class="o">()</span></div><div class='line' id='LC2194'><span class="o">{</span></div><div class='line' id='LC2195'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC2196'><span class="o">}</span></div><div class='line' id='LC2197'><br/></div><div class='line' id='LC2198'>_git_reset <span class="o">()</span></div><div class='line' id='LC2199'><span class="o">{</span></div><div class='line' id='LC2200'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2201'><br/></div><div class='line' id='LC2202'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2203'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2204'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--merge --mixed --hard --soft --patch&quot;</span></div><div class='line' id='LC2205'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2206'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2207'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2208'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC2209'><span class="o">}</span></div><div class='line' id='LC2210'><br/></div><div class='line' id='LC2211'>_git_revert <span class="o">()</span></div><div class='line' id='LC2212'><span class="o">{</span></div><div class='line' id='LC2213'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2214'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2215'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--edit --mainline --no-edit --no-commit --signoff&quot;</span></div><div class='line' id='LC2216'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2217'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2218'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2219'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC2220'><span class="o">}</span></div><div class='line' id='LC2221'><br/></div><div class='line' id='LC2222'>_git_rm <span class="o">()</span></div><div class='line' id='LC2223'><span class="o">{</span></div><div class='line' id='LC2224'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2225'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2226'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--cached --dry-run --ignore-unmatch --quiet&quot;</span></div><div class='line' id='LC2227'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2228'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2229'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2230'><br/></div><div class='line' id='LC2231'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_index_file <span class="s2">&quot;--cached&quot;</span></div><div class='line' id='LC2232'><span class="o">}</span></div><div class='line' id='LC2233'><br/></div><div class='line' id='LC2234'>_git_shortlog <span class="o">()</span></div><div class='line' id='LC2235'><span class="o">{</span></div><div class='line' id='LC2236'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2237'><br/></div><div class='line' id='LC2238'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2239'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2240'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2241'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_common_options</span></div><div class='line' id='LC2242'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_shortlog_options</span></div><div class='line' id='LC2243'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--numbered --summary</span></div><div class='line' id='LC2244'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2245'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2246'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2247'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2248'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC2249'><span class="o">}</span></div><div class='line' id='LC2250'><br/></div><div class='line' id='LC2251'>_git_show <span class="o">()</span></div><div class='line' id='LC2252'><span class="o">{</span></div><div class='line' id='LC2253'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2254'><br/></div><div class='line' id='LC2255'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2256'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--pretty<span class="o">=</span>*<span class="p">|</span>--format<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC2257'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_log_pretty_formats $(__git_pretty_aliases)</span></div><div class='line' id='LC2258'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur#*=}&quot;</span></div><div class='line' id='LC2259'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2260'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2261'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--diff-algorithm<span class="o">=</span>*<span class="o">)</span></div><div class='line' id='LC2262'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$__git_diff_algorithms&quot;</span> <span class="s2">&quot;&quot;</span> <span class="s2">&quot;${cur##--diff-algorithm=}&quot;</span></div><div class='line' id='LC2263'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2264'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2265'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2266'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--pretty= --format= --abbrev-commit --oneline</span></div><div class='line' id='LC2267'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_diff_common_options</span></div><div class='line' id='LC2268'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2269'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2270'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2271'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2272'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist_file</div><div class='line' id='LC2273'><span class="o">}</span></div><div class='line' id='LC2274'><br/></div><div class='line' id='LC2275'>_git_show_branch <span class="o">()</span></div><div class='line' id='LC2276'><span class="o">{</span></div><div class='line' id='LC2277'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2278'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2279'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2280'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--all --remotes --topo-order --current --more=</span></div><div class='line' id='LC2281'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--list --independent --merge-base --no-name</span></div><div class='line' id='LC2282'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--color --no-color</span></div><div class='line' id='LC2283'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--sha1-name --sparse --topics --reflog</span></div><div class='line' id='LC2284'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2285'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2286'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2287'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2288'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC2289'><span class="o">}</span></div><div class='line' id='LC2290'><br/></div><div class='line' id='LC2291'>_git_stash <span class="o">()</span></div><div class='line' id='LC2292'><span class="o">{</span></div><div class='line' id='LC2293'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">save_opts</span><span class="o">=</span><span class="s1">&#39;--keep-index --no-keep-index --quiet --patch&#39;</span></div><div class='line' id='LC2294'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s1">&#39;save list show apply clear drop pop create branch&#39;</span></div><div class='line' id='LC2295'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC2296'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$subcommand&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2297'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2298'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2299'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$save_opts&quot;</span></div><div class='line' id='LC2300'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2301'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2302'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$save_opts</span><span class="s2">&quot;)&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2303'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC2304'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC2305'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2306'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2307'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else</span></div><div class='line' id='LC2308'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$subcommand,$cur&quot;</span> in</div><div class='line' id='LC2309'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;save,--*<span class="o">)</span></div><div class='line' id='LC2310'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$save_opts&quot;</span></div><div class='line' id='LC2311'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2312'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;apply,--*<span class="p">|</span>pop,--*<span class="o">)</span></div><div class='line' id='LC2313'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--index --quiet&quot;</span></div><div class='line' id='LC2314'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2315'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show,--*<span class="p">|</span>drop,--*<span class="p">|</span>branch,--*<span class="o">)</span></div><div class='line' id='LC2316'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2317'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show,*<span class="p">|</span>apply,*<span class="p">|</span>drop,*<span class="p">|</span>pop,*<span class="p">|</span>branch,*<span class="o">)</span></div><div class='line' id='LC2318'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(git --git-dir=&quot;</span><span class="k">$(</span>__gitdir<span class="k">)</span><span class="s2">&quot; stash list \</span></div><div class='line' id='LC2319'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| sed -n -e &#39;s/:.*//p&#39;)&quot;</span></div><div class='line' id='LC2320'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2321'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2322'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2323'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2324'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC2325'><span class="o">}</span></div><div class='line' id='LC2326'><br/></div><div class='line' id='LC2327'>_git_submodule <span class="o">()</span></div><div class='line' id='LC2328'><span class="o">{</span></div><div class='line' id='LC2329'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2330'><br/></div><div class='line' id='LC2331'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s2">&quot;add status init deinit update summary foreach sync&quot;</span></div><div class='line' id='LC2332'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2333'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2334'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2335'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--quiet --cached&quot;</span></div><div class='line' id='LC2336'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2337'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2338'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC2339'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2340'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2341'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return</span></div><div class='line' id='LC2342'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC2343'><span class="o">}</span></div><div class='line' id='LC2344'><br/></div><div class='line' id='LC2345'>_git_svn <span class="o">()</span></div><div class='line' id='LC2346'><span class="o">{</span></div><div class='line' id='LC2347'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommands</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC2348'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;init fetch clone rebase dcommit log find-rev</span></div><div class='line' id='LC2349'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set-tree commit-diff info create-ignore propget</span></div><div class='line' id='LC2350'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;proplist show-ignore show-externals branch tag blame</span></div><div class='line' id='LC2351'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;migrate mkdirs reset gc</span></div><div class='line' id='LC2352'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2353'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">subcommand</span><span class="o">=</span><span class="s2">&quot;$(__git_find_on_cmdline &quot;</span><span class="nv">$subcommands</span><span class="s2">&quot;)&quot;</span></div><div class='line' id='LC2354'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -z <span class="s2">&quot;$subcommand&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2355'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp <span class="s2">&quot;$subcommands&quot;</span></div><div class='line' id='LC2356'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC2357'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">remote_opts</span><span class="o">=</span><span class="s2">&quot;--username= --config-dir= --no-auth-cache&quot;</span></div><div class='line' id='LC2358'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">fc_opts</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC2359'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--follow-parent --authors-file= --repack=</span></div><div class='line' id='LC2360'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-metadata --use-svm-props --use-svnsync-props</span></div><div class='line' id='LC2361'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--log-window-size= --no-checkout --quiet</span></div><div class='line' id='LC2362'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--repack-flags --use-log-author --localtime</span></div><div class='line' id='LC2363'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--ignore-paths= --include-paths= $remote_opts</span></div><div class='line' id='LC2364'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2365'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">init_opts</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC2366'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--template= --shared= --trunk= --tags=</span></div><div class='line' id='LC2367'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--branches= --stdlayout --minimize-url</span></div><div class='line' id='LC2368'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-metadata --use-svm-props --use-svnsync-props</span></div><div class='line' id='LC2369'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--rewrite-root= --prefix= --use-log-author</span></div><div class='line' id='LC2370'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--add-author-from $remote_opts</span></div><div class='line' id='LC2371'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2372'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">cmt_opts</span><span class="o">=</span><span class="s2">&quot;</span></div><div class='line' id='LC2373'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--edit --rmdir --find-copies-harder --copy-similarity=</span></div><div class='line' id='LC2374'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2375'><br/></div><div class='line' id='LC2376'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$subcommand,$cur&quot;</span> in</div><div class='line' id='LC2377'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fetch,--*<span class="o">)</span></div><div class='line' id='LC2378'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--revision= --fetch-all $fc_opts&quot;</span></div><div class='line' id='LC2379'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2380'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;clone,--*<span class="o">)</span></div><div class='line' id='LC2381'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--revision= $fc_opts $init_opts&quot;</span></div><div class='line' id='LC2382'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2383'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;init,--*<span class="o">)</span></div><div class='line' id='LC2384'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;$init_opts&quot;</span></div><div class='line' id='LC2385'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2386'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dcommit,--*<span class="o">)</span></div><div class='line' id='LC2387'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2388'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--merge --strategy= --verbose --dry-run</span></div><div class='line' id='LC2389'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--fetch-all --no-rebase --commit-url</span></div><div class='line' id='LC2390'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--revision --interactive $cmt_opts $fc_opts</span></div><div class='line' id='LC2391'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2392'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2393'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">set</span>-tree,--*<span class="o">)</span></div><div class='line' id='LC2394'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--stdin $cmt_opts $fc_opts&quot;</span></div><div class='line' id='LC2395'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2396'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;create-ignore,--*<span class="p">|</span>propget,--*<span class="p">|</span>proplist,--*<span class="p">|</span>show-ignore,--*<span class="p">|</span><span class="se">\</span></div><div class='line' id='LC2397'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show-externals,--*<span class="p">|</span>mkdirs,--*<span class="o">)</span></div><div class='line' id='LC2398'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--revision=&quot;</span></div><div class='line' id='LC2399'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2400'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;log,--*<span class="o">)</span></div><div class='line' id='LC2401'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2402'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--limit= --revision= --verbose --incremental</span></div><div class='line' id='LC2403'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--oneline --show-commit --non-recursive</span></div><div class='line' id='LC2404'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--authors-file= --color</span></div><div class='line' id='LC2405'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2406'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2407'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rebase,--*<span class="o">)</span></div><div class='line' id='LC2408'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2409'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--merge --verbose --strategy= --local</span></div><div class='line' id='LC2410'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--fetch-all --dry-run $fc_opts</span></div><div class='line' id='LC2411'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2412'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2413'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commit-diff,--*<span class="o">)</span></div><div class='line' id='LC2414'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--message= --file= --revision= $cmt_opts&quot;</span></div><div class='line' id='LC2415'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2416'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;info,--*<span class="o">)</span></div><div class='line' id='LC2417'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--url&quot;</span></div><div class='line' id='LC2418'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2419'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;branch,--*<span class="o">)</span></div><div class='line' id='LC2420'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--dry-run --message --tag&quot;</span></div><div class='line' id='LC2421'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2422'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tag,--*<span class="o">)</span></div><div class='line' id='LC2423'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--dry-run --message&quot;</span></div><div class='line' id='LC2424'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2425'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;blame,--*<span class="o">)</span></div><div class='line' id='LC2426'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--git-format&quot;</span></div><div class='line' id='LC2427'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2428'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;migrate,--*<span class="o">)</span></div><div class='line' id='LC2429'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2430'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--config-dir= --ignore-paths= --minimize</span></div><div class='line' id='LC2431'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-auth-cache --username=</span></div><div class='line' id='LC2432'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2433'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2434'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;reset,--*<span class="o">)</span></div><div class='line' id='LC2435'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;--revision= --parent&quot;</span></div><div class='line' id='LC2436'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2437'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2438'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2439'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2440'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC2441'><span class="o">}</span></div><div class='line' id='LC2442'><br/></div><div class='line' id='LC2443'>_git_tag <span class="o">()</span></div><div class='line' id='LC2444'><span class="o">{</span></div><div class='line' id='LC2445'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">c</span><span class="o">=</span>1 <span class="nv">f</span><span class="o">=</span>0</div><div class='line' id='LC2446'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC2447'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC2448'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC2449'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-d<span class="p">|</span>-v<span class="o">)</span></div><div class='line' id='LC2450'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_tags)&quot;</span></div><div class='line' id='LC2451'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2452'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2453'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-f<span class="o">)</span></div><div class='line' id='LC2454'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">f</span><span class="o">=</span>1</div><div class='line' id='LC2455'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2456'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2457'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC2458'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC2459'><br/></div><div class='line' id='LC2460'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$prev&quot;</span> in</div><div class='line' id='LC2461'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-m<span class="p">|</span>-F<span class="o">)</span></div><div class='line' id='LC2462'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2463'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-*<span class="p">|</span>tag<span class="o">)</span></div><div class='line' id='LC2464'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> <span class="nv">$f</span> <span class="o">=</span> 1 <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2465'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__gitcomp_nl <span class="s2">&quot;$(__git_tags)&quot;</span></div><div class='line' id='LC2466'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC2467'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2468'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2469'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="s2">&quot;$(__git_refs)&quot;</span></div><div class='line' id='LC2470'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2471'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2472'><span class="o">}</span></div><div class='line' id='LC2473'><br/></div><div class='line' id='LC2474'>_git_whatchanged <span class="o">()</span></div><div class='line' id='LC2475'><span class="o">{</span></div><div class='line' id='LC2476'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_git_log</div><div class='line' id='LC2477'><span class="o">}</span></div><div class='line' id='LC2478'><br/></div><div class='line' id='LC2479'>__git_main <span class="o">()</span></div><div class='line' id='LC2480'><span class="o">{</span></div><div class='line' id='LC2481'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>i <span class="nv">c</span><span class="o">=</span>1 <span class="nb">command </span>__git_dir</div><div class='line' id='LC2482'><br/></div><div class='line' id='LC2483'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">while</span> <span class="o">[</span> <span class="nv">$c</span> -lt <span class="nv">$cword</span> <span class="o">]</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC2484'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">i</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span></div><div class='line' id='LC2485'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$i&quot;</span> in</div><div class='line' id='LC2486'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--git-dir<span class="o">=</span>*<span class="o">)</span> <span class="nv">__git_dir</span><span class="o">=</span><span class="s2">&quot;${i#--git-dir=}&quot;</span> <span class="p">;;</span></div><div class='line' id='LC2487'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--git-dir<span class="o">)</span>   <span class="o">((</span>c++<span class="o">))</span> <span class="p">;</span> <span class="nv">__git_dir</span><span class="o">=</span><span class="s2">&quot;${words[c]}&quot;</span> <span class="p">;;</span></div><div class='line' id='LC2488'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--bare<span class="o">)</span>      <span class="nv">__git_dir</span><span class="o">=</span><span class="s2">&quot;.&quot;</span> <span class="p">;;</span></div><div class='line' id='LC2489'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--help<span class="o">)</span> <span class="nb">command</span><span class="o">=</span><span class="s2">&quot;help&quot;</span><span class="p">;</span> <span class="nb">break</span> <span class="p">;;</span></div><div class='line' id='LC2490'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-c<span class="p">|</span>--work-tree<span class="p">|</span>--namespace<span class="o">)</span> <span class="o">((</span>c++<span class="o">))</span> <span class="p">;;</span></div><div class='line' id='LC2491'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-*<span class="o">)</span> <span class="p">;;</span></div><div class='line' id='LC2492'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nb">command</span><span class="o">=</span><span class="s2">&quot;$i&quot;</span><span class="p">;</span> <span class="nb">break</span> <span class="p">;;</span></div><div class='line' id='LC2493'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2494'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">((</span>c++<span class="o">))</span></div><div class='line' id='LC2495'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC2496'><br/></div><div class='line' id='LC2497'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if</span> <span class="o">[</span> -z <span class="s2">&quot;$command&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2498'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2499'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span>   __gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2500'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--paginate</span></div><div class='line' id='LC2501'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-pager</span></div><div class='line' id='LC2502'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--git-dir=</span></div><div class='line' id='LC2503'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--bare</span></div><div class='line' id='LC2504'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--version</span></div><div class='line' id='LC2505'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--exec-path</span></div><div class='line' id='LC2506'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--exec-path=</span></div><div class='line' id='LC2507'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--html-path</span></div><div class='line' id='LC2508'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--man-path</span></div><div class='line' id='LC2509'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--info-path</span></div><div class='line' id='LC2510'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--work-tree=</span></div><div class='line' id='LC2511'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--namespace=</span></div><div class='line' id='LC2512'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--no-replace-objects</span></div><div class='line' id='LC2513'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--help</span></div><div class='line' id='LC2514'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2515'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2516'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span>     __git_compute_porcelain_commands</div><div class='line' id='LC2517'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       __gitcomp <span class="s2">&quot;$__git_porcelain_commands $(__git_aliases)&quot;</span> <span class="p">;;</span></div><div class='line' id='LC2518'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2519'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return</span></div><div class='line' id='LC2520'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fi</span></div><div class='line' id='LC2521'><br/></div><div class='line' id='LC2522'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">completion_func</span><span class="o">=</span><span class="s2">&quot;_git_${command//-/_}&quot;</span></div><div class='line' id='LC2523'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">declare</span> -f <span class="nv">$completion_func</span> &gt;/dev/null <span class="o">&amp;&amp;</span> <span class="nv">$completion_func</span> <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2524'><br/></div><div class='line' id='LC2525'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">expansion</span><span class="o">=</span><span class="k">$(</span>__git_aliased_command <span class="s2">&quot;$command&quot;</span><span class="k">)</span></div><div class='line' id='LC2526'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -n <span class="s2">&quot;$expansion&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2527'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">completion_func</span><span class="o">=</span><span class="s2">&quot;_git_${expansion//-/_}&quot;</span></div><div class='line' id='LC2528'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">declare</span> -f <span class="nv">$completion_func</span> &gt;/dev/null <span class="o">&amp;&amp;</span> <span class="nv">$completion_func</span></div><div class='line' id='LC2529'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC2530'><span class="o">}</span></div><div class='line' id='LC2531'><br/></div><div class='line' id='LC2532'>__gitk_main <span class="o">()</span></div><div class='line' id='LC2533'><span class="o">{</span></div><div class='line' id='LC2534'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_has_doubledash <span class="o">&amp;&amp;</span> <span class="k">return</span></div><div class='line' id='LC2535'><br/></div><div class='line' id='LC2536'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">local </span><span class="nv">g</span><span class="o">=</span><span class="s2">&quot;$(__gitdir)&quot;</span></div><div class='line' id='LC2537'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">merge</span><span class="o">=</span><span class="s2">&quot;&quot;</span></div><div class='line' id='LC2538'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">[</span> -f <span class="s2">&quot;$g/MERGE_HEAD&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2539'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">merge</span><span class="o">=</span><span class="s2">&quot;--merge&quot;</span></div><div class='line' id='LC2540'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">fi</span></div><div class='line' id='LC2541'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;case</span> <span class="s2">&quot;$cur&quot;</span> in</div><div class='line' id='LC2542'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">)</span></div><div class='line' id='LC2543'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="s2">&quot;</span></div><div class='line' id='LC2544'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_common_options</span></div><div class='line' id='LC2545'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$__git_log_gitk_options</span></div><div class='line' id='LC2546'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$merge</span></div><div class='line' id='LC2547'><span class="s2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&quot;</span></div><div class='line' id='LC2548'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2549'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2550'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2551'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>__git_complete_revlist</div><div class='line' id='LC2552'><span class="o">}</span></div><div class='line' id='LC2553'><br/></div><div class='line' id='LC2554'><span class="k">if</span> <span class="o">[[</span> -n <span class="k">${</span><span class="nv">ZSH_VERSION</span><span class="p">-</span><span class="k">}</span> <span class="o">]]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2555'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nb">echo</span> <span class="s2">&quot;WARNING: this script is deprecated, please see git-completion.zsh&quot;</span> 1&gt;<span class="p">&amp;</span>2</div><div class='line' id='LC2556'><br/></div><div class='line' id='LC2557'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;autoload -U +X compinit <span class="o">&amp;&amp;</span> compinit</div><div class='line' id='LC2558'><br/></div><div class='line' id='LC2559'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp <span class="o">()</span></div><div class='line' id='LC2560'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">{</span></div><div class='line' id='LC2561'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emulate -L zsh</div><div class='line' id='LC2562'><br/></div><div class='line' id='LC2563'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">cur_</span><span class="o">=</span><span class="s2">&quot;${3-$cur}&quot;</span></div><div class='line' id='LC2564'><br/></div><div class='line' id='LC2565'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="s2">&quot;$cur_&quot;</span> in</div><div class='line' id='LC2566'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">=)</span></div><div class='line' id='LC2567'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2568'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span></div><div class='line' id='LC2569'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>c <span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39; \t\n&#39;</span></div><div class='line' id='LC2570'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local</span> -a array</div><div class='line' id='LC2571'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">for </span>c in <span class="k">${</span><span class="p">=1</span><span class="k">}</span><span class="p">;</span> <span class="k">do</span></div><div class='line' id='LC2572'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="nv">c</span><span class="o">=</span><span class="s2">&quot;$c${4-}&quot;</span></div><div class='line' id='LC2573'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">case</span> <span class="nv">$c</span> in</div><div class='line' id='LC2574'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--*<span class="o">=</span>*<span class="p">|</span>*.<span class="o">)</span> <span class="p">;;</span></div><div class='line' id='LC2575'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*<span class="o">)</span> <span class="nv">c</span><span class="o">=</span><span class="s2">&quot;$c &quot;</span> <span class="p">;;</span></div><div class='line' id='LC2576'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2577'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>array<span class="o">[</span><span class="k">${#</span><span class="nv">array</span><span class="p">[@]</span><span class="k">}</span>+1<span class="o">]=</span><span class="s2">&quot;$c&quot;</span></div><div class='line' id='LC2578'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">done</span></div><div class='line' id='LC2579'><span class="k">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>compset -P <span class="s1">&#39;*[=:]&#39;</span></div><div class='line' id='LC2580'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compadd -Q -S <span class="s1">&#39;&#39;</span> -p <span class="s2">&quot;${2-}&quot;</span> -a -- array <span class="o">&amp;&amp;</span> <span class="nv">_ret</span><span class="o">=</span>0</div><div class='line' id='LC2581'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">;;</span></div><div class='line' id='LC2582'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">esac</span></div><div class='line' id='LC2583'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">}</span></div><div class='line' id='LC2584'><br/></div><div class='line' id='LC2585'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_nl <span class="o">()</span></div><div class='line' id='LC2586'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">{</span></div><div class='line' id='LC2587'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emulate -L zsh</div><div class='line' id='LC2588'><br/></div><div class='line' id='LC2589'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC2590'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compset -P <span class="s1">&#39;*[=:]&#39;</span></div><div class='line' id='LC2591'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compadd -Q -S <span class="s2">&quot;${4- }&quot;</span> -p <span class="s2">&quot;${2-}&quot;</span> -- <span class="k">${</span><span class="p">=1</span><span class="k">}</span> <span class="o">&amp;&amp;</span> <span class="nv">_ret</span><span class="o">=</span>0</div><div class='line' id='LC2592'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">}</span></div><div class='line' id='LC2593'><br/></div><div class='line' id='LC2594'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__gitcomp_file <span class="o">()</span></div><div class='line' id='LC2595'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">{</span></div><div class='line' id='LC2596'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emulate -L zsh</div><div class='line' id='LC2597'><br/></div><div class='line' id='LC2598'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">IFS</span><span class="o">=</span><span class="s1">$&#39;\n&#39;</span></div><div class='line' id='LC2599'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compset -P <span class="s1">&#39;*[=:]&#39;</span></div><div class='line' id='LC2600'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compadd -Q -p <span class="s2">&quot;${2-}&quot;</span> -f -- <span class="k">${</span><span class="p">=1</span><span class="k">}</span> <span class="o">&amp;&amp;</span> <span class="nv">_ret</span><span class="o">=</span>0</div><div class='line' id='LC2601'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">}</span></div><div class='line' id='LC2602'><br/></div><div class='line' id='LC2603'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_git <span class="o">()</span></div><div class='line' id='LC2604'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">{</span></div><div class='line' id='LC2605'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">_ret</span><span class="o">=</span>1 cur cword prev</div><div class='line' id='LC2606'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">cur</span><span class="o">=</span><span class="k">${</span><span class="nv">words</span><span class="p">[CURRENT]</span><span class="k">}</span></div><div class='line' id='LC2607'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">prev</span><span class="o">=</span><span class="k">${</span><span class="nv">words</span><span class="p">[CURRENT-1]</span><span class="k">}</span></div><div class='line' id='LC2608'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">let </span><span class="nv">cword</span><span class="o">=</span>CURRENT-1</div><div class='line' id='LC2609'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emulate ksh -c __<span class="k">${</span><span class="nv">service</span><span class="k">}</span>_main</div><div class='line' id='LC2610'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">let </span>_ret <span class="o">&amp;&amp;</span> _default <span class="o">&amp;&amp;</span> <span class="nv">_ret</span><span class="o">=</span>0</div><div class='line' id='LC2611'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return </span>_ret</div><div class='line' id='LC2612'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">}</span></div><div class='line' id='LC2613'><br/></div><div class='line' id='LC2614'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;compdef _git git gitk</div><div class='line' id='LC2615'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">return</span></div><div class='line' id='LC2616'><span class="k">fi</span></div><div class='line' id='LC2617'><br/></div><div class='line' id='LC2618'>__git_func_wrap <span class="o">()</span></div><div class='line' id='LC2619'><span class="o">{</span></div><div class='line' id='LC2620'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span>cur words cword prev</div><div class='line' id='LC2621'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_get_comp_words_by_ref -n <span class="o">=</span>: cur words cword prev</div><div class='line' id='LC2622'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nv">$1</span></div><div class='line' id='LC2623'><span class="o">}</span></div><div class='line' id='LC2624'><br/></div><div class='line' id='LC2625'><span class="c"># Setup completion for certain functions defined above by setting common</span></div><div class='line' id='LC2626'><span class="c"># variables and workarounds.</span></div><div class='line' id='LC2627'><span class="c"># This is NOT a public function; use at your own risk.</span></div><div class='line' id='LC2628'>__git_complete <span class="o">()</span></div><div class='line' id='LC2629'><span class="o">{</span></div><div class='line' id='LC2630'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">local </span><span class="nv">wrapper</span><span class="o">=</span><span class="s2">&quot;__git_wrap${2}&quot;</span></div><div class='line' id='LC2631'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">eval</span> <span class="s2">&quot;$wrapper () { __git_func_wrap $2 ; }&quot;</span></div><div class='line' id='LC2632'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">complete</span> -o bashdefault -o default -o nospace -F <span class="nv">$wrapper</span> <span class="nv">$1</span> 2&gt;/dev/null <span class="se">\</span></div><div class='line' id='LC2633'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="o">||</span> <span class="nb">complete</span> -o default -o nospace -F <span class="nv">$wrapper</span> <span class="nv">$1</span></div><div class='line' id='LC2634'><span class="o">}</span></div><div class='line' id='LC2635'><br/></div><div class='line' id='LC2636'><span class="c"># wrapper for backwards compatibility</span></div><div class='line' id='LC2637'>_git <span class="o">()</span></div><div class='line' id='LC2638'><span class="o">{</span></div><div class='line' id='LC2639'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_wrap__git_main</div><div class='line' id='LC2640'><span class="o">}</span></div><div class='line' id='LC2641'><br/></div><div class='line' id='LC2642'><span class="c"># wrapper for backwards compatibility</span></div><div class='line' id='LC2643'>_gitk <span class="o">()</span></div><div class='line' id='LC2644'><span class="o">{</span></div><div class='line' id='LC2645'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__git_wrap__gitk_main</div><div class='line' id='LC2646'><span class="o">}</span></div><div class='line' id='LC2647'><br/></div><div class='line' id='LC2648'>__git_complete git __git_main</div><div class='line' id='LC2649'>__git_complete gitk __gitk_main</div><div class='line' id='LC2650'><br/></div><div class='line' id='LC2651'><span class="c"># The following are necessary only for Cygwin, and only are needed</span></div><div class='line' id='LC2652'><span class="c"># when the user has tab-completed the executable name and consequently</span></div><div class='line' id='LC2653'><span class="c"># included the &#39;.exe&#39; suffix.</span></div><div class='line' id='LC2654'><span class="c">#</span></div><div class='line' id='LC2655'><span class="k">if</span> <span class="o">[</span> <span class="nv">Cygwin</span> <span class="o">=</span> <span class="s2">&quot;$(uname -o 2&gt;/dev/null)&quot;</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span></div><div class='line' id='LC2656'>__git_complete git.exe __git_main</div><div class='line' id='LC2657'><span class="k">fi</span></div></pre></div>
            </td>
          </tr>
        </table>
  </div>

  </div>
</div>

<a href="#jump-to-line" rel="facebox[.linejump]" data-hotkey="l" class="js-jump-to-line" style="display:none">Jump to Line</a>
<div id="jump-to-line" style="display:none">
  <form accept-charset="UTF-8" class="js-jump-to-line-form">
    <input class="linejump-input js-jump-to-line-field" type="text" placeholder="Jump to line&hellip;" autofocus>
    <button type="submit" class="button">Go</button>
  </form>
</div>

        </div>

      </div><!-- /.repo-container -->
      <div class="modal-backdrop"></div>
    </div><!-- /.container -->
  </div><!-- /.site -->


    </div><!-- /.wrapper -->

      <div class="container">
  <div class="site-footer">
    <ul class="site-footer-links right">
      <li><a href="https://status.github.com/">Status</a></li>
      <li><a href="http://developer.github.com">API</a></li>
      <li><a href="http://training.github.com">Training</a></li>
      <li><a href="http://shop.github.com">Shop</a></li>
      <li><a href="/blog">Blog</a></li>
      <li><a href="/about">About</a></li>

    </ul>

    <a href="/">
      <span class="mega-octicon octicon-mark-github"></span>
    </a>

    <ul class="site-footer-links">
      <li>&copy; 2013 <span title="0.03446s from github-fe133-cp1-prd.iad.github.net">GitHub</span>, Inc.</li>
        <li><a href="/site/terms">Terms</a></li>
        <li><a href="/site/privacy">Privacy</a></li>
        <li><a href="/security">Security</a></li>
        <li><a href="/contact">Contact</a></li>
    </ul>
  </div><!-- /.site-footer -->
</div><!-- /.container -->


    <div class="fullscreen-overlay js-fullscreen-overlay" id="fullscreen_overlay">
  <div class="fullscreen-container js-fullscreen-container">
    <div class="textarea-wrap">
      <textarea name="fullscreen-contents" id="fullscreen-contents" class="js-fullscreen-contents" placeholder="" data-suggester="fullscreen_suggester"></textarea>
          <div class="suggester-container">
              <div class="suggester fullscreen-suggester js-navigation-container" id="fullscreen_suggester"
                 data-url="/git/git/suggestions/commit">
              </div>
          </div>
    </div>
  </div>
  <div class="fullscreen-sidebar">
    <a href="#" class="exit-fullscreen js-exit-fullscreen tooltipped leftwards" title="Exit Zen Mode">
      <span class="mega-octicon octicon-screen-normal"></span>
    </a>
    <a href="#" class="theme-switcher js-theme-switcher tooltipped leftwards"
      title="Switch themes">
      <span class="octicon octicon-color-mode"></span>
    </a>
  </div>
</div>



    <div id="ajax-error-message" class="flash flash-error">
      <span class="octicon octicon-alert"></span>
      <a href="#" class="octicon octicon-remove-close close ajax-error-dismiss"></a>
      Something went wrong with that request. Please try again.
    </div>

  </body>
</html>

>>>>>>> 8fdd211f77e1e655fbf8ad8e2de943318ebbaa56
