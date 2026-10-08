import { type CSSProperties } from "react";
import { type PieceName } from "./library.ts";
import { type MountOptions } from "./mount.ts";
import type { Piece } from "./types.ts";
export interface AsciiProps {
    /** A piece module, from "ascii.rest/pieces", or a piece's file name to load on demand. */
    piece: Piece | PieceName;
    /** The piece's option overrides, and `fps` to override its frame rate. */
    options?: MountOptions;
    /** What the picture shows, for screen readers. The piece's name otherwise. */
    label?: string;
    /** Draws a coloured piece as text in one ink, in a <pre> like any other. */
    mono?: boolean;
    className?: string;
    style?: CSSProperties;
}
export declare function Ascii({ piece, options, label, mono, className, style }: AsciiProps): import("react").JSX.Element;
export type { MountOptions, Piece, PieceName };
