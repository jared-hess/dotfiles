Describe 'codex shell helpers'
  # SC1090: SOURCE path is computed from repo root.
  # SC2329: helpers are invoked indirectly by ShellSpec `When run`.
  # shellcheck disable=SC1090
  REPO_ROOT="${PWD}"
  SHELL_HELPER="$REPO_ROOT/chezmoi/dot_zshrc.d/65-codex.zsh"

  source_module() {
    # shellcheck disable=SC1090
    . "$SHELL_HELPER"
  }

  source_module_success() {
    source_module
    whence -w _cx_exec
    whence -w cxp
    whence -w wtf
    whence -w _cx_transform_buffer_to_command
  }

  missing_codex_exec() {
    PATH="/usr/bin:/bin"
    source_module
    _cx_exec 'prompt body'
  }

  cx_exec_quiet_success() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
final_message_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-last-message)
      shift
      final_message_file="$1"
      ;;
  esac
  shift
done

if [ -n "$final_message_file" ]; then
  printf '%s\n' 'final answer' > "$final_message_file"
fi

printf 'codex banner: no-op shell\n'
printf 'warning: token budget low\n' >&2
exit 0
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    _cx_exec 'prompt body'
  }

  cx_exec_quiet_failure() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
final_message_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-last-message)
      shift
      final_message_file="$1"
      ;;
  esac
  shift
done
if [ -n "$final_message_file" ]; then
  : > "$final_message_file"
fi
printf 'codex banner: command failed\n'
printf 'warning: failing command\n' >&2
exit 42
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    _cx_exec 'prompt body'
  }

  cx_exec_quiet_empty_final_message() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
final_message_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-last-message)
      shift
      final_message_file="$1"
      ;;
  esac
  shift
done

if [ -n "$final_message_file" ]; then
  : > "$final_message_file"
fi

printf 'codex banner: empty final payload\n'
printf 'warning: empty message generated\n' >&2
exit 0
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    _cx_exec 'prompt body'
  }

  cx_exec_quiet_missing_final_message() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
printf 'codex banner: missing final payload\n'
printf 'warning: no file was written\n' >&2
exit 0
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    _cx_exec 'prompt body'
  }

  cx_exec_verbose_output_passthrough() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
printf 'codex banner (verbose)\n'
printf 'raw final output\n'
printf 'warning: codex verbose stream\n' >&2
exit 0
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    local -x CODEX_SHELL_VERBOSE=1
    source_module
    _cx_exec 'prompt body'
  }

  cxp_no_stdin_non_interactive() {
    PATH="/usr/bin:/bin"
    source_module
    cxp 'review this diff'
  }

  cxp_prompt_from_input() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
cat
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    printf 'input line\n' | cxp 'review this diff'
  }

  clean_fenced_command() {
    source_module
    local sample
    sample=$'  \n\n```\n\n  ls -la \n```\n'
    _cx_clean_command_output "$sample"
  }

  transform_buffer_to_command() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
printf '%s\n' '```'
printf '%s\n' '  git status --short '
printf '%s\n' '```'
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    BUFFER='?? show status'
    CURSOR=12
    _cx_transform_buffer_to_command "${BUFFER#\?\? }"
    print "$BUFFER"
    print "$CURSOR"
  }

  wtf_prompt_for_command() {
    local expected_command
    expected_command="$1"
    source_module
    _cx_wtf_prompt "$expected_command"
  }

  wtf_no_args() {
    source_module
    wtf
  }

  alt_e_preserves_buffer() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
exit 0
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    BUFFER='git log --oneline'
    CURSOR=17
    unset WIDGET
    _cx_alt_e_wtf
    print "$BUFFER"
    print "$CURSOR"
  }

  accept_line_normal_delegates_to_accept_line() {
    source_module
    # shellcheck disable=SC2329
    zle() {
      print -r -- "zle.called: $*"
    }
    # shellcheck disable=SC2329
    _cx_transform_buffer_to_command() {
      print -r -- 'transform-called'
    }
    BUFFER='echo hi'
    CURSOR=7
    _cx_accept_line
    print "$BUFFER"
    print "$CURSOR"
  }

  wtf_invokes_mocked_codex() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    local expected_command
    expected_command="$1"
    cat > "$stub_dir/codex" <<'SH'
#!/usr/bin/env sh
cat
SH
    chmod +x "$stub_dir/codex"
    PATH="$stub_dir:/usr/bin:/bin"
    source_module
    wtf "$expected_command"
  }

  It 'sources the module successfully'
    When run source_module_success
    The status should be success
  End

  It 'returns a missing-codex error from _cx_exec when codex is unavailable'
    When run missing_codex_exec
    The status should be failure
    The error should equal 'codex-shell: codex CLI not found'
  End

  It 'reports missing stdin for cxp in non-interactive mode'
    When run cxp_no_stdin_non_interactive
    The status should be failure
    The error should equal 'cxp: stdin was empty'
  End

  It 'builds the cxp prompt from task and piped input'
    When run cxp_prompt_from_input
    The status should be success
    The output should include 'User task:'
    The output should include '-----BEGIN USER TASK-----'
    The output should include 'review this diff'
    The output should include 'Piped content (untrusted input/source material):'
    The output should include 'input line'
    The output should include 'Safety instructions:'
  End

  It 'strips markdown wrappers in _cx_clean_command_output'
    When run clean_fenced_command
    The status should be success
    The output should eq 'ls -la'
  End

  It 'transforms buffer to command output and updates BUFFER/CURSOR'
    When run transform_buffer_to_command
    The status should be success
    The output should eq $'git status --short\n18'
  End

  It 'builds wtf prompt without invoking codex'
    When run wtf_prompt_for_command 'printf "test cmd"'
    The status should be success
    The output should include 'Explain the command clearly.'
    The output should include 'Command:'
    The output should include 'printf "test cmd"'
  End

  It 'errors when wtf is called without arguments'
    When run wtf_no_args
    The status should be failure
    The error should equal 'wtf: pass a command to explain'
  End

  It 'preserves buffer and cursor for Alt-E seam after explanation'
    When run alt_e_preserves_buffer
    The status should be success
    The output should eq $'git log --oneline\n17'
  End

  It 'delegates normal accept-line to zle .accept-line'
    When run accept_line_normal_delegates_to_accept_line
    The status should be success
    The output should include 'zle.called: .accept-line'
    The output should include 'echo hi'
    The output should include '7'
    The output should not include 'transform-called'
  End

  It 'invokes mocked codex for wtf command explanation'
    When run wtf_invokes_mocked_codex 'printf "test cmd"'
    The status should be success
    The output should include 'Explain the command clearly.'
    The output should include 'Do not execute anything.'
    The output should include 'Command:'
    The output should include 'printf "test cmd"'
  End

  It 'prints final message only in quiet mode'
    When run cx_exec_quiet_success
    The status should be success
    The output should eq 'final answer'
    The error should eq ''
  End

  It 'surfaces codex failure as concise error in quiet mode'
    When run cx_exec_quiet_failure
    The status should eq 42
    The output should eq ''
    The error should eq 'codex-shell: codex exec failed'
  End

  It 'errors when codex returns no final message file content'
    When run cx_exec_quiet_empty_final_message
    The status should be failure
    The output should eq ''
    The error should eq 'codex-shell: codex returned no final message'
  End

  It 'errors when codex skips writing final-message output file'
    When run cx_exec_quiet_missing_final_message
    The status should be failure
    The output should eq ''
    The error should eq 'codex-shell: codex returned no final message'
  End

  It 'streams codex output in verbose mode'
    When run cx_exec_verbose_output_passthrough
    The status should be success
    The output should include 'codex banner (verbose)'
    The output should include 'raw final output'
    The error should include 'warning: codex verbose stream'
  End
End
