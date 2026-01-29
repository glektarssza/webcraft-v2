/// <reference types="deno" />

/**
 * A simple terminal wrapper.
 */
export class Terminal {
    /**
     * Whether this terminal is initialized.
     */
    #initialized: boolean;

    /**
     * The abort controller for this instance.
     */
    readonly #abortController: AbortController;

    /**
     * The common text encoder.
     */
    readonly #textEncoder: TextEncoder;

    /**
     * The input stream for the instance.
     */
    #inputStream: ReadableStream<Uint8Array<ArrayBuffer>> | null;

    /**
     * The input stream text decoder for the instance.
     */
    #inputTextStreamDecoder: TextDecoderStream | null;

    /**
     * The error stream for the instance.
     */
    #inputStreamReader: ReadableStreamDefaultReader<
        Uint8Array<ArrayBuffer>
    > | null;

    /**
     * The input stream reader for the instance.
     */
    #inputTextStreamReader: ReadableStreamDefaultReader<string> | null;

    /**
     * The output stream for the instance.
     */
    #outputStream: WritableStream<Uint8Array<ArrayBuffer>> | null;

    /**
     * The output stream text encoder for the instance.
     */
    #outputTextStreamEncoder: TextEncoderStream | null;

    /**
     * The error stream for the instance.
     */
    #outputStreamWriter: WritableStreamDefaultWriter<
        Uint8Array<ArrayBuffer>
    > | null;

    /**
     * The writer for the output stream text encoder for this instance.
     */
    #outputTextStreamWriter: WritableStreamDefaultWriter<string> | null;

    /**
     * The error stream for the instance.
     */
    #errorStream: WritableStream<Uint8Array<ArrayBuffer>> | null;

    /**
     * The error stream text decoder for the instance.
     */
    #errorTextStreamEncoder: TextEncoderStream | null;

    /**
     * The error stream for the instance.
     */
    #errorStreamWriter: WritableStreamDefaultWriter<
        Uint8Array<ArrayBuffer>
    > | null;

    /**
     * The writer for the output stream text encoder for this instance.
     */
    #errorTextStreamWriter: WritableStreamDefaultWriter<string> | null;

    /**
     * Whether this instance is initialized.
     */
    public get isInitialized(): boolean {
        return this.#initialized;
    }

    /**
     * Create a new instance.
     *
     * @param inputStream The input stream for the new instance.
     * @param outputStream The output stream for the new instance.
     * @param errorStream The error stream for the new instance.
     */
    public constructor() {
        this.#initialized = false;
        this.#abortController = new AbortController();
        this.#textEncoder = new TextEncoder();
        this.#inputStream = null;
        this.#outputStream = null;
        this.#errorStream = null;
        this.#inputStreamReader = null;
        this.#outputStreamWriter = null;
        this.#errorStreamWriter = null;
        this.#inputTextStreamDecoder = null;
        this.#outputTextStreamEncoder = null;
        this.#errorTextStreamEncoder = null;
        this.#inputTextStreamReader = null;
        this.#outputTextStreamWriter = null;
        this.#errorTextStreamWriter = null;
    }

    async initialize(
        inputStream: ReadableStream<Uint8Array<ArrayBuffer>>,
        outputStream: WritableStream<Uint8Array<ArrayBuffer>>,
        errorStream: WritableStream<Uint8Array<ArrayBuffer>>
    ): Promise<void> {
        if (this.isInitialized) {
            return;
        }
        this.#inputStream = inputStream;
        this.#inputStreamReader = this.#inputStream.getReader();
        this.#outputStream = outputStream;
        this.#outputStreamWriter = this.#outputStream.getWriter();
        this.#errorStream = errorStream;
        this.#errorStreamWriter = this.#errorStream.getWriter();
        this.#inputTextStreamDecoder = new TextDecoderStream();
        await this.#inputStream.pipeTo(this.#inputTextStreamDecoder.writable, {
            signal: this.#abortController.signal,
            // Do not allow the source (stdin) to be cancelled if the destination errors
            preventCancel: true
        });
        this.#outputTextStreamEncoder = new TextEncoderStream();
        await this.#outputTextStreamEncoder.readable.pipeTo(
            this.#outputStream,
            {
                signal: this.#abortController.signal,
                // Do not allow the destination (stdout) to be aborted if the source errors
                preventAbort: true,
                // Do not allow the destination (stdout) to be closed if the source is closed
                preventClose: true
            }
        );
        this.#errorTextStreamEncoder = new TextEncoderStream();
        await this.#errorTextStreamEncoder.readable.pipeTo(this.#errorStream, {
            signal: this.#abortController.signal,
            // Do not allow the destination (stdout) to be aborted if the source errors
            preventAbort: true,
            // Do not allow the destination (stdout) to be closed if the source is closed
            preventClose: true
        });
        this.#inputTextStreamReader =
            this.#inputTextStreamDecoder.readable.getReader();
        this.#outputTextStreamWriter =
            this.#outputTextStreamEncoder.writable.getWriter();
        this.#errorTextStreamWriter =
            this.#errorTextStreamEncoder.writable.getWriter();
        this.#initialized = true;
    }

    /**
     * Destroy this instance.
     */
    public async destroy(): Promise<void> {
        this.#initialized = false;
        //-- Send abort signals to all pipes
        this.#abortController.abort();
        //-- Release locks on our text-side readers/writers
        this.#inputTextStreamReader?.releaseLock();
        this.#outputTextStreamWriter?.releaseLock();
        this.#errorTextStreamWriter?.releaseLock();
        //-- Close our decoders/encoders
        await this.#inputTextStreamDecoder?.writable.close();
        await this.#outputTextStreamWriter?.close();
        await this.#errorTextStreamWriter?.close();
        //-- Release locks on our binary-side readers/writers
        this.#inputStreamReader?.releaseLock();
        this.#outputStreamWriter?.releaseLock();
        this.#errorStreamWriter?.releaseLock();
        //-- Do not close standard streams
        //-- Null out our internal variables
        this.#inputTextStreamReader = null;
        this.#outputTextStreamWriter = null;
        this.#errorTextStreamWriter = null;
        this.#inputTextStreamDecoder = null;
        this.#outputTextStreamEncoder = null;
        this.#errorTextStreamEncoder = null;
        this.#inputStreamReader = null;
        this.#outputStreamWriter = null;
        this.#errorStreamWriter = null;
    }

    /**
     * Write data asynchronously to the output stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public async writeOutput(
        data?: string | Uint8Array<ArrayBuffer>
    ): Promise<void> {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        await (typeof data === 'string' ?
            this.#outputTextStreamWriter?.write(data)
        :   this.#outputStreamWriter?.write(data));
    }

    /**
     * Write a line of data asynchronously to the output stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public async writeOutputLine(...data: string[]): Promise<void> {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        await this.writeOutput(`${data.join(' ')}\n`);
    }

    /**
     * Write data synchronously to the output stream.
     *
     * @param data The data to write.
     */
    public writeOutputSync(data?: string | Uint8Array<ArrayBuffer>): void {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        void this.#outputStreamWriter?.write(
            typeof data === 'string' ? this.#textEncoder.encode(data) : data
        );
    }

    /**
     * Write a line of data asynchronously to the output stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public writeOutputLineSync(...data: string[]): void {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        this.writeOutputSync(`${data.join(' ')}\n`);
    }

    /**
     * Write data asynchronously to the error stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public async writeError(
        data?: string | Uint8Array<ArrayBuffer>
    ): Promise<void> {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        await (typeof data === 'string' ?
            this.#errorTextStreamWriter?.write(data)
        :   this.#errorStreamWriter?.write(data));
    }

    /**
     * Write a line of data asynchronously to the error stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public async writeErrorLine(...data: string[]): Promise<void> {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        await this.writeError(`${data.join(' ')}\n`);
    }

    /**
     * Write data synchronously to the error stream.
     *
     * @param data The data to write.
     */
    public writeErrorSync(data?: string | Uint8Array<ArrayBuffer>): void {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        void this.#errorStreamWriter?.write(
            typeof data === 'string' ? this.#textEncoder.encode(data) : data
        );
    }

    /**
     * Write a line of data synchronously to the error stream.
     *
     * @param data The data to write.
     *
     * @returns A promise that resolves when the data is written or rejects if an
     * error occurs.
     */
    public writeErrorLineSync(...data: string[]): void {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        this.writeErrorSync(`${data.join(' ')}\n`);
    }

    public async readInput(): Promise<
        ReadableStreamReadResult<Uint8Array<ArrayBuffer>>
    > {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        return this.#inputStreamReader!.read();
    }

    public async readInputText(): Promise<ReadableStreamReadResult<string>> {
        if (!this.isInitialized) {
            throw new Error('Terminal instance is not initialized!');
        }
        return this.#inputTextStreamReader!.read();
    }
}
