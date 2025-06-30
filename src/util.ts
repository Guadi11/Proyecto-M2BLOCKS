export function numberToColor(num: number) {
    switch (num) {
        case 2: return "#0083bb";
        case 4: return "#fc7f40";
        case 8: return "#e6538a";
        case 16: return "#058555";
        case 32: return "#b82bfa";
        case 64: return "#a24e78";
        case 128: return "#b9c508";
        case 256: return "#aed581";
        case 512: return "#9575cd";
        case 1024: return "#fo6292";
        case 2048: return "#4db6ac";
        default: return "black";
    }
}

export function delay(milliseconds: number) {
    return new Promise(resolve => setTimeout(resolve, milliseconds));
}