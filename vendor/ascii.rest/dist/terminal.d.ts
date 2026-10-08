import { type PieceName } from "./library.ts";
import type { Options, Piece } from "./types.ts";
/** Where a piece is drawn: process.stdout, or a stream shaped like it. */
export interface Output {
    write(text: string): unknown;
    isTTY?: boolean;
    columns?: number;
    rows?: number;
    on?(event: "resize", listener: () => void): unknown;
    off?(event: "resize", listener: () => void): unknown;
}
export interface PlayOptions {
    /** Seconds to play. Until a key is pressed, by default. */
    seconds?: number;
    /** Draws a coloured piece as text in the terminal's own colour. */
    mono?: boolean;
    /** For a light terminal: a coloured piece takes its light colours, a shaded one flips its ramp. */
    light?: boolean;
    /** Frames a second, instead of the piece's own. */
    fps?: number;
    /** The piece's option overrides. Kept apart from the rest because two clocks have a `seconds` option of their own. */
    options?: Options;
    /** Where to draw: process.stdout by default. Keys are read from process.stdin. */
    out?: Output;
}
export interface Played {
    /** True when the terminal was smaller than the piece as it stopped, so only the piece's middle showed. */
    cropped: boolean;
    /** True when Ctrl+C stopped it. */
    interrupted: boolean;
    /** The piece's size in the terminal's cells. */
    piece: {
        cols: number;
        rows: number;
    };
    /** The terminal's size as it stopped. */
    terminal: {
        cols: number;
        rows: number;
    };
}
/** A piece's first frame as plain text, its rows paired as on a terminal: for a pipe or a log, where nothing plays. */
export declare function still(piece: Piece | PieceName, { light, options }?: Pick<PlayOptions, "light" | "options">): Promise<string>;
/** Plays a piece in the terminal. Resolves when it stops: after `seconds`, on a key or on Ctrl+C. */
export declare function play(piece: Piece | PieceName, { seconds, mono, light, fps, options, out }?: PlayOptions): Promise<Played>;
