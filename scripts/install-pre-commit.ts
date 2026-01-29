/// <reference types="deno" />
import {Command} from 'commander';
let verboseMode = false;
const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();
const abortController = new AbortController();
async function writeStream(
    data: string,
    writeable: WritableStream<Uint8Array<ArrayBufferLike>>
): Promise<void> {
    const writer = writeable.getWriter();
    const buffer = textEncoder.encode(data);
    await writer.write(buffer);
    writer.releaseLock();
}
async function writeStdout(data: string): Promise<void> {
    await writeStream(data, Deno.stdout.writable);
}
async function writeStderr(data: string): Promise<void> {
    await writeStream(data, Deno.stderr.writable);
}
async function writeStdoutLine(data?: string): Promise<void> {
    await writeStdout(`${data ?? ''}\n`);
}
async function writeStderrLine(data?: string): Promise<void> {
    await writeStderr(`${data ?? ''}\n`);
}
async function writeSGR(
    data: string,
    writeable: WritableStream<Uint8Array<ArrayBufferLike>> = Deno.stdout
        .writable
): Promise<void> {
    await writeStream(`\x1b[${data}m`, writeable);
}
async function resetSGR(
    writeable: WritableStream<Uint8Array<ArrayBufferLike>> = Deno.stdout
        .writable
): Promise<void> {
    await writeSGR('0', writeable);
}
async function writeSGR8BitFG(
    code: number,
    writeable: WritableStream<Uint8Array<ArrayBufferLike>> = Deno.stdout
        .writable
): Promise<void> {
    if (code < 0 || code > 255) {
        throw new Error(`Invalid 8-bit SGR foreground color code "${code}"`);
    }
    await writeSGR(`38:5:${code}`, writeable);
}
async function logError(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStderrLine(`[ERROR] ${data.join(' ')}`);
    } else {
        await writeSGR8BitFG(196, Deno.stderr.writable);
        await writeStderr('[ERROR]');
        await resetSGR(Deno.stderr.writable);
        await writeStderrLine(` ${data.join(' ')}`);
    }
}
// @ts-expect-error Logging functions are allowed
// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function logWarning(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStdoutLine(`[WARN] ${data.join(' ')}`);
    } else {
        await writeSGR8BitFG(208);
        await writeStderr('[WARN]');
        await resetSGR();
        await writeStderrLine(` ${data.join(' ')}`);
    }
}
async function logInfo(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStdoutLine(`[INFO] ${data.join(' ')}`);
    } else {
        await writeSGR8BitFG(111);
        await writeStderr('[INFO]');
        await resetSGR();
        await writeStdoutLine(` ${data.join(' ')}`);
    }
}
async function logVerbose(...data: unknown[]): Promise<void> {
    if (!verboseMode) {
        return;
    }
    if (Deno.noColor) {
        await writeStdoutLine(`[VERBOSE] ${data.join(' ')}`);
    } else {
        await writeSGR8BitFG(141);
        await writeStderr('[VERBOSE]');
        await resetSGR();
        await writeStdoutLine(` ${data.join(' ')}`);
    }
}
async function findProgram(name: string): Promise<string | null> {
    let cmd: Deno.Command | undefined = undefined;
    if (Deno.build.os === 'linux') {
        cmd = new Deno.Command('sh', {
            args: ['-c', `command -v ${name}`],
            signal: abortController.signal,
            stdin: 'null',
            stdout: 'piped',
            stderr: 'null'
        });
    } else if (Deno.build.os === 'windows') {
        cmd = new Deno.Command('which.exe', {
            args: [name],
            signal: abortController.signal,
            stdin: 'null',
            stdout: 'piped',
            stderr: 'null'
        });
    }
    if (!cmd) {
        throw new Error('Unsupported operating system!');
    }
    const result = await cmd.output();
    if (!result.success) {
        return null;
    }
    const installPath = textDecoder.decode(result.stdout).trim();
    await logVerbose(`Found pre-commit installed at "${installPath}"`);
    return installPath;
}
interface CommandOptions {
    verbose: boolean;
}
const program = new Command('install-pre-commit');
program
    .description('Install pre-commit and its dependencies.')
    .storeOptionsAsProperties(false)
    .addHelpText(
        'afterAll',
        "\nCopyright (c) 2026 G'lek Tarssza\nAll rights reserved"
    )
    .allowUnknownOption(false)
    .allowExcessArguments(false)
    .helpOption('-h,--help', 'Show the help information and exit.')
    .version(
        "v0.1.0\n\nCopyright (c) 2026 G'lek Tarssza\nAll rights reserved",
        '--version',
        'Show the version information and exit.'
    )
    .showSuggestionAfterError(true)
    .showHelpAfterError(false)
    .enablePositionalOptions(false);
program
    .optionsGroup('Logging')
    .option('-v,--verbose', 'Enable verbose logging.', false);
const args = program.parse().opts<CommandOptions>();
if (Deno.env.has('VERBOSE')) {
    verboseMode = Deno.env.get('VERBOSE')?.match(/false|0/i) === null;
}
verboseMode = args.verbose;
async function main(): Promise<void> {
    await logInfo('Checking for pre-commit on the system...');
    const preCommitPath = await findProgram('pre-commit');
    if (preCommitPath) {
        await logInfo('pre-commit is already installed on the system!');
        return;
    }
}
await main()
    .then(async (): Promise<void> => {
        await writeSGR8BitFG(118);
        await writeStdout('Success!');
        await resetSGR();
        await writeStdoutLine();
    })
    .catch(async (err: Error): Promise<void> => {
        await writeSGR8BitFG(196);
        await writeStdout('Error!');
        await resetSGR();
        await logError(err.message);
        if (err.stack) {
            await writeStderr(err.stack);
        }
        await writeStdoutLine();
    });
