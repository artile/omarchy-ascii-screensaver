declare const Base: typeof HTMLElement;
export declare class AsciiArt extends Base {
    #private;
    static observedAttributes: string[];
    connectedCallback(): void;
    disconnectedCallback(): void;
    attributeChangedCallback(): void;
}
/** Defines the tag, once. Importing this module calls it for "ascii-art". */
export declare function define(tag?: string): void;
declare global {
    interface HTMLElementTagNameMap {
        "ascii-art": AsciiArt;
    }
}
export {};
