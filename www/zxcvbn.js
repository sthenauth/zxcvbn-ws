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
      * { box-sizing: border-box; margin: 0; padding: 0; }

      section {
        margin: 0em auto 0;
        width: 30em;
      }

      input {
        margin: 0 auto 0;
        width: 100%;
      }

      meter {
        margin: 0 auto 1em;
        width: 100%;
        height: 0.25em;
        background: none;
        background-color: rgba(0, 0, 0, 0.1);
        border: none;
      }

      meter::-webkit-meter-bar {
        background: none;
        background-color: rgba(0, 0, 0, 0.1);
      }

      meter[value="1"]::-webkit-meter-optimum-value { background: red; }
      meter[value="2"]::-webkit-meter-optimum-value { background: orange; }
      meter[value="3"]::-webkit-meter-optimum-value { background: yellow; }
      meter[value="4"]::-webkit-meter-optimum-value { background: green; }

      meter[value="1"]::-moz-meter-bar { background: red; }
      meter[value="2"]::-moz-meter-bar { background: orange; }
      meter[value="3"]::-moz-meter-bar { background: yellow; }
      meter[value="4"]::-moz-meter-bar { background: green; }
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
    section.appendChild(meter);

    const update = result => {
      console.log("Result:", result);

      if (result) {
        meter.max = result.possible;
        meter.value = result.strength;
        meter.textContent = result.description;
      } else {
        meter.value = null;
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
