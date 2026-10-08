import type { Options, Piece } from "./types.ts";
/**
 * The piece's option overrides, `fps` to override its frame rate, and `motion`
 * to play even when the reader prefers reduced motion: only for a page that
 * offers its own control, such as a play button the reader presses.
 */
export type MountOptions = Options & {
    fps?: number;
    motion?: boolean;
};
export declare function mount(el: HTMLElement, piece: Piece | Piece["default"], options?: MountOptions): () => void;
