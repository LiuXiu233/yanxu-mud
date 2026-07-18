"use strict";

const state = {
  socket: null,
  websocketUrl: "",
  resumeToken: sessionStorage.getItem("yanyu.resumeToken") || "",
  requestSequence: 0,
  pending: new Map(),
  reconnectTimer: null,
  reconnectAttempt: 0,
  manualClose: false,
  commandHistory: [],
  historyIndex: 0,
  characterId: "",
};

const elements = {
  workspace: document.querySelector(".workspace"),
  viewButtons: [...document.querySelectorAll(".view-button")],
  connectionStatus: document.querySelector("#connection-status"),
  reconnectButton: document.querySelector("#reconnect-button"),
  logoutButton: document.querySelector("#logout-button"),
  clearButton: document.querySelector("#clear-button"),
  transcript: document.querySelector("#transcript"),
  commandForm: document.querySelector("#command-form"),
  commandInput: document.querySelector("#command-input"),
  sendButton: document.querySelector("#send-button"),
  loginDialog: document.querySelector("#login-dialog"),
  loginForm: document.querySelector("#login-form"),
  loginButton: document.querySelector("#login-button"),
  guestButton: document.querySelector("#guest-button"),
  loginError: document.querySelector("#login-error"),
  characterName: document.querySelector("#character-name"),
  locationName: document.querySelector("#location-name"),
  mapLocation: document.querySelector("#map-location"),
  healthMeter: document.querySelector("#health-meter"),
  healthValue: document.querySelector("#health-value"),
  stateValue: document.querySelector("#state-value"),
  serverVersion: document.querySelector("#server-version"),
  onlineCount: document.querySelector("#online-count"),
  contentState: document.querySelector("#content-state"),
  sessionLabel: document.querySelector("#session-label"),
};

function nextRequestId(prefix = "web") {
  state.requestSequence += 1;
  return `${prefix}-${Date.now()}-${state.requestSequence}`;
}

function setConnectionStatus(label, status) {
  elements.connectionStatus.textContent = label;
  elements.connectionStatus.dataset.state = status;
  const enabled = status === "online";
  elements.commandInput.disabled = !enabled;
  elements.sendButton.disabled = !enabled;
}

function showLogin(message = "") {
  elements.loginError.textContent = message;
  if (!elements.loginDialog.open) {
    elements.loginDialog.showModal();
  }
}

function hideLogin() {
  if (elements.loginDialog.open) {
    elements.loginDialog.close();
  }
}

function appendEntry(kind, label, content) {
  const entry = document.createElement("article");
  entry.className = `message-entry ${kind}-entry`;

  const meta = document.createElement("div");
  meta.className = "message-meta";
  meta.textContent = label;

  const body = document.createElement("div");
  body.className = "message-body";
  if (content instanceof Node) {
    body.append(content);
  } else {
    body.textContent = String(content);
  }

  entry.append(meta, body);
  elements.transcript.append(entry);
  elements.transcript.scrollTop = elements.transcript.scrollHeight;
}

function textFromNodes(nodes) {
  if (!Array.isArray(nodes)) return "";
  return nodes.map((node) => {
    if (!node || typeof node !== "object") return "";
    switch (node["种类"]) {
      case "文字": return String(node["内容"] || "");
      case "富文本": return Array.isArray(node["片段"]) ? node["片段"].map((part) => String(part["文字"] || "")).join("") : "";
      case "人物引用":
      case "物品引用":
      case "房间引用": return String(node["显示"] || node["编号"] || "");
      case "命令链接": return String(node["标题"] || node["命令"] || "");
      case "状态栏": return `${node["标签"] || ""} ${node["值"] || ""} ${node["补充"] || ""}`.trim();
      case "进度条": return `${node["标签"] || ""} ${node["当前"] ?? 0}/${node["最大"] ?? 0}`;
      case "场景描述": return `${node["标题"] || ""}\n${textFromNodes(node["正文"])}\n${textFromNodes(node["出口"])}`.trim();
      case "系统提示": return textFromNodes(node["内容"]);
      case "错误": return `[${node["代码"] || "ERROR"}] ${node["消息"] || ""}`;
      case "频道": return `[${node["频道"] || "频道"}] ${node["发送者"] || ""}: ${textFromNodes(node["内容"])}`;
      case "战斗": return textFromNodes(node["内容"]);
      case "自定义": return textFromNodes(node["回退"]);
      default: return "";
    }
  }).filter(Boolean).join(" ");
}

function renderNodes(nodes, container) {
  if (!Array.isArray(nodes)) return;
  nodes.forEach((node) => {
    if (!node || typeof node !== "object") return;
    const type = node["种类"];

    if (type === "文字") {
      container.append(document.createTextNode(String(node["内容"] || "")));
      return;
    }

    if (type === "富文本") {
      (node["片段"] || []).forEach((part) => {
        const span = document.createElement("span");
        span.textContent = String(part["文字"] || "");
        const style = part["样式"] || {};
        if (style["加粗"]) span.style.fontWeight = "700";
        if (style["下划线"]) span.style.textDecoration = "underline";
        if (style["斜体"]) span.style.fontStyle = "italic";
        container.append(span);
      });
      return;
    }

    if (["人物引用", "物品引用", "房间引用"].includes(type)) {
      const span = document.createElement("strong");
      span.textContent = String(node["显示"] || node["编号"] || "");
      container.append(span);
      return;
    }

    if (type === "命令链接") {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "command-link";
      button.textContent = String(node["标题"] || node["命令"] || "命令");
      button.addEventListener("click", () => sendCommand(String(node["命令"] || "")));
      container.append(button);
      return;
    }

    if (type === "列表") {
      const list = document.createElement(node["有序"] ? "ol" : "ul");
      list.className = "message-list";
      (node["项目"] || []).forEach((item) => {
        const listItem = document.createElement("li");
        renderNodes(Array.isArray(item) ? item : [item], listItem);
        list.append(listItem);
      });
      container.append(list);
      return;
    }

    if (type === "表格") {
      const table = document.createElement("table");
      table.className = "message-table";
      const head = document.createElement("thead");
      const headRow = document.createElement("tr");
      (node["表头"] || []).forEach((value) => {
        const cell = document.createElement("th");
        cell.textContent = String(value);
        headRow.append(cell);
      });
      head.append(headRow);
      table.append(head);
      const body = document.createElement("tbody");
      (node["各行"] || []).forEach((row) => {
        const rowElement = document.createElement("tr");
        (row || []).forEach((value) => {
          const cell = document.createElement("td");
          cell.textContent = String(value);
          rowElement.append(cell);
        });
        body.append(rowElement);
      });
      table.append(body);
      container.append(table);
      return;
    }

    if (type === "状态栏") {
      const line = document.createElement("div");
      line.textContent = `${node["标签"] || ""} ${node["值"] || ""} ${node["补充"] || ""}`.trim();
      container.append(line);
      updateStatusNode(node);
      return;
    }

    if (type === "进度条") {
      const wrapper = document.createElement("div");
      wrapper.className = "inline-meter";
      const label = document.createElement("span");
      label.textContent = String(node["标签"] || "");
      const progress = document.createElement("progress");
      progress.max = Number(node["最大"] || 1);
      progress.value = Number(node["当前"] || 0);
      const value = document.createElement("span");
      value.textContent = `${progress.value}/${progress.max}`;
      wrapper.append(label, progress, value);
      container.append(wrapper);
      updateProgressNode(node);
      return;
    }

    if (type === "场景描述") {
      const section = document.createElement("section");
      const title = document.createElement("strong");
      title.textContent = String(node["标题"] || "");
      const content = document.createElement("div");
      renderNodes(node["正文"] || [], content);
      const exits = document.createElement("div");
      exits.className = "muted-line";
      renderNodes(node["出口"] || [], exits);
      section.append(title, content, exits);
      container.append(section);
      updateLocation(String(node["标题"] || ""));
      return;
    }

    if (["系统提示", "频道", "战斗"].includes(type)) {
      renderNodes(node["内容"] || [], container);
      return;
    }

    if (type === "错误") {
      container.append(document.createTextNode(`[${node["代码"] || "ERROR"}] ${node["消息"] || ""}`));
      return;
    }

    if (type === "自定义") {
      renderNodes(node["回退"] || [], container);
    }
  });
}

function updateProgressNode(node) {
  const label = String(node["标签"] || "");
  if (label.includes("生命")) {
    const current = Number(node["当前"] || 0);
    const maximum = Math.max(1, Number(node["最大"] || 1));
    elements.healthMeter.max = maximum;
    elements.healthMeter.value = current;
    elements.healthValue.textContent = `${current}/${maximum}`;
  }
}

function updateStatusNode(node) {
  const label = String(node["标签"] || "");
  if (label.includes("状态")) {
    elements.stateValue.textContent = String(node["值"] || "--");
  }
}

function updateLocation(location) {
  if (!location) return;
  elements.locationName.textContent = location;
  elements.mapLocation.textContent = location;
}

function renderEnvelope(envelope) {
  if (!envelope || typeof envelope !== "object") return;
  const requestType = String(envelope["请求种类"] || "响应");
  const messages = Array.isArray(envelope["消息"]) ? envelope["消息"] : [];

  if (messages.length) {
    messages.forEach((message) => {
      const body = document.createElement("div");
      const nodes = message && Array.isArray(message["节点"]) ? message["节点"] : [];
      renderNodes(nodes, body);
      const nodeTypes = nodes.map((node) => node && node["种类"]);
      let kind = "world";
      let label = "世界";
      if (nodeTypes.includes("错误")) { kind = "error"; label = "错误"; }
      else if (nodeTypes.includes("战斗")) { kind = "combat"; label = "战斗"; }
      else if (nodeTypes.includes("频道")) { kind = "channel"; label = "频道"; }
      else if (nodeTypes.includes("系统提示")) { kind = "system"; label = "系统"; }
      appendEntry(kind, label, body);
    });
  } else if (!envelope["成功"]) {
    const error = envelope["错误"] || {};
    appendEntry("error", "错误", `[${error["代码"] || "ERROR"}] ${error["消息"] || "请求失败"}`);
  } else if (!["协商", "状态"].includes(requestType)) {
    appendEntry("system", "系统", `${requestType}完成`);
  }

  const data = envelope["数据"] || {};
  const session = data["会话"] || {};
  if (session["角色编号"]) {
    state.characterId = String(session["角色编号"]);
    elements.characterName.textContent = state.characterId.split("/").pop() || state.characterId;
    elements.sessionLabel.textContent = String(session["会话编号"] || "在线会话");
  }
}

function handleSocketMessage(event) {
  let envelope;
  try {
    envelope = JSON.parse(event.data);
  } catch {
    appendEntry("error", "协议", "服务器返回了无效 JSON。");
    return;
  }

  renderEnvelope(envelope);
  const requestId = String(envelope["请求编号"] || "");
  const pending = state.pending.get(requestId);
  if (pending) {
    state.pending.delete(requestId);
    if (envelope["成功"]) pending.resolve(envelope);
    else pending.reject(envelope);
  }
}

function sendRequest(kind, data = {}) {
  return new Promise((resolve, reject) => {
    if (!state.socket || state.socket.readyState !== WebSocket.OPEN) {
      reject({ "错误": { "消息": "WebSocket 未连接" } });
      return;
    }
    const requestId = nextRequestId(kind);
    const request = { "种类": kind, "请求编号": requestId, ...data };
    state.pending.set(requestId, { resolve, reject });
    state.socket.send(JSON.stringify(request));
    window.setTimeout(() => {
      const pending = state.pending.get(requestId);
      if (pending) {
        state.pending.delete(requestId);
        pending.reject({ "错误": { "消息": "请求超时" } });
      }
    }, 12000);
  });
}

async function discoverWebSocketUrl() {
  if (state.websocketUrl) return state.websocketUrl;
  const response = await fetch("/api/v1/ws", { cache: "no-store" });
  const discovered = response.headers.get("x-yanyu-websocket-url");
  if (!discovered) throw new Error("缺少 WebSocket 地址");
  state.websocketUrl = discovered;
  return discovered;
}

async function connect() {
  if (state.socket && [WebSocket.OPEN, WebSocket.CONNECTING].includes(state.socket.readyState)) return;
  state.manualClose = false;
  setConnectionStatus("连接中", "connecting");

  try {
    const url = await discoverWebSocketUrl();
    const socket = new WebSocket(url, ["yanyu.v1"]);
    state.socket = socket;

    socket.addEventListener("message", handleSocketMessage);
    socket.addEventListener("open", async () => {
      state.reconnectAttempt = 0;
      setConnectionStatus("已连接", "online");
      try {
        await sendRequest("协商", { "能力": ["结构化消息-v1", "请求编号", "会话恢复"] });
        if (!state.resumeToken) {
          setConnectionStatus("待登录", "connecting");
          showLogin();
          return;
        }
        const resumed = await sendRequest("恢复", {
          "恢复令牌": state.resumeToken,
          "能力": ["结构化消息-v1", "请求编号", "会话恢复"],
        });
        const nextToken = resumed["数据"] && resumed["数据"]["恢复令牌"];
        if (nextToken) {
          state.resumeToken = String(nextToken);
          sessionStorage.setItem("yanyu.resumeToken", state.resumeToken);
        }
        hideLogin();
        elements.commandInput.focus();
        await sendCommand("观察", false);
      } catch (error) {
        state.resumeToken = "";
        sessionStorage.removeItem("yanyu.resumeToken");
        setConnectionStatus("待登录", "connecting");
        showLogin(error && error["错误"] ? error["错误"]["消息"] : "会话恢复失败");
      }
    });

    socket.addEventListener("close", () => {
      setConnectionStatus("已断开", "offline");
      state.pending.forEach(({ reject }) => reject({ "错误": { "消息": "连接已关闭" } }));
      state.pending.clear();
      if (!state.manualClose && state.resumeToken) scheduleReconnect();
    });

    socket.addEventListener("error", () => {
      setConnectionStatus("连接错误", "error");
    });
  } catch (error) {
    setConnectionStatus("连接错误", "error");
    appendEntry("error", "网络", error instanceof Error ? error.message : "无法发现 WebSocket 入口");
    scheduleReconnect();
  }
}

function scheduleReconnect() {
  if (state.reconnectTimer || state.manualClose) return;
  const delay = Math.min(10000, 800 * (2 ** state.reconnectAttempt));
  state.reconnectAttempt += 1;
  state.reconnectTimer = window.setTimeout(() => {
    state.reconnectTimer = null;
    connect();
  }, delay);
}

async function sendCommand(command, recordHistory = true) {
  const normalized = String(command || "").trim();
  if (!normalized) return;
  if (recordHistory) {
    state.commandHistory.push(normalized);
    state.commandHistory = state.commandHistory.slice(-100);
    state.historyIndex = state.commandHistory.length;
  }
  appendEntry("command", "你", normalized);
  elements.commandInput.value = "";
  try {
    await sendRequest("命令", { "命令": normalized });
  } catch {
    // The failed response is rendered by handleSocketMessage.
  }
}

async function establishSession(kind, data) {
  const envelope = await sendRequest(kind, data);
  const token = envelope["数据"] && envelope["数据"]["恢复令牌"];
  if (!token) throw { "错误": { "消息": "会话响应缺少恢复令牌" } };
  state.resumeToken = String(token);
  sessionStorage.setItem("yanyu.resumeToken", state.resumeToken);
  hideLogin();
  elements.commandInput.focus();
  await sendCommand("观察", false);
}

async function refreshServerFacts() {
  const endpoints = [
    ["/api/v1/server", elements.serverVersion, (data) => data["版本"] || "--"],
    ["/api/v1/online", elements.onlineCount, (data) => data["在线"] ?? data["会话"] ?? "--"],
    ["/api/v1/content", elements.contentState, (data) => data["状态"] || (data["摘要"] ? "已装载" : "--")],
  ];
  await Promise.all(endpoints.map(async ([url, element, select]) => {
    try {
      const response = await fetch(url, { cache: "no-store" });
      const body = await response.json();
      if (response.ok && body["成功"]) element.textContent = String(select(body["数据"] || {}));
    } catch {
      element.textContent = "--";
    }
  }));
}

elements.loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  elements.loginButton.disabled = true;
  elements.guestButton.disabled = true;
  elements.loginError.textContent = "";
  try {
    const formData = new FormData(elements.loginForm);
    await establishSession("登录", {
      "登录名": String(formData.get("loginName") || ""),
      "密码": String(formData.get("password") || ""),
      "角色编号": String(formData.get("roleId") || ""),
      "能力": ["结构化消息-v1", "请求编号", "会话恢复"],
    });
  } catch (error) {
    elements.loginError.textContent = error && error["错误"] ? String(error["错误"]["消息"] || "登录失败") : "登录失败";
  } finally {
    elements.loginButton.disabled = false;
    elements.guestButton.disabled = false;
  }
});

elements.guestButton.addEventListener("click", async () => {
  elements.loginButton.disabled = true;
  elements.guestButton.disabled = true;
  elements.loginError.textContent = "";
  try {
    await establishSession("游客", {
      "能力": ["结构化消息-v1", "请求编号", "会话恢复"],
    });
  } catch (error) {
    elements.loginError.textContent = error && error["错误"] ? String(error["错误"]["消息"] || "游客会话建立失败") : "游客会话建立失败";
  } finally {
    elements.loginButton.disabled = false;
    elements.guestButton.disabled = false;
  }
});

elements.commandForm.addEventListener("submit", (event) => {
  event.preventDefault();
  sendCommand(elements.commandInput.value);
});

elements.commandInput.addEventListener("keydown", (event) => {
  if (event.key === "ArrowUp") {
    event.preventDefault();
    state.historyIndex = Math.max(0, state.historyIndex - 1);
    elements.commandInput.value = state.commandHistory[state.historyIndex] || "";
  } else if (event.key === "ArrowDown") {
    event.preventDefault();
    state.historyIndex = Math.min(state.commandHistory.length, state.historyIndex + 1);
    elements.commandInput.value = state.commandHistory[state.historyIndex] || "";
  }
});

document.querySelectorAll("[data-command]").forEach((button) => {
  button.addEventListener("click", () => sendCommand(button.dataset.command));
});

elements.viewButtons.forEach((button) => {
  button.addEventListener("click", () => {
    elements.viewButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    elements.workspace.dataset.activeView = button.dataset.view;
  });
});

elements.reconnectButton.addEventListener("click", () => {
  if (state.reconnectTimer) {
    window.clearTimeout(state.reconnectTimer);
    state.reconnectTimer = null;
  }
  if (state.socket) {
    state.manualClose = true;
    state.socket.close(1000, "手动重连");
  }
  state.socket = null;
  state.manualClose = false;
  connect();
});

elements.logoutButton.addEventListener("click", async () => {
  state.manualClose = true;
  try {
    if (state.socket && state.socket.readyState === WebSocket.OPEN) await sendRequest("退出");
  } catch {
    // Local cleanup still runs.
  }
  state.resumeToken = "";
  state.characterId = "";
  sessionStorage.removeItem("yanyu.resumeToken");
  if (state.socket) state.socket.close(1000, "退出");
  state.socket = null;
  elements.characterName.textContent = "未选择";
  elements.locationName.textContent = "等待世界状态";
  setConnectionStatus("未连接", "offline");
  showLogin();
});

elements.clearButton.addEventListener("click", () => {
  elements.transcript.replaceChildren();
});

window.addEventListener("beforeunload", () => {
  state.manualClose = true;
  if (state.socket) state.socket.close(1000, "页面关闭");
});

refreshServerFacts();
window.setInterval(refreshServerFacts, 30000);
connect();
