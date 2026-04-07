import "@hotwired/turbo-rails"
import "controllers"

// Stable Lucide Hydration System
const initializeIcons = () => {
    if (window.lucide) {
        window.lucide.createIcons();
    }
};

// Listen to key Turbo lifecycle events
document.addEventListener("turbo:load", initializeIcons);
document.addEventListener("turbo:render", initializeIcons);
document.addEventListener("turbo:frame-load", initializeIcons);

// Manual trigger for edge cases
window.refreshIcons = initializeIcons;

// Log success to console to verify the loop is gone
console.log("Resonance UI: Icon engine stabilized.");
