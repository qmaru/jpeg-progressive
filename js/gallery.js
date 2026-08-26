function formatFileSize(bytes) {
    return `${(bytes / 1000).toFixed(2)} kB`;
}

async function getFileSize(url) {
    if (location.protocol === "file:") {
        return undefined;
    }

    try {
        const headResponse = await fetch(url, { method: "HEAD", cache: "no-store" });
        const contentLength = headResponse.headers.get("content-length");

        if (headResponse.ok && contentLength) {
            return Number(contentLength);
        }

        const response = await fetch(url, { cache: "no-store" });
        return response.ok ? (await response.blob()).size : undefined;
    } catch {
        return undefined;
    }
}

document.querySelectorAll(".card").forEach(async (card) => {
    const image = card.querySelector("img");
    const info = card.querySelector(".info");
    const sizeLabel = document.createElement("span");

    sizeLabel.className = "file-size";
    sizeLabel.textContent = "Reading file size...";
    info.append(sizeLabel);

    const size = await getFileSize(image.src);
    sizeLabel.textContent = size === undefined ? "Size unavailable" : formatFileSize(size);
});

const hdrToggle = document.querySelector("#hdr-toggle");
const hdrSection = document.querySelector("#hdr-showcase");
const hdrToggleState = document.querySelector("#hdr-toggle-state");

if (hdrToggle && hdrSection && hdrToggleState) {
    const updateHdrMode = () => {
        const enabled = hdrToggle.checked;
        hdrSection.style.setProperty("dynamic-range-limit", enabled ? "no-limit" : "standard");
        hdrToggleState.textContent = enabled ? "ON" : "OFF";
    };

    hdrToggle.addEventListener("change", updateHdrMode);
    updateHdrMode();
}
