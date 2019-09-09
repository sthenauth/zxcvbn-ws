// Talk with the WebSocket server:
class Zxcvbn {
  constructor(callback, url=document.location) {
    const mkURL = () => {
      let proto = "ws";
      if (url.protocol === "https:") proto = "wss";
      return `${proto}://${url.host}${url.pathname}connect`;
    };

    this.callback = callback;

    this._connect = () => {
      this._socket = new WebSocket(mkURL());

      this._socket.onopen  = () => this.socket = this._socket;
      this._socket.onclose = () => this.socket = null;
      this._socket.onerror = () => this.socket = null;

      this._socket.onmessage = e => {
        if (this.callback) this.callback(JSON.parse(e.data));
      };
    };

    this._connect();
  }

  // Send a password to the zxcvbn algorithm.
  send(password) {
    if (!this.socket) this._connect();
    const record = {password};

    // Debouncing (don't overload the server).
    if (this.timeout) clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      if (!this.socket) return;
      this.socket.send(JSON.stringify(record));
    }, 150);
  }
}

// User Interface:
class PasswordWithStrength extends HTMLElement {
  constructor() { super(); }

  connectedCallback() {
    const shadowRoot = this.attachShadow({mode: 'open'});

    // YUCK!
    shadowRoot.innerHTML = `
      <style>
      * {box-sizing: border-box; margin: 0; padding: 0;}
      section {margin: 0em auto 0; width: 30em;}
      input {margin: 0 auto 0; width: 100%;}
      meter {margin: 0 auto 1em; width: 100%; height: 0.25em;}
      </style>
    `;

    const section = document.createElement("section");
    shadowRoot.appendChild(section);

    const input = document.createElement("input");
    input.setAttribute("type", "password");
    input.setAttribute("placeholder", "Password");
    section.appendChild(input);

    const meter = document.createElement("meter");
    meter.max = 4;
    meter.low = 1;
    meter.high = 3;
    meter.optimum = 4;
    section.appendChild(meter);

    const debug = document.createElement("code");
    section.appendChild(debug);

    const update = result => {
      if (result) {
        meter.value = result.strength;
        debug.textContent = JSON.stringify(result);
      } else {
        meter.value = null;
        debug.textContent = "";
      }
    };

    const zxcvbn = new Zxcvbn(update);
    input.addEventListener("keyup", _ => {
      if (input.value.toString().match(/^\s*$/)) {
        update(null);
      } else {
        zxcvbn.send(input.value);
      }
    });
  }
}

// Register the custom element:
customElements.define("password-with-strength", PasswordWithStrength);
