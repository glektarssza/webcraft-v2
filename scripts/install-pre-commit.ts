/// <reference types="deno" />
import {Command} from 'commander';
let verboseMode = false;
const textEncoder = new TextEncoder();
async function writeStdout(data: string): Promise<void> {
    const buffer = textEncoder.encode(data);
    await Deno.stdout.write(buffer);
}
async function writeStderr(data: string): Promise<void> {
    const buffer = textEncoder.encode(data);
    await Deno.stderr.write(buffer);
}
async function writeStdoutLine(data: string): Promise<void> {
    await writeStdout(`${data}\n`);
}
async function writeStderrLine(data: string): Promise<void> {
    await writeStderr(`${data}\n`);
}
async function logError(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStderrLine(`[ERROR] ${data.join(' ')}`);
    } else {
        await writeStderrLine(`\x1b[38:5:196m[ERROR]\x1b[0m ${data.join(' ')}`);
    }
}
async function logWarning(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStdoutLine(`[WARN] ${data.join(' ')}`);
    } else {
        await writeStdoutLine(`\x1b[38:5:208m[WARN]\x1b[0m ${data.join(' ')}`);
    }
}
async function logInfo(...data: unknown[]): Promise<void> {
    if (Deno.noColor) {
        await writeStdoutLine(`[INFO] ${data.join(' ')}`);
    } else {
        await writeStdoutLine(`\x1b[38:5:111m[INFO]\x1b[0m ${data.join(' ')}`);
    }
}
async function logVerbose(...data: unknown[]): Promise<void> {
    if (!verboseMode) {
        return;
    }
    if (Deno.noColor) {
        await writeStdoutLine(`[VERBOSE] ${data.join(' ')}`);
    } else {
        await writeStdoutLine(
            `\x1b[38:5:141m[VERBOSE]\x1b[0m ${data.join(' ')}`
        );
    }
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
await logError('Hello, world!');
await logWarning('Hello, world!');
await logInfo('Hello, world!');
await logVerbose('Hello, world!');
