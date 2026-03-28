import "./style.css";
import { initializeApp } from "firebase/app";
import {
  getFirestore,
  collection,
  addDoc,
  deleteDoc,
  doc,
  updateDoc,
  serverTimestamp,
  query,
  orderBy,
  onSnapshot,
} from "firebase/firestore";

// THAY THÔNG TIN NÀY BẰNG FIREBASE CONFIG CỦA BẠN
const firebaseConfig = {
  apiKey: "DAN_API_KEY_CUA_BAN",
  authDomain: "task-manager-luan.firebaseapp.com",
  projectId: "task-manager-luan",
  storageBucket: "task-manager-luan.appspot.com",
  messagingSenderId: "DAN_MESSAGING_SENDER_ID",
  appId: "DAN_APP_ID",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

document.querySelector("#app").innerHTML = `
  <div class="container">
    <div class="hero">
      <div class="hero-icon">✅</div>
      <div>
        <h1>Quản lý công việc</h1>
        <p>Theo dõi đầu việc hằng ngày theo cách gọn gàng và dễ nhìn.</p>
      </div>
    </div>

    <div class="stats">
      <div class="stat-box">
        <div class="stat-number" id="totalCount">0</div>
        <div class="stat-label">Tổng việc</div>
      </div>
      <div class="stat-box">
        <div class="stat-number" id="doingCount">0</div>
        <div class="stat-label">Đang làm</div>
      </div>
      <div class="stat-box">
        <div class="stat-number" id="doneCount">0</div>
        <div class="stat-label">Hoàn thành</div>
      </div>
    </div>

    <div class="card add-card">
      <h2>Thêm công việc mới</h2>
      <div class="add-row">
        <input id="taskInput" type="text" placeholder="Ví dụ: Hoàn thiện báo cáo tuần..." />
        <button id="addBtn">+ Thêm việc</button>
      </div>
    </div>

    <div class="card list-card">
      <div class="list-header">
        <h2>Danh sách công việc</h2>
        <span id="taskBadge" class="badge">0 mục</span>
      </div>
      <div id="taskList" class="task-list"></div>
    </div>
  </div>
`;

const taskInput = document.getElementById("taskInput");
const addBtn = document.getElementById("addBtn");
const taskList = document.getElementById("taskList");
const totalCount = document.getElementById("totalCount");
const doingCount = document.getElementById("doingCount");
const doneCount = document.getElementById("doneCount");
const taskBadge = document.getElementById("taskBadge");

const tasksRef = collection(db, "tasks");

function formatTime(date) {
  const h = String(date.getHours()).padStart(2, "0");
  const m = String(date.getMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}

async function addTask() {
  const text = taskInput.value.trim();
  if (!text) return;

  addBtn.disabled = true;

  try {
    await addDoc(tasksRef, {
      text,
      done: false,
      createdAt: serverTimestamp(),
    });
    taskInput.value = "";
    taskInput.focus();
  } catch (error) {
    console.error("Lỗi thêm công việc:", error);
    alert("Không thêm được công việc. Kiểm tra Firestore và Rules.");
  } finally {
    addBtn.disabled = false;
  }
}

async function toggleTask(id, done) {
  try {
    await updateDoc(doc(db, "tasks", id), {
      done: !done,
    });
  } catch (error) {
    console.error("Lỗi cập nhật:", error);
    alert("Không cập nhật được công việc.");
  }
}

async function removeTask(id) {
  const ok = confirm("Bạn có chắc muốn xóa công việc này không?");
  if (!ok) return;

  try {
    await deleteDoc(doc(db, "tasks", id));
  } catch (error) {
    console.error("Lỗi xóa:", error);
    alert("Không xóa được công việc.");
  }
}

function renderTasks(tasks) {
  taskList.innerHTML = "";

  const total = tasks.length;
  const done = tasks.filter((t) => t.done).length;
  const doing = total - done;

  totalCount.textContent = total;
  doingCount.textContent = doing;
  doneCount.textContent = done;
  taskBadge.textContent = `${total} mục`;

  if (total === 0) {
    taskList.innerHTML = `<div class="empty">Chưa có công việc nào.</div>`;
    return;
  }

  tasks.forEach((task) => {
    const item = document.createElement("div");
    item.className = `task-item ${task.done ? "done" : ""}`;

    let createdText = "Vừa tạo";
    if (task.createdAt?.toDate) {
      const d = task.createdAt.toDate();
      createdText = `Tạo lúc ${formatTime(d)}`;
    }

    item.innerHTML = `
      <div class="task-left">
        <input class="task-check" type="checkbox" ${task.done ? "checked" : ""} />
        <div class="task-content">
          <div class="task-text">${escapeHtml(task.text)}</div>
          <div class="task-meta">
            <span class="status ${task.done ? "done-status" : "doing-status"}">
              ${task.done ? "Đã xong" : "Đang làm"}
            </span>
            <span class="time">${createdText}</span>
          </div>
        </div>
      </div>
      <button class="delete-btn" title="Xóa">🗑️</button>
    `;

    const check = item.querySelector(".task-check");
    const del = item.querySelector(".delete-btn");

    check.addEventListener("change", () => toggleTask(task.id, task.done));
    del.addEventListener("click", () => removeTask(task.id));

    taskList.appendChild(item);
  });
}

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

addBtn.addEventListener("click", addTask);

taskInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") addTask();
});

// Tự đồng bộ dữ liệu realtime cho tất cả người đang mở app
const q = query(tasksRef, orderBy("createdAt", "desc"));
onSnapshot(
  q,
  (snapshot) => {
    const tasks = snapshot.docs.map((docSnap) => ({
      id: docSnap.id,
      ...docSnap.data(),
    }));
    renderTasks(tasks);
  },
  (error) => {
    console.error("Lỗi đọc dữ liệu:", error);
    taskList.innerHTML = `
      <div class="empty" style="color:red;">
        Không đọc được dữ liệu. Kiểm tra Firestore Rules hoặc cấu hình Firebase.
      </div>
    `;
  }
);