// Shared helpers for the Claude Code hooks in this directory.
//
// Two rules every hook here follows:
//   1. Read the payload from stdin. Claude Code does NOT pass tool arguments as
//      environment variables; a hook reading process.env.TOOL_INPUT_* silently
//      never fires, which is worse than having no hook at all.
//   2. Never crash. A guard that throws turns every tool call into an error.
//      On any internal failure, fail open and let the action through.

export async function readStdin() {
  let raw = '';
  try {
    for await (const chunk of process.stdin) raw += chunk;
    return JSON.parse(raw || '{}');
  } catch {
    return {};
  }
}

/** PreToolUse: refuse the call and tell the model why. */
export function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: reason,
      },
    }),
  );
  process.exit(0);
}

/** Let the call proceed under the normal permission rules. */
export function allow() {
  process.stdout.write('{}');
  process.exit(0);
}

/**
 * PostToolUse: the action already happened, so this is feedback rather than a
 * block. Exit 2 puts the message in front of the model so it corrects course.
 */
export function flag(message) {
  process.stderr.write(message);
  process.exit(2);
}

/** PostToolUse with nothing to say. */
export function ok() {
  process.exit(0);
}

/** The file a Write/Edit/MultiEdit tool call targeted, or '' if not applicable. */
export function targetFile(input) {
  return input?.tool_input?.file_path ?? '';
}
