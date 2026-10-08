"use client";
import { jsx as _jsx } from "react/jsx-runtime";
/*
 * <Ascii>: a piece in React. A client component, so it works in the Next.js
 * app router as well as anywhere else React runs.
 * Part of ascii.rest by @bas3line (https://github.com/bas3line), MIT licensed.
 *
 *   import { Ascii } from "ascii.rest/react";
 *   import { donut } from "ascii.rest/pieces";
 *
 *   <Ascii piece={donut} />                      // bundled with your page
 *   <Ascii piece="night-coast" />                // or fetched by name when it mounts
 *   <Ascii piece={donut} options={{ fps: 12 }} className="art" />
 *   <Ascii piece="rust" mono />                  // a coloured piece in one ink
 *
 * Text pieces draw into a <pre> in the element's colour and font size; the
 * coloured ones draw onto a <canvas> as wide as its container.
 */
import { useEffect, useRef, useState } from "react";
import { canvas, isPiece, load } from "./library.js";
import { mount } from "./mount.js";
export function Ascii({ piece, options, label, mono = false, className, style }) {
    const ref = useRef(null);
    const [loaded, setLoaded] = useState(null);
    const mod = typeof piece === "string" ? loaded : piece;
    useEffect(() => {
        if (typeof piece !== "string" || !isPiece(piece))
            return;
        let live = true;
        setLoaded(null);
        load[piece]().then((m) => live && setLoaded(m));
        return () => {
            live = false;
        };
    }, [piece]);
    // An inline options object is new every render; only a real change restarts the piece.
    const key = JSON.stringify(options ?? {});
    // mono swaps the canvas for a <pre>, so the piece starts again on the new element.
    useEffect(() => {
        if (!mod || !ref.current)
            return;
        return mount(ref.current, mod, JSON.parse(key));
    }, [mod, key, mono]);
    // Known before loading, so a coloured piece gets its canvas from the first render.
    const onCanvas = !mono && (typeof piece === "string" ? canvas.has(piece) : Boolean(piece.meta.palette));
    const name = typeof piece === "string" ? piece : piece.meta.name;
    const props = { role: "img", "aria-label": label ?? mod?.meta.name ?? name, className, style };
    return onCanvas ? (_jsx("canvas", { ref: ref, ...props })) : (_jsx("pre", { ref: ref, ...props }));
}
