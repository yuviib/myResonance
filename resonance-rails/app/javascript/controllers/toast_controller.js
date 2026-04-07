import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String,
    type: { type: String, default: "notice" },
    duration: { type: Number, default: 4000 }
  }

  connect() {
    this.show()
  }

  show() {
    this.element.innerHTML = this.template()
    this.element.classList.remove("hidden")
    this.element.classList.add("pointer-events-auto", "animate-in")
    
    if (window.lucide) window.lucide.createIcons()

    this.timeout = setTimeout(() => this.hide(), this.durationValue)
  }

  hide() {
    this.element.classList.replace("animate-in", "animate-out")
    this.element.classList.add("fade-out", "slide-out-to-right-10")
    this.element.addEventListener("animationend", () => this.element.remove())
  }

  template() {
    const isError = this.typeValue === "alert" || this.typeValue === "error"
    const bgColor = isError ? "bg-red-500/10 border-red-500/20" : "bg-white/[0.05] border-white/10"
    const iconColor = isError ? "text-red-500" : "text-brand-primary"
    const icon = isError ? "circle-x" : "check-circle"

    return `
      <div class="flex items-center gap-4 px-6 py-4 rounded-3xl ${bgColor} border backdrop-blur-2xl shadow-2xl min-w-[320px]">
        <div class="w-10 h-10 rounded-2xl bg-white/5 flex items-center justify-center flex-shrink-0">
          <i data-lucide="${icon}" class="w-5 h-5 ${iconColor}"></i>
        </div>
        <div class="flex-1">
          <p class="text-[13px] font-bold text-white tracking-tight">${this.messageValue}</p>
        </div>
      </div>
    `
  }
}
