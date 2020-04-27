import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "position" ];

  connect() {
    this.index = 0;
    // this.nextPosition = this.nextPosition.bind(this);
    this.interval = setInterval(() => this.nextPosition(), 1000);
  }

  disconnect() {
    clearInterval(this.interval);
  }

  nextPosition() {
    this.index += 1;
    this.index = this.index % 3;
    this.positionTargets.forEach((el, i) => {
      el.classList.toggle("hidden", this.index != i)
    })
  }
}
